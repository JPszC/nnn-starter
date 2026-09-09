{
  pkgs,
  username,
  ...
}: let
  # Runs a command inside a netns using the age-decrypted Proton WireGuard
  # config (`secrets/proton-vpn.conf.age` → /run/agenix/proton-vpn).
  vopono-proton = pkgs.writeShellApplication {
    name = "vopono-proton";
    runtimeInputs = [pkgs.vopono];
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
    (python3.withPackages (ps: [ps.pip])) # venv is included in Python's standard library

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
    vopono # run a single app through a VPN netns (`vopono exec`)
    vopono-proton # `vopono-proton firefox` — uses the age-decrypted Proton config
    openvpn # vopono OpenVPN backends (Proton/custom); WireGuard uses wireguard-tools
  ];

  # nh is a nicer frontend for nixos-rebuild + garbage collection. Point it at
  # wherever you keep this flake checked out.
  programs.nh = {
    enable = true;
    flake = "/home/${username}/nnn-starter";
  };
}
