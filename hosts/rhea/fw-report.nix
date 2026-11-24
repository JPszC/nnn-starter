{
  config,
  lib,
  pkgs,
  ...
}: let
  fw = config.networking.firewall;
  publicIf = "ens3";

  # `fw-report [1h|24h|7d]`: listening ports vs firewall, live connections, and
  # accepted/refused connection counts from the kernel log for that window.
  fw-report = pkgs.writeShellApplication {
    name = "fw-report";
    runtimeInputs = with pkgs; [coreutils gawk iproute2 systemd];
    text = ''
      [[ $EUID -eq 0 ]] || exec sudo "$0" "$@"
      window="''${1:-1h}"
      tcp=" ${toString fw.allowedTCPPorts} "
      udp=" ${toString fw.allowedUDPPorts} "

      echo "== Firewall on ${publicIf} =="
      echo "public TCP:${toString fw.allowedTCPPorts}  public UDP:${toString fw.allowedUDPPorts}  ping:${lib.boolToString fw.allowPing}"
      echo "trusted interfaces (everything allowed): ${toString fw.trustedInterfaces}"

      echo
      echo "== Listening ports =="
      # Process names may contain spaces, so the process column is "rest of line".
      ss -H -tulpn | awk -v tcp="$tcp" -v udp="$udp" '
        {
          addr = $5; port = $5; sub(/:[^:]*$/, "", addr); sub(/.*:/, "", port)
          proc = $0; sub(/^[[:space:]]*([^[:space:]]+[[:space:]]+){6}/, "", proc)
          if (proc == $0) proc = "(kernel)"
          allowed = ($1 == "tcp" && index(tcp, " " port " ")) || ($1 == "udp" && index(udp, " " port " "))
          if (addr ~ /^(127\.|\[::1\])|%lo$/) st = "local only"
          else if (allowed) st = "OPEN (public)"
          else st = "closed publicly (NetBird/local)"
          seen[$1 " " port] = 1
          printf "%-4s %-30s %-32s %s\n", $1, $5, st, proc
        }
        END {
          n = split(tcp, t, " "); for (i = 1; i <= n; i++) if (!seen["tcp " t[i]]) print "tcp  allowed port " t[i] ": nothing listening"
          n = split(udp, u, " "); for (i = 1; i <= n; i++) if (!seen["udp " u[i]]) print "udp  allowed port " u[i] ": nothing listening"
        }'

      echo
      echo "== Live connections (excluding loopback) =="
      ss -H -tunp state established | awk '$5 !~ /^(127\.|\[::1\])/ {
        proc = $0; sub(/^[[:space:]]*([^[:space:]]+[[:space:]]+){5}/, "", proc)
        printf "%-4s %-30s <-> %-30s %s\n", $1, $4, $5, proc
      }'

      # Kernel log lines look like: "<prefix> IN=ens3 ... SRC=1.2.3.4 ... PROTO=TCP ... DPT=22".
      summary() {
        local lines
        lines=$(journalctl -k -q -o cat --no-pager --since "-$window" -g "$1" || true)
        echo
        echo "== $2 in the last $window: $(grep -c . <<<"$lines" || true) =="
        [[ -n $lines ]] || return 0
        echo "-- by port --"
        awk '{ for (i = 1; i <= NF; i++) { split($i, kv, "="); f[kv[1]] = kv[2] } print tolower(f["PROTO"]) "/" f["DPT"] }' <<<"$lines" | sort | uniq -c | sort -rn | head -10
        echo "-- by source --"
        awk '{ for (i = 1; i <= NF; i++) { split($i, kv, "="); f[kv[1]] = kv[2] } print f["SRC"] }' <<<"$lines" | sort | uniq -c | sort -rn | head -10
      }
      summary "accepted connection: " "Accepted new public connections"
      summary "refused connection: " "Refused connections"
    '';
  };
in {
  environment.systemPackages = [fw-report];

  networking.firewall = {
    # Off by default in nixpkgs; fw-report reads these kernel log lines.
    logRefusedConnections = true;
    # Counterpart for accepted ones: new flows arriving on the public NIC.
    extraCommands = ''
      ip46tables -I nixos-fw-accept 1 -i ${publicIf} -m conntrack --ctstate NEW -j LOG --log-level info --log-prefix "accepted connection: "
    '';
  };
}
