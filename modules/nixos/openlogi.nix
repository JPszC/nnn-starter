{
  inputs,
  pkgs,
  ...
}: {
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
    # Agent starts with the graphical (niri) session.
    launchAtLogin = true;
    # rustc 1.98 / LLVM 22 can SIGSEGV during release LTO on deps like moxcms.
    package = inputs.openlogi.packages.${pkgs.system}.openlogi.overrideAttrs (old: {
      RUSTFLAGS =
        (old.RUSTFLAGS or "")
        + " -C lto=off -Clinker-plugin-lto=off -Ccodegen-units=16";
    });
  };
}
