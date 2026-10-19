{
  pkgs,
  inputs,
  ...
}: {
  disabledModules = ["programs/noctalia"];

  # The Noctalia desktop shell: bar, launcher, notifications, control center,
  # lock screen and wallpaper, all in one. Colors follow Stylix.
  programs.noctalia = {
    enable = true;

    # Prebuilt package from noctalia.cachix.org (see
    # modules/nixos/noctalia.nix), re-linked onto the system glibc so the
    # lock screen can load the system's PAM modules (see
    # ../noctalia-package.nix for why).
    package = import ../noctalia-package.nix {inherit pkgs inputs;};

    # Run as a systemd user service tied to the graphical (niri) session so it
    # starts and stops with your login.
    systemd.enable = true;

    # Bar workspace pills show the niri workspace names (web / orca / code,
    # see modules/home/niri.nix) instead of numbers. max_label_chars defaults
    # to 1, which would cut them to "w" / "o" / "c".
    settings.widget.workspaces = {
      label_source = "name";
      max_label_chars = 8;
    };

    # Configure the shell interactively via its control center (Mod+Space →
    # settings) and, once you're happy, pin the values declaratively here under
    # `settings = { ... };` (schema at docs.noctalia.dev). Left at defaults so
    # the build can't break on a settings key that doesn't exist yet.
  };
}
