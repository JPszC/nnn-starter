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

    # Tide renders each prompt in `fish -c` (non-interactive). Globals set
    # only in interactiveShellInit are invisible there, so cmd_duration
    # sees an empty $tide_cmd_duration_threshold (`test 0 -gt`).
    shellInit = ''
      set -g _tide_color_dark_blue 0087AF
      set -g _tide_color_dark_green 5FAF00
      set -g _tide_color_gold D7AF00
      set -g _tide_color_green 5FD700
      set -g _tide_color_light_blue 00AFFF
      string replace -r '^' 'set -g ' < ${pkgs.fishPlugins.tide.src}/functions/tide/configure/icons.fish | source
      string replace -r '^' 'set -g ' < ${pkgs.fishPlugins.tide.src}/functions/tide/configure/configs/lean.fish | source
      set -g tide_left_prompt_items pwd git nix_shell newline character
      set -g tide_right_prompt_items status cmd_duration
      set -g tide_cmd_duration_threshold 2000
    '';

    interactiveShellInit = ''
      # Keep fish inside `nix-shell` instead of falling back to bash.
      ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source

      # CMD_DURATION is unset on first prompt; tide's cmd_duration item needs it.
      set -g CMD_DURATION 0
    '';
  };
}
