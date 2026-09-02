{
  lib,
  pkgs,
  ...
}: {
  # `nix-shell` / `nix-shell -p` hardcode bash. any-nix-shell re-execs fish
  # inside the ad-hoc environment so we keep our shell, aliases, and prompt.
  home.packages = [pkgs.any-nix-shell];

  programs.fish = {
    enable = true;

    plugins = [
      {
        name = "tide";
        src = pkgs.fishPlugins.tide.src;
      }
    ];

    # Modern-unix muscle memory: keep the old names, get the new tools.
    # The lsd module also defines ls/ll/la, so force ours to win the merge.
    shellAliases = {
      ls = lib.mkForce "lsd";
      ll = lib.mkForce "lsd -l";
      la = lib.mkForce "lsd -la";
      lt = lib.mkForce "lsd --tree";
      cat = "bat";
      top = "btop";
      du = "dust";
      df = "duf";
      ps = "procs";
      ping = "gping";
      vim = "nvim";
      vi = "nvim";
      g = "git";
      lg = "lazygit";

      # nh-powered rebuilds from anywhere.
      rebuild = "nh os switch";
      update = "nh os switch --update";
    };

    interactiveShellInit = ''
      # Keep fish inside `nix-shell` instead of falling back to bash.
      ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source

      # Tide Lean, two-line — applied as globals so Nix owns the prompt
      # (no fish_variables writes, no activation-time `tide configure`).
      string replace -r '^' 'set -g ' < ${pkgs.fishPlugins.tide.src}/functions/tide/configure/configs/lean.fish | source
      set -g tide_left_prompt_items pwd git nix_shell newline character
      set -g tide_right_prompt_items status cmd_duration
      set -g tide_cmd_duration_threshold 2000
    '';
  };
}
