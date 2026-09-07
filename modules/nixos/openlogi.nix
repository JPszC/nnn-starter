{
  inputs,
  pkgs,
  lib,
  ...
}: let
  # rustc 1.98 / LLVM 22 can SIGSEGV during release LTO on deps like moxcms.
  openlogiUnwrapped = inputs.openlogi.packages.${pkgs.stdenv.hostPlatform.system}.openlogi.overrideAttrs (old: {
    RUSTFLAGS =
      (old.RUSTFLAGS or "")
      + " -C lto=off -Clinker-plugin-lto=off -Ccodegen-units=16";
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
