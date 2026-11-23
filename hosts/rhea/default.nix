{modulesPath, ...}: {
  # rhea — headless VPS for self-hosted services. Install from the NixOS ISO
  # with nixos-anywhere, then deploy with `nixos-rebuild --target-host` (README).
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix") # virtio disk/net drivers in initrd
    ./disko.nix
  ];

  networking.hostName = "rhea";
  time.timeZone = "UTC";

  # The provider has no DHCP; static values from the VPS panel.
  networking = {
    useDHCP = false;
    interfaces.ens3.ipv4.addresses = [
      {
        address = "23.252.124.173";
        prefixLength = 24;
      }
    ];
    defaultGateway = {
      address = "23.252.124.1";
      interface = "ens3";
    };
    nameservers = [
      "1.1.1.1"
      "9.9.9.9"
    ];
  };

  # Root over SSH with keys only; deploys run as root@rhea.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };
  # Same key as `user` in secrets/secrets.nix.
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC6rcJI/Qs1aVnk6ShIcfm5lhj2t8kS9r84skhaMRhBHzxTJlzs2gFhAtH1dKtERBGOHiM5ca9N6LFNRWQ44XHnei1CzSkIy7L+ZEFAbx+BfMUIo7AKU5b7fE+yuJy/kXJo+giP9ROxNdHwLNpCgW28Mn2y395YIHj92u9bcJeofyUx55KL/fuvDkPP3Q7Hx2EFYnrz4m43D+g3l5/sitTLzOmzl7GhL2rZ/WgAmOoVEqY99UldvwkMDhiqo6oNhEQ1acsnfD09ZROUxoii8a7k9PDUnDe1+CkkAmyr6ea9hLXUZHbCieRX8QfeRztIC+AjNDxVW3dvh5OOb6Fa7Mzs3Ll621bq1SZUTf2GI1lkkWeWu8GfmU1hlFqwK8iEFF9JmoL+urWTiz2jG4V5duSJRml0WywhJBiE5NzHCUEqAXNa2Qa2hYSGwE2T5FXXbUooPq5PucloaiKATEXAgvNw2h9yxfnPxWjRtKi4nT97V/IRK5m9LWcxgXfR4UWiK6M= user@DESKTOP-8PN5EV6"
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # The release this host was installed with. Do NOT bump casually.
  system.stateVersion = "26.11";
}
