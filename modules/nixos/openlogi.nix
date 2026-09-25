{
  inputs,
  pkgs,
  lib,
  ...
}: let
  # Upstream pins rust-overlay's "stable.latest", which is still rustc 1.98.0.
  # That release miscompiles trait-object vtables (fixed in 1.98.1) and this
  # build also dies in two other 1.98.0 bugs: an ICE while type-checking
  # `AsyncHidChannel::read_report` (the patch rewrites that await), and a
  # SIGSEGV in LLVM InstCombine.
  #
  # Nixpkgs' rustc 1.98.1 has the vtable fix, but it links nixpkgs LLVM 21.1.8,
  # which SIGSEGVs in MCAssembler::relaxInstruction
  # (MCExpr::evaluateAsRelocatableImpl) while emitting proc-macro-crate. The
  # official 1.98.1 binary ships the LLVM that compiler was built against.
  #
  # LLVM 22 in the official 1.98.1 binary also SIGSEGVs in GlobalOpt at
  # opt-level 3 and in the inliner at opt-level 1 while compiling dependencies.
  # Disable LLVM optimization for this package. Cargo's profile settings take
  # precedence over RUSTFLAGS, so set them through profile environment vars.
  rustToolchain =
    (inputs.rust-overlay.lib.mkRustBin {} pkgs).stable."1.98.1".minimal;
  rustPlatform = pkgs.makeRustPlatform {
    cargo = rustToolchain;
    rustc = rustToolchain;
  };

  openlogiUnwrapped =
    (inputs.openlogi.packages.${pkgs.stdenv.hostPlatform.system}.openlogi.override {
      inherit rustPlatform;
    }).overrideAttrs
    (old: {
      env =
        (old.env or {})
        // {
          CARGO_PROFILE_RELEASE_LTO = "off";
          CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "16";
          CARGO_PROFILE_RELEASE_OPT_LEVEL = "0";
        };
      patches = (old.patches or []) ++ [./openlogi-read-report.patch];
    });

  # GPUI dlopens Wayland / Vulkan / libGL at runtime. Upstream only patchelf's
  # openlogi-desktop, so the Actions Ring overlay (and a PATH-spawned GUI)
  # panic with NoWaylandLib. Wrap instead of overrideAttrs postFixup so we
  # don't rebuild the Rust crate. Wrapping the agent as well means the overlay
  # helper inherits LD_LIBRARY_PATH even when the agent resolves the sibling
  # binary in the unwrapped store path.
  runtimeLibs = lib.makeLibraryPath [
    pkgs.libGL
    pkgs.wayland
    pkgs.vulkan-loader
  ];

  openlogi = pkgs.symlinkJoin {
    name = "openlogi-${openlogiUnwrapped.version}";
    paths = [openlogiUnwrapped];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      for bin in openlogi-agent openlogi-desktop openlogi-overlay; do
        rm -f "$out/bin/$bin"
        makeWrapper "${openlogiUnwrapped}/bin/$bin" "$out/bin/$bin" \
          --prefix LD_LIBRARY_PATH : "${runtimeLibs}"
      done
    '';
    inherit (openlogiUnwrapped) meta;
  };
in {
  # OpenLogi — local-first Logitech Options+ replacement (HID++ buttons, DPI,
  # SmartShift). No account, no telemetry. Upstream flake ships the package,
  # udev rules, and a user agent; we only flip the switch.
  #
  # The udev rules tag Logitech hidraw/event nodes and uinput with `uaccess`,
  # so the seated user can talk to the mouse without an `input` group. uinput
  # itself is a kernel module, so load it at boot or the agent's hook has
  # nothing to open. Don't have Logitech gear? Comment this import out of
  # ./default.nix.
  boot.kernelModules = ["uinput"];

  programs.openlogi = {
    enable = true;
    # Agent starts with the graphical (niri) session. Leave the GUI's
    # Settings → Launch at login off: that writes a user unit which shadows
    # this one and points at the unwrapped store binary.
    launchAtLogin = true;
    package = openlogi;
  };
}
