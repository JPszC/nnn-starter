{
  config,
  modulesPath,
  ...
}: let
  # Same key as `user` in secrets/secrets.nix.
  sshKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC6rcJI/Qs1aVnk6ShIcfm5lhj2t8kS9r84skhaMRhBHzxTJlzs2gFhAtH1dKtERBGOHiM5ca9N6LFNRWQ44XHnei1CzSkIy7L+ZEFAbx+BfMUIo7AKU5b7fE+yuJy/kXJo+giP9ROxNdHwLNpCgW28Mn2y395YIHj92u9bcJeofyUx55KL/fuvDkPP3Q7Hx2EFYnrz4m43D+g3l5/sitTLzOmzl7GhL2rZ/WgAmOoVEqY99UldvwkMDhiqo6oNhEQ1acsnfD09ZROUxoii8a7k9PDUnDe1+CkkAmyr6ea9hLXUZHbCieRX8QfeRztIC+AjNDxVW3dvh5OOb6Fa7Mzs3Ll621bq1SZUTf2GI1lkkWeWu8GfmU1hlFqwK8iEFF9JmoL+urWTiz2jG4V5duSJRml0WywhJBiE5NzHCUEqAXNa2Qa2hYSGwE2T5FXXbUooPq5PucloaiKATEXAgvNw2h9yxfnPxWjRtKi4nT97V/IRK5m9LWcxgXfR4UWiK6M= user@DESKTOP-8PN5EV6";
in {
  # rhea — headless VPS for self-hosted services. Install from the NixOS ISO
  # with nixos-anywhere, then deploy with `nh os switch --target-host` (README).
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

    # Public side: SSH (opened by openssh) and NetBird's WireGuard UDP port
    # (opened by openFirewall below), nothing else, not even ping. Peers
    # reaching rhea over NetBird are trusted; NetBird's own ACLs gate them.
    firewall = {
      enable = true;
      allowPing = false;
      trustedInterfaces = [config.services.netbird.clients.netbird.interface];
    };
  };

  # Same setup key as the desktop; decrypted with rhea's SSH host key
  # (secrets/secrets.nix lists it as a recipient).
  age.secrets.netbird-setup-key.file = ../../secrets/netbird-setup-key.age;

  # Mirrors modules/nixos/netbird.nix, which reads local.nix and so isn't shared.
  services.netbird.clients.netbird = {
    port = 51820;
    autoStart = true;
    openFirewall = true;
    login = {
      enable = true;
      setupKeyFile = config.age.secrets.netbird-setup-key.path;
    };
  };

  # Pangolin site (pango.jpszc.com). newt dials out, so no firewall port opens.
  # NEWT_ID / NEWT_SECRET come from the agenix env file, not the Nix store.
  age.secrets.newt-env.file = ../../secrets/newt.env.age;
  services.newt = {
    enable = true;
    settings = {
      endpoint = "https://pango.jpszc.com";
      disable-ssh = true;
    };
    environmentFile = config.age.secrets.newt-env.path;
  };

  # Linkwarden bookmarks with local Postgres (Unix socket, no password).
  # Public via Pangolin: resource link.jpszc.com → localhost:3000 on site rhea.
  # Linkwarden binds "localhost" as [::1], which is also what newt dials.
  # NEXTAUTH_SECRET comes from the agenix env file.
  age.secrets.linkwarden-env.file = ../../secrets/linkwarden.env.age;
  services.linkwarden = {
    enable = true;
    environmentFile = config.age.secrets.linkwarden-env.path;
    environment.NEXTAUTH_URL = "https://link.jpszc.com/api/v1/auth";
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
  users.users.root.openssh.authorizedKeys.keys = [sshKey];

  # Day-to-day login. No password exists, so sudo can't prompt for one;
  # SSH-key access already equals root here, as on the desktop (users.nix).
  users.users.jpereira = {
    isNormalUser = true;
    # netbird group: run `netbird status` without sudo (hardened daemon socket).
    extraGroups = [
      "wheel"
      config.services.netbird.clients.netbird.user.group
    ];
    openssh.authorizedKeys.keys = [sshKey];
  };
  security.sudo.wheelNeedsPassword = false;

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

  # `nh os switch` on rhea builds the pushed config from GitHub (selects
  # nixosConfigurations.rhea by hostname). Cleanup stays with nix.gc above.
  programs.nh = {
    enable = true;
    flake = "github:jpszc/nnn-starter";
  };

  # The release this host was installed with. Do NOT bump casually.
  system.stateVersion = "26.11";
}
