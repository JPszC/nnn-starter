{pkgs, ...}: {
  # Cursor — AI-powered VS Code fork. Marked unfree, so it relies on the
  # allowUnfree set in flake.nix. Zed stays the default GUI handler for
  # text/source files (see modules/home/zed.nix); this is an extra editor you
  # launch by name (`cursor`) or from the Noctalia launcher.
  #
  # We only install the package; login, settings, and extensions stay
  # runtime-managed under ~/.config/Cursor and ~/.cursor, so nothing here
  # fights what Cursor writes at runtime.
  # `code-cursor-fhs` is the FHS-wrapped build: Cursor is an AppImage, and
  # extensions that ship native bits expect a glibc layout rather than Nix
  # store paths.
  programs.cursor = {
    enable = true;
    package = pkgs.code-cursor-fhs;
  };
}
