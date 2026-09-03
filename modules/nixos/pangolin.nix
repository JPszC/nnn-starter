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
        ExecStart = "${lib.getExe pkgs.pangolin-cli} up --attach";
        Restart = "always";
        RestartSec = "5s";
        AmbientCapabilities = ["CAP_NET_ADMIN"];
        CapabilityBoundingSet = ["CAP_NET_ADMIN"];
      };
    };
  }
