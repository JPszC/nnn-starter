{pkgs, ...}: {
  # One palette to rule them all. Stylix derives colors for niri, noctalia,
  # alacritty, bat, btop, neovim, GTK/Qt and more from a single base16 scheme.
  stylix = {
    enable = true;
    polarity = "dark";

    # Kanagawa, vendored in-repo so the build never depends on whatever version
    # of `base16-schemes` happens to be pinned. To use an upstream scheme
    # instead: stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
    base16Scheme = ../../themes/kanagawa.yaml;

    # Native 3840×2160. The previous wallpaper is 1672×941, and scaling that
    # up to this panel softens the whole desktop.
    image = ../../themes/wallhaven-e82kv8_3840x2160.png;

    # Solid black. At 0.95 the wallpaper shows through and the VA panel
    # reads it as gray.
    opacity.terminal = 1.0;

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      # Logical px. At the 1.5 output scale this is a 48 px cursor on the 4K panel.
      size = 32;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        terminal = 12;
        applications = 11;
        desktop = 11;
        popups = 11;
      };
    };
  };
}
