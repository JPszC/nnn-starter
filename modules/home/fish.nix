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

      # Load personal SSH key into the agent once per login session.
      set -l _ssh_key $HOME/.ssh/id_rsa
      if set -q SSH_AUTH_SOCK
        and test -f $_ssh_key
        set -l _ssh_fp (ssh-keygen -lf $_ssh_key | string split -f 2 ' ')
        if test -n "$_ssh_fp"
          and not ssh-add -l 2>/dev/null | string match -q "*$_ssh_fp*"
          ssh-add --quiet $_ssh_key
        end
      end
    '';
  };
}
