{...}: {
  # OpenLogi — local-first Logitech Options+ replacement (HID++ buttons, DPI,
  # SmartShift). Upstream flake ships the package, udev rules, and a user agent.
  #
  # The udev rules tag Logitech hidraw/event nodes and uinput with `uaccess`,
  # so the seated user can talk to the mouse without an `input` group. uinput
  # itself is a kernel module, so load it at boot. Don't have Logitech gear?
  # Comment this import out of ./default.nix.
  boot.kernelModules = ["uinput"];

  programs.openlogi = {
    enable = true;
    launchAtLogin = true;
  };
}
