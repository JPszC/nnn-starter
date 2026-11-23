{username, ...}: {
  imports = [
    ./cli.nix
    ./fish.nix
    ./git.nix
    ./alacritty.nix
    ./neovim.nix
    ./zed.nix
    ./cursor.nix
    ./gtk.nix
    ./niri.nix
    ./noctalia.nix
    ./direnv.nix
    ./claude-code.nix
    ./codex.nix
    ./antigravity-cli.nix
    ./omp.nix
    ./orca.nix
    ./apps.nix
    ./media.nix
    ./discord.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Match system.stateVersion in hosts/nnn/default.nix. Don't bump casually.
  home.stateVersion = "25.05";

  # Home Manager removed Wayprompt; the pinned Stylix still configures it.
  stylix.targets.wayprompt.enable = false;

  programs.home-manager.enable = true;
}
