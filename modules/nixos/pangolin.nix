{
  pkgs,
  lib,
  config,
  local,
  ...
}: let
  # Machine client for Pangolin. Credentials live in secrets/pangolin.env.age
  # (agenix); only the enable switch is in local.nix.
  cfg = local.pangolin or {};
  enabled = cfg.enable or false;
in
  lib.mkIf enabled {
    # Decrypted to /run/agenix/pangolin-env at activation (mode 0400, root).
    age.secrets.pangolin-env = {
      file = ../../secrets/pangolin.env.age;
    };

    # Docs: https://docs.pangolin.net/manage/clients/install-client
    # Env file must define:
    #   PANGOLIN_ENDPOINT=https://…
    #   CLIENT_ID=…
    #   CLIENT_SECRET=…
    systemd.services.pangolin = {
      description = "Pangolin CLI VPN client";
      after = [
        "network-online.target"
        "agenix.service"
      ];
      wants = [
        "network-online.target"
        "agenix.service"
      ];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        EnvironmentFile = config.age.secrets.pangolin-env.path;
        # CLI writes ~/.config/pangolin (logs, state); systemd has no $HOME by default.
        StateDirectory = "pangolin";
        Environment = ["HOME=%S/pangolin"];
        # Binary does not auto-read CLIENT_* env vars (only the Docker entrypoint does).
        # Map EnvironmentFile vars onto the flags the CLI expects.
        ExecStart = pkgs.writeShellScript "pangolin-up" ''
          set -eu
          : "''${PANGOLIN_ENDPOINT:?PANGOLIN_ENDPOINT missing from EnvironmentFile}"
          : "''${CLIENT_ID:?CLIENT_ID missing from EnvironmentFile}"
          : "''${CLIENT_SECRET:?CLIENT_SECRET missing from EnvironmentFile}"
          exec ${lib.getExe pkgs.pangolin-cli} up --attach \
            --id "$CLIENT_ID" \
            --secret "$CLIENT_SECRET" \
            --endpoint "$PANGOLIN_ENDPOINT"
        '';
        Restart = "always";
        RestartSec = "5s";
        AmbientCapabilities = ["CAP_NET_ADMIN"];
        CapabilityBoundingSet = ["CAP_NET_ADMIN"];
        DeviceAllow = ["/dev/net/tun rw"];
      };
    };
  }
