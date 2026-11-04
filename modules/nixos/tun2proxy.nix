{
  config,
  lib,
  local,
  pkgs,
  ...
}: let
  # Full tunnel through a SOCKS/HTTP proxy.
  #
  # tun2proxy --setup is not used. It installs 0.0.0.0/1 and 128.0.0.0/1 in the
  # main table, and NetBird's rule "lookup main suppress_prefixlength 0"
  # (priority 105) prefers any non-default main-table route over the netbird
  # table. Those /1 routes would swallow the mesh.
  #
  # Lookup order once this service is up:
  #   100  from vopono's veth prefixes, full main      (VPN underlay, real default)
  #   105  main, skipping the default route            (on-link, proxy host)
  #   110  NetBird table, except fwmark 0x1bd00        (mesh, routed networks)
  #   115  table 7121                                  (other private ranges)
  #   120  table 7122, except fwmark 0x1bd00           (everything else → tun)
  #   main default                                     (NetBird's own sockets)
  #
  # Vopono puts each namespace on 10.200.<n>.0/24 and fd42:4242:<n>::/64.
  # WireGuard (or OpenVPN) leaves that namespace toward the public VPN
  # endpoint with that source address. The mark vopono sets stays inside the
  # namespace, so the host has to match the source prefix. Priority 100 is
  # before NetBird's suppress-default rule, so the real default route is used.
  #
  # fwmark 0x1bd00 is NetBird's control-plane mark: management, signal, relays,
  # ICE/STUN and the WireGuard socket. It must match NB_FWMARK_BASE.
  cfg = local.tun2proxy or {};
  enabled = cfg.enable or false;
  proxyAge = ../../secrets/tun2proxy-proxy.age;
  hasProxy = builtins.pathExists proxyAge;
  active = enabled && hasProxy;

  voponoPriority = 100;
  directPriority = 115;
  proxyPriority = 120;
  directTable = 7121;
  proxyTable = 7122;
  tun = "tun2proxy";
  netbirdMark = "0x1bd00";

  extra = cfg.extraBypass or [];
  extraV4 = lib.filter (p: !lib.hasInfix ":" p) extra;
  extraV6 = lib.filter (p: lib.hasInfix ":" p) extra;

  # Non-global IPv4 that must not enter the proxy. 100.64.0.0/10 is CGNAT;
  # this machine's NetBird range (100.105.0.0/16) sits inside it and is
  # matched earlier by the netbird table when the mesh is up.
  ipv4Via =
    [
      "10.0.0.0/8"
      "100.64.0.0/10"
      "169.254.0.0/16"
      "172.16.0.0/12"
      "192.0.0.0/24"
      "192.0.2.0/24"
      "192.168.0.0/16"
      "198.51.100.0/24"
      "203.0.113.0/24"
    ]
    ++ extraV4;

  shList = prefixes: lib.concatMapStringsSep "\n" lib.escapeShellArg prefixes;

  routeScript = pkgs.writeShellScript "tun2proxy-routes" ''
    set -euo pipefail

    tun=${lib.escapeShellArg tun}
    direct_table=${toString directTable}
    proxy_table=${toString proxyTable}
    vopono_pref=${toString voponoPriority}
    direct_pref=${toString directPriority}
    proxy_pref=${toString proxyPriority}
    mark=${lib.escapeShellArg netbirdMark}
    proxy_file=${lib.escapeShellArg config.age.secrets.tun2proxy-proxy.path}
    state=/run/tun2proxy/proxy-host
    # Global servers live in resolved.conf. resolvectl treats "global" as a
    # device name, so it cannot change them. List options are appended across
    # files; an empty DNS= or Domains= clears what the main file set, and the
    # next line is the value that should actually be used.
    dns_dropin=/run/systemd/resolved.conf.d/tun2proxy.conf

    ipv4_via=(
      ${shList ipv4Via}
    )
    ipv6_extra=(
      ${shList extraV6}
    )

    rule_del() {
      ip -4 rule del pref "$vopono_pref" 2>/dev/null || true
      ip -4 rule del pref "$direct_pref" 2>/dev/null || true
      ip -4 rule del pref "$proxy_pref" 2>/dev/null || true
      ip -6 rule del pref "$vopono_pref" 2>/dev/null || true
      ip -6 rule del pref "$direct_pref" 2>/dev/null || true
      ip -6 rule del pref "$proxy_pref" 2>/dev/null || true
    }

    flush_tables() {
      ip -4 route flush table "$direct_table" 2>/dev/null || true
      ip -4 route flush table "$proxy_table" 2>/dev/null || true
      ip -6 route flush table "$direct_table" 2>/dev/null || true
      ip -6 route flush table "$proxy_table" 2>/dev/null || true
    }

    proxy_host_del() {
      local host
      [[ -r $state ]] || return 0
      host=$(tr -d '[:space:]' < "$state")
      [[ -n $host ]] || return 0
      if [[ $host == *:* ]]; then
        ip -6 route del "$host" 2>/dev/null || true
      else
        ip -4 route del "$host" 2>/dev/null || true
      fi
    }

    # First NetworkManager device that has resolvers. A veth default route
    # (vopono, docker) often has none; the uplink is the one NM configured.
    pick_uplink() {
      local line dev="" s
      local -a servers=()
      UPLINK_DEV=""
      UPLINK_SERVERS=()
      while IFS= read -r line; do
        case $line in
          GENERAL.DEVICE:*)
            if [[ -n $dev && ''${#servers[@]} -gt 0 ]]; then
              UPLINK_DEV=$dev
              UPLINK_SERVERS=("''${servers[@]}")
              return 0
            fi
            dev=''${line#GENERAL.DEVICE:}
            servers=()
            ;;
          IP4.DNS*)
            s=''${line#*:}
            s=''${s//[[:space:]]/}
            if [[ -n $s && $s != 198.18.* && -n $dev && $dev != "$tun" && $dev != lo ]]; then
              servers+=("$s")
            fi
            ;;
        esac
      done < <(nmcli -t -f GENERAL.DEVICE,IP4.DNS device show 2>/dev/null || true)
      if [[ -n $dev && ''${#servers[@]} -gt 0 ]]; then
        UPLINK_DEV=$dev
        UPLINK_SERVERS=("''${servers[@]}")
        return 0
      fi
      return 1
    }

    # SIGHUP reloads resolved directly. systemctl reload from ExecStop deadlocks:
    # PID 1 will not start that job until this stop job finishes.
    reload_resolved() {
      local pid
      pid=$(systemctl show -p MainPID --value systemd-resolved 2>/dev/null || true)
      if [[ -z $pid || $pid == 0 ]]; then
        echo "tun2proxy: systemd-resolved is not running" >&2
        return 1
      fi
      kill -HUP "$pid"
    }

    # $1 is one address that must appear on the global "DNS Servers" line.
    # Fallback servers also contain public resolvers, so the match is only
    # that line. Dots in the address are literal.
    wait_for_global_dns() {
      local needle=$1 i
      for ((i = 0; i < 20; i++)); do
        # Read the whole status. Exiting awk early SIGPIPEs resolvectl, and
        # pipefail would treat a successful match as a failure.
        if resolvectl status 2>/dev/null | awk -v n="$needle" '
          /^Global$/ { g = 1; next }
          /^Link / { g = 0 }
          g && $1 == "DNS" && $2 == "Servers:" {
            for (i = 3; i <= NF; i++) if ($i == n) hit = 1
          }
          END { exit hit ? 0 : 1 }
        '; then
          return 0
        fi
        sleep 0.05
      done
      return 1
    }

    write_dns_dropin() {
      local line="" s first=""
      for s in "$@"; do
        [[ $s =~ ^[0-9A-Fa-f:.]+$ ]] || continue
        [[ -n $first ]] || first=$s
        line+="$s "
      done
      if [[ -z $first ]]; then
        echo "tun2proxy: no DNS servers to configure" >&2
        return 1
      fi
      mkdir -p /run/systemd/resolved.conf.d
      cat > "$dns_dropin" <<EOF
[Resolve]
DNS=
DNS=$line
Domains=
Domains=~.
EOF
      reload_resolved || return 1
      wait_for_global_dns "$first" || return 1
      resolvectl flush-caches || true
    }

    # 198.18.0.1 only exists inside the tun. Leaving it configured after the
    # device is gone black-holes every lookup, which looks like "no internet".
    direct_dns() {
      local -a servers=()
      if pick_uplink; then
        servers=("''${UPLINK_SERVERS[@]}")
      else
        servers=(1.1.1.1 8.8.8.8 9.9.9.9)
      fi
      write_dns_dropin "''${servers[@]}" \
        || echo "tun2proxy: could not restore DNS" >&2
    }

    tunnel_dns() {
      write_dns_dropin 198.18.0.1 || {
        echo "tun2proxy: could not set tunnel DNS" >&2
        return 1
      }
    }

    cleanup() {
      rule_del
      flush_tables
      proxy_host_del
      rm -f "$state"
      ip route flush cache || true
    }

    if [[ ''${1:-} == stop ]]; then
      # Switch DNS before the tun disappears, or lookups hit 198.18.0.1 and die.
      direct_dns
      cleanup
      ip link del "$tun" 2>/dev/null || true
      exit 0
    fi
    if [[ ''${1:-} == pre ]]; then
      # ExecStartPost must not race a delete. Drop a leftover device first.
      ip link del "$tun" 2>/dev/null || true
      exit 0
    fi

    for ((i = 0; i < 50; i++)); do
      if ip link show "$tun" >/dev/null 2>&1; then
        break
      fi
      sleep 0.1
    done
    ip link show "$tun" >/dev/null

    # tun2proxy addresses the device as 10.0.0.33/24. That connected route
    # lives in the main table and would capture a real 10.0.0.0/24 LAN.
    # Routing is by device, so the address is not needed.
    ip -4 addr flush dev "$tun"
    ip -6 addr flush dev "$tun" 2>/dev/null || true
    ip link set "$tun" up
    sysctl -q -w "net.ipv4.conf.$tun.rp_filter=0"
    sysctl -q -w "net.ipv6.conf.$tun.disable_ipv6=0" || true

    url=$(tr -d '[:space:]' < "$proxy_file")
    rest=''${url#*://}
    rest=''${rest#*@}
    hostport=''${rest%%/*}
    hostport=''${hostport%%\?*}
    if [[ $hostport == \[* ]]; then
      proxy_host=''${hostport#\[}
      proxy_host=''${proxy_host%%\]*}
    else
      proxy_host=''${hostport%%:*}
    fi
    if [[ -z $proxy_host ]]; then
      echo "tun2proxy: proxy URL has no host" >&2
      exit 1
    fi

    # Drop any previous rules before installing the host route, so a reload
    # cannot send the proxy's own connection back into the tun.
    cleanup
    printf '%s\n' "$proxy_host" > "$state"

    v4=$(ip -4 route show default | awk '!/dev '"$tun"'/ { print; exit }')
    if [[ -z $v4 ]]; then
      echo "tun2proxy: no IPv4 default route" >&2
      exit 1
    fi
    gw4=$(awk '{ for (i = 1; i <= NF; i++) if ($i == "via") { print $(i + 1); exit } }' <<< "$v4")
    dev4=$(awk '{ for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit } }' <<< "$v4")
    if [[ -z $dev4 || -z $gw4 ]]; then
      echo "tun2proxy: default route has no via/dev ($v4)" >&2
      exit 1
    fi

    v6=$(ip -6 route show default | awk '!/dev '"$tun"'/ { print; exit }' || true)
    gw6=$(awk '{ for (i = 1; i <= NF; i++) if ($i == "via") { print $(i + 1); exit } }' <<< "$v6")
    dev6=$(awk '{ for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit } }' <<< "$v6")

    if [[ $proxy_host == *:* ]]; then
      if [[ -z $gw6 || -z $dev6 ]]; then
        echo "tun2proxy: proxy is IPv6 but there is no IPv6 default route" >&2
        exit 1
      fi
      ip -6 route replace "$proxy_host" via "$gw6" dev "$dev6"
    else
      ip -4 route replace "$proxy_host" via "$gw4" dev "$dev4"
    fi

    for prefix in "''${ipv4_via[@]}"; do
      ip -4 route replace "$prefix" via "$gw4" dev "$dev4" table "$direct_table"
    done
    # Multicast has to stay on the LAN interface; a via-gateway route is rejected.
    ip -4 route replace 224.0.0.0/4 dev "$dev4" scope link table "$direct_table" \
      || echo "tun2proxy: multicast bypass skipped" >&2

    ip -4 route replace 0.0.0.0/1 dev "$tun" table "$proxy_table"
    ip -4 route replace 128.0.0.0/1 dev "$tun" table "$proxy_table"

    add_v6() {
      local prefix=$1
      if [[ -n $gw6 && -n $dev6 ]]; then
        ip -6 route replace "$prefix" via "$gw6" dev "$dev6" table "$direct_table"
      else
        ip -6 route replace unreachable "$prefix" table "$direct_table"
      fi
    }
    add_v6 fc00::/7
    add_v6 2001:db8::/32
    # Link-local and multicast are on-link in the main table when they exist.
    # unreachable here is only the fallback so they are not proxied.
    ip -6 route replace unreachable fe80::/10 table "$direct_table" \
      || echo "tun2proxy: fe80 bypass skipped" >&2
    ip -6 route replace unreachable ff00::/8 table "$direct_table" \
      || echo "tun2proxy: IPv6 multicast bypass skipped" >&2
    for prefix in "''${ipv6_extra[@]}"; do
      add_v6 "$prefix"
    done

    ip -6 route replace ::/1 dev "$tun" table "$proxy_table"
    ip -6 route replace 8000::/1 dev "$tun" table "$proxy_table"

    # Full main table, including the physical default. Existing vopono
    # namespaces are covered without watching interfaces come and go.
    ip -4 rule add pref "$vopono_pref" from 10.200.0.0/16 lookup main
    ip -6 rule add pref "$vopono_pref" from fd42:4242::/32 lookup main
    ip -4 rule add pref "$direct_pref" lookup "$direct_table"
    ip -4 rule add pref "$proxy_pref" not fwmark "$mark" lookup "$proxy_table"
    ip -6 rule add pref "$direct_pref" lookup "$direct_table"
    ip -6 rule add pref "$proxy_pref" not fwmark "$mark" lookup "$proxy_table"
    ip route flush cache || true
    tunnel_dns
  '';

  startScript = pkgs.writeShellScript "tun2proxy-start" ''
    set -euo pipefail
    url=$(tr -d '[:space:]' < ${lib.escapeShellArg config.age.secrets.tun2proxy-proxy.path})
    if [[ -z $url ]]; then
      echo "tun2proxy: proxy URL file is empty" >&2
      exit 1
    fi
    exec ${lib.getExe pkgs.tun2proxy} \
      --tun ${lib.escapeShellArg tun} \
      --proxy "$url" \
      --dns virtual \
      --ipv6-enabled \
      --exit-on-fatal-error \
      --max-sessions 4096 \
      --verbosity info
  '';

  # `tun stop` has to return the machine to the real network even when the
  # proxy process is wedged. ExecStop drops the routes before systemd waits
  # for the process, and this wrapper is the short command for that.
  tunCmd = pkgs.writeShellApplication {
    name = "tun";
    runtimeInputs = [pkgs.systemd];
    text = ''
      usage() {
        echo "usage: tun {stop|start|restart|status}" >&2
        exit 1
      }

      case ''${1:-} in
        stop | shutdown) action=stop ;;
        start) action=start ;;
        restart) action=restart ;;
        status)
          exec systemctl status tun2proxy --no-pager
          ;;
        *) usage ;;
      esac

      if ! systemctl cat tun2proxy.service >/dev/null 2>&1; then
        echo "tun2proxy is not installed. Set tun2proxy.enable = true in local.nix, then run: nh os switch" >&2
        exit 1
      fi

      sudo systemctl "$action" tun2proxy
      case "$action" in
        stop) echo "tun2proxy stopped" ;;
        start) echo "tun2proxy started" ;;
        restart) echo "tun2proxy restarted" ;;
      esac
    '';
  };
in {
  config = lib.mkMerge [
    {
      warnings = lib.optional (enabled && !hasProxy) ''
        tun2proxy is enabled, but secrets/tun2proxy-proxy.age is not in the flake, so the tunnel is not installed.
        From the secrets/ directory run `agenix -e tun2proxy-proxy.age` and put a single line in it:
        socks5://user:pass@host:port
        (percent-encode any extra @ or : in the userinfo). `git add` that file so Nix can see it, then run `nh os switch`.
      '';
      # Installed even while the tunnel is off, so `tun start` is available
      # after a switch without first enabling the service.
      environment.systemPackages = [tunCmd];
    }
    (lib.mkIf active {
      age.secrets.tun2proxy-proxy.file = proxyAge;

      # DHCP DNS is a private address, so it would bypass the tunnel and answer
      # public names. NetworkManager must not install it. While the tunnel is
      # up the route script's drop-in is the only global resolver (198.18.0.1,
      # routed into the tun). Stop replaces that drop-in with the uplink's
      # resolvers. NetBird still installs its own per-link domains
      # (*.netbird.cloud), which are more specific than ~. and keep winning.
      networking.networkmanager.dns = lib.mkForce "none";

      # Reply packets are written back through the tun with the real source
      # address. Strict reverse-path filtering drops those.
      networking.firewall.trustedInterfaces = [tun];

      networking.networkmanager.dispatcherScripts = [
        {
          source = pkgs.writeText "tun2proxy-reload" ''
            #!/bin/sh
            case "$2" in
              up|dhcp4-change|dhcp6-change)
                if /run/current-system/sw/bin/systemctl is-active --quiet tun2proxy; then
                  /run/current-system/sw/bin/systemctl reload tun2proxy
                fi
                ;;
            esac
          '';
        }
      ];

      systemd.services.tun2proxy = {
        description = "tun2proxy full tunnel";
        wantedBy = ["multi-user.target"];
        after = [
          "network-online.target"
          "netbird.service"
          "systemd-resolved.service"
        ];
        wants = ["network-online.target"];
        path = with pkgs; [
          coreutils
          gawk
          iproute2
          networkmanager
          procps
          systemd
        ];
        serviceConfig = {
          ExecStartPre = "${routeScript} pre";
          ExecStart = startScript;
          ExecStartPost = "${routeScript} start";
          ExecReload = "${routeScript} start";
          # Drop routes and restore DNS before signaling the process. SIGTERM
          # is the stop signal so a normal exit is not recorded as a failure;
          # a process that ignores it is SIGKILLed when the timeout expires.
          ExecStop = "${routeScript} stop";
          ExecStopPost = "${routeScript} stop";
          RuntimeDirectory = "tun2proxy";
          Restart = "on-failure";
          RestartSec = "3s";
          TimeoutStopSec = "5s";
          LimitNOFILE = 65536;
        };
      };
    })
  ];
}
