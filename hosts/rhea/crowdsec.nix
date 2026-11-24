{config, ...}: let
  lapi = "http://${config.services.crowdsec.settings.config.api.server.listen_uri}";
  uiData = "/var/lib/crowdsec-web-ui";
  # Written by crowdsec-web-ui-register; holds the UI's LAPI watcher password.
  uiEnv = "/var/lib/crowdsec-web-ui-lapi/env";
in {
  # CrowdSec engine + local API on 127.0.0.1:8080. The module's default
  # acquisition reads sshd.service from the journal; crowdsecurity/linux brings
  # the sshd parsers/scenarios (they accept OpenSSH's `sshd-session` lines).
  services.crowdsec = {
    enable = true;
    hub.collections = ["crowdsecurity/linux"];
    # Registers with CrowdSec's central API: shares signals, pulls the community blocklist.
    # Must live in data_dir: the setup unit can't write /var/lib/crowdsec itself.
    settings.config.api.server.online_client.credentials_path = "/var/lib/crowdsec/data/online_api_credentials.yaml";
  };

  # Enforces decisions in iptables (registers itself with the local API).
  services.crowdsec-firewall-bouncer.enable = true;

  # Watcher account for the web UI. Re-created with a fresh random password on
  # every start, so it self-heals if the CrowdSec database is reset.
  systemd.services.crowdsec-web-ui-register = {
    after = ["crowdsec.service"];
    requires = ["crowdsec.service"];
    path = [config.services.crowdsec.package];
    script = ''
      umask 077
      cscli machines add crowdsec-web-ui --auto --force -f "$STATE_DIRECTORY/credentials.yaml"
      printf 'CONFIG_INSTANCE_LAPI_AUTH_PASSWORD=%s\n' \
        "$(sed -n 's/^password: *//p' "$STATE_DIRECTORY/credentials.yaml")" > ${uiEnv}
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Same identity/paths as the firewall bouncer's register unit, so cscli can write the DB.
      User = config.services.crowdsec.user;
      Group = config.services.crowdsec.group;
      DynamicUser = true;
      ReadWritePaths = ["/var/lib/crowdsec"];
      StateDirectory = "crowdsec-web-ui-lapi";
    };
  };

  # https://github.com/TheDuffman85/crowdsec-web-ui on :3001. Host networking:
  # podman's -p publishing would DNAT around the INPUT firewall and make the
  # port public; this way only NetBird and localhost (Pangolin) can reach it.
  virtualisation.oci-containers.containers.crowdsec-web-ui = {
    image = "ghcr.io/theduffman85/crowdsec-web-ui:2026.11.12";
    environment = {
      CONFIG_SERVER_PORT = "3001";
      CONFIG_INSTANCE_LAPI_URL = lapi;
      CONFIG_INSTANCE_LAPI_AUTH_USERNAME = "crowdsec-web-ui";
    };
    environmentFiles = [uiEnv];
    volumes = ["${uiData}:/app/data"];
    # The image's HEALTHCHECK is hardcoded to :3000.
    extraOptions = ["--network=host" "--no-healthcheck"];
  };
  systemd.services.podman-crowdsec-web-ui = {
    after = ["crowdsec-web-ui-register.service"];
    requires = ["crowdsec-web-ui-register.service"];
  };
  # Users, passkeys, settings (state.db). The entrypoint chowns it to the image's node user.
  systemd.tmpfiles.rules = ["d ${uiData} 0750 root root -"];
}
