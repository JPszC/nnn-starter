{
  lib,
  pkgs,
  username,
  ...
}: let
  # glibc asks the host nscd before it reads nsswitch.conf. nscd resolves
  # through systemd-resolved, which tun2proxy points at 198.18.0.0/15. Those
  # addresses only exist on the host tun, so a name looked up inside the VPN
  # namespace never reaches the tunnel. Setting LOCALDOMAIN makes glibc skip
  # nscd and use the namespace resolv.conf. vopono already rewrites that
  # nsswitch line to "hosts: files dns" and points it at the VPN resolver.
  # An empty value is enough: glibc only checks that the variable is present,
  # and it also drops the host search domain so netbird.cloud is not appended.
  voponoWrapped = pkgs.writeShellScriptBin "vopono" ''
    if [[ -z ''${LOCALDOMAIN+x} ]]; then
      export LOCALDOMAIN=
    fi
    exec ${lib.getExe pkgs.vopono} "$@"
  '';

  # Runs a command inside a netns using the age-decrypted Proton WireGuard
  # config (`secrets/proton-vpn.conf.age` → /run/agenix/proton-vpn).
  vopono-proton = pkgs.writeShellApplication {
    name = "vopono-proton";
    runtimeInputs = [voponoWrapped];
    text = ''
      config=/run/agenix/proton-vpn
      if [[ ! -r "$config" ]]; then
        echo "vopono-proton: no decrypted Proton WireGuard config at $config" >&2
        echo "Download a .conf from https://account.protonvpn.com → Downloads → WireGuard," >&2
        echo "then: cd secrets && agenix -e proton-vpn.conf.age && nh os switch" >&2
        exit 1
      fi
      exec vopono exec --provider custom --custom "$config" --protocol wireguard "$@"
    '';
  };
in {
  # ── Tools with a home-manager program module ──────────────────────────────
  # Using programs.* (rather than raw packages) gets us shell integration and
  # Stylix theming for free.

  programs.lsd = {
    enable = true;
    settings = {
      date = "relative";
      icons.when = "auto";
    };
  };

  programs.bat.enable = true;
  programs.btop.enable = true;
  programs.ripgrep.enable = true;
  programs.fd.enable = true;
  programs.zellij.enable = true;
  programs.jq.enable = true;

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    defaultCommand = "fd --type f --hidden --exclude .git";
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = ["--cmd cd"]; # `cd` becomes smart, keeps muscle memory.
  };

  programs.tealdeer = {
    enable = true;
    settings.updates.auto_update = true;
  };

  # ── Everything else ───────────────────────────────────────────────────────
  home.packages = with pkgs; [
    # language runtimes
    (python3.withPackages (ps: [
      ps.pip
      ps.pandas
      ps.ipykernel
      ps.openpyxl
      ps.trafilatura # web text extraction CLI (was a `uv tool`)
    ])) # venv is included in Python's standard library
    uv # was a hand-copied binary in ~/.local/bin
    ruff # was `nix profile install`ed
    basedpyright # was `nix profile install`ed

    # navigation / files
    eza # alternative listing to lsd, handy for `eza --tree`
    yazi # TUI file manager

    # system / inspection
    dust # disk usage (du replacement)
    duf # disk free (df replacement)
    procs # process viewer (ps replacement)
    bandwhich # per-process bandwidth
    gping # ping with a graph

    # data / misc
    yq-go # yaml/json/xml processor
    curlie # httpie-like curl frontend
    sd # sed-like find & replace

    # nix workflow
    nix-output-monitor # pretty build output (`nom`)
    alejandra # formatter
    devenv # per-project dev environments (`use devenv` in .envrc)
    proton-vpn
    wireguard-tools
    voponoWrapped # `vopono exec`; skips host nscd so VPN DNS is used
    vopono-proton # `vopono-proton firefox` — uses the age-decrypted Proton config
    openvpn # vopono OpenVPN backends (Proton/custom); WireGuard uses wireguard-tools
  ];

  # Personal scripts (~/bin) and `uv tool` / `pipx`-style installs (~/.local/bin).
  home.sessionPath = [
    "$HOME/bin"
    "$HOME/.local/bin"
  ];

  # nh is a nicer frontend for nixos-rebuild + garbage collection. Point it at
  # wherever you keep this flake checked out.
  programs.nh = {
    enable = true;
    flake = "/home/${username}/nnn-starter";
  };
}
