{
  config,
  lib,
  ...
}: let
  cfg = config.programs.openlogi;
in {
  # OpenLogi — local-first Logitech Options+ replacement (HID++ buttons, DPI,
  # SmartShift). nixpkgs ships the package and the NixOS module (binary +
  # udev). That module does not start the background agent, so we do.
  #
  # The udev rules tag Logitech hidraw/event nodes and uinput with `uaccess`,
  # so the seated user can talk to the mouse without an `input` group. uinput
  # itself is a kernel module, so load it at boot. Don't have Logitech gear?
  # Comment this import out of ./default.nix.
  boot.kernelModules = ["uinput"];

  programs.openlogi.enable = true;

  systemd.user.services.openlogi-agent = lib.mkIf cfg.enable {
    description = "OpenLogi background agent";
    wantedBy = ["graphical-session.target"];
    after = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    serviceConfig = {
      ExecStart = lib.getExe' cfg.package "openlogi-agent";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
