{pkgs, ...}: {
  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono # JetBrains Mono, patched with Nerd Font glyphs.
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];

    enableDefaultPackages = true;

    # The panel runs at scale 1.5, so glyphs are resampled. Subpixel (RGB)
    # antialiasing assumes a 1:1 pixel grid and leaves color fringes after that
    # resample. Slight grayscale hinting stays sharp without the fringe.
    fontconfig = {
      hinting = {
        enable = true;
        style = "slight";
      };
      subpixel.rgba = "none";
    };

    fontconfig.defaultFonts = {
      monospace = ["JetBrainsMono Nerd Font"];
      sansSerif = ["Noto Sans"];
      serif = ["Noto Serif"];
      emoji = ["Noto Color Emoji"];
    };
  };
}
