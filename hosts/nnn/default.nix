{
  local,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = local.hostName;

  # ⇩ Timezone comes from local.nix; locale/keyboard layout below.
  time.timeZone = local.timeZone;
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "grp:alt_shift_toggle"; # Alt+Shift switches layout
  };
  console.keyMap = "us";

  # The 32" 4K is plugged into the RTX HDMI port. nouveau composites that
  # framebuffer too slowly, so workspace and window animations drop frames.
  # The open kernel module matches this Ada GPU; persistence keeps the
  # memory clock from parking between animations (that ramp-up is a visible hitch).
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    powerManagement.enable = false;
    nvidiaPersistenced = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # The release this config was written against. Do NOT bump casually after
  # first install — read the NixOS release notes first.
  system.stateVersion = "26.05";
}
