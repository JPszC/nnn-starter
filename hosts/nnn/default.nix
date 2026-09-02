{local, ...}: {
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

  # The release this config was written against. Do NOT bump casually after
  # first install — read the NixOS release notes first.
  system.stateVersion = "26.05";
}
