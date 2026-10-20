{
  pkgs,
  inputs,
  ...
}: {
  imports = [inputs.zen-browser.homeModules.beta];

  # GUI desktop apps. Browsers and file managers live here rather than in the
  # CLI bundle.
  home.packages = [
    pkgs.jetbrains.datagrip
    pkgs.libreoffice-stable

    # Strata: keyboard-first GTK4 file manager (built from source, see
    # modules/strata-package.nix). Pairs with the gvfs service enabled in
    # modules/nixos/desktop.nix for trash + mounting. The browser's open/save
    # picker still comes from the gtk xdg portal, not from Strata.
    (pkgs.callPackage ../strata-package.nix {})
  ];

  # Strata is the default handler for folders.
  xdg.mimeApps = {
    enable = true;
    defaultApplications."inode/directory" = "io.github.lgse.Strata.desktop";
  };

  # Zen browser — Firefox-based, from the community flake (beta channel).
  # Managed through the flake's home-manager module (rather than just dropping
  # the package in home.packages) so that:
  #   1. `setAsDefaultBrowser` registers the xdg mime associations for
  #      http(s)/html and exports $BROWSER=zen-beta (used by gh, git, etc.).
  #   2. Stylix's zen-browser target can theme its profile (see below).
  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
  };

  # Paint Zen's chrome + about:/newtab pages with the same Kanagawa base16
  # palette Stylix uses everywhere else. The target writes userChrome.css and
  # userContent.css into the named profile and flips on the
  # `toolkit.legacyUserProfileCustomizations.stylesheets` pref for us.
  stylix.targets.zen-browser.profileNames = ["default"];
}
