{
  lib,
  config,
  local,
  ...
}: let
  # NetBird client. The setup key lives in secrets/netbird-setup-key.age
  # (agenix, file contains just the key); only the enable switch (and an
  # optional self-hosted management URL) is in local.nix.
  cfg = local.netbird or {};
  enabled = cfg.enable or false;
in
  lib.mkIf enabled {
    # Decrypted to /run/agenix/netbird-setup-key at activation (mode 0400, root).
    age.secrets.netbird-setup-key = {
      file = ../../secrets/netbird-setup-key.age;
    };

    # Docs: https://docs.netbird.io/how-to/register-machines-using-setup-keys
    # Installs the `netbird` CLI wrapper on PATH: `netbird status`, `netbird up`.
    # The client is named "netbird" so the wrapper binary is plain `netbird`
    # (any other name `foo` would give `netbird-foo`).
    # Hardened mode restricts the daemon socket to the client's group, so the
    # login user must be a member to run `netbird status` etc. without sudo.
    users.users.${local.username}.extraGroups = [
      config.services.netbird.clients.netbird.user.group
    ];

    services.netbird.clients.netbird = {
      port = 51820;
      autoStart = true;
      openFirewall = true;
      login = {
        enable = true;
        # agenix decrypts during activation (no systemd unit), so the file is
        # already in place before any service starts; no systemdDependencies.
        setupKeyFile = config.age.secrets.netbird-setup-key.path;
      };
      # Only needed for self-hosted NetBird; omit to use NetBird Cloud.
      environment = lib.mkIf (cfg ? managementUrl) {
        NB_MANAGEMENT_URL = cfg.managementUrl;
      };
    };
  }
