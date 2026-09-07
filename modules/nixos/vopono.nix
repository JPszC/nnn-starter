{
  pkgs,
  lib,
  username,
  ...
}: let
  # Encrypted WireGuard config from Proton (see secrets/secrets.nix). Gated so
  # a missing file doesn't break evaluation before you've run `agenix -e`.
  protonConfig = ../../secrets/proton-vpn.conf.age;
  hasProtonConfig = builtins.pathExists protonConfig;
in {
  # Privileged helper for vopono (the CLI is in modules/home/cli.nix).
  # The daemon owns netns / firewall / tun setup and listens on
  # /run/vopono.sock, so `vopono exec` as your user doesn't need sudo.
  # Docs: https://github.com/jamesmcm/vopono/blob/master/USERGUIDE.md
  age.secrets.proton-vpn = lib.mkIf hasProtonConfig {
    file = protonConfig;
    # Named path so `vopono-proton` / `--custom` can find it. owner=user +
    # /run/agenix mode 0751 means you can open the file without listing the dir.
    path = "/run/agenix/proton-vpn.conf";
    owner = username;
    mode = "0400";
  };

  systemd.services.vopono = {
    description = "Vopono root daemon";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];

    # Bare crate build; these are the tools it shells out to for WireGuard,
    # OpenVPN, routing, and killswitches. Keep them on the daemon PATH even
    # if the user-facing CLI is installed via home-manager.
    path = with pkgs; [
      iproute2
      iptables
      libnatpmp # `natpmpc` for Proton `--custom-port-forwarding protonvpn`
      nftables
      openvpn
      procps
      util-linux
      wireguard-tools
    ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${lib.getExe pkgs.vopono} daemon";
      Restart = "on-failure";
      RestartSec = "2s";
      Environment = ["RUST_LOG=info"];
    };
  };
}
