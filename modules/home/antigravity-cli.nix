{...}: {
  # Antigravity CLI — Google's terminal agent (binary: `agy`). Marked unfree, so
  # it relies on the allowUnfree set in flake.nix.
  #
  # We only install the package; ~/.gemini (auth, settings, sessions) stays
  # runtime-managed, so nothing here fights what `agy` writes at runtime.
  # To manage it declaratively instead, set programs.antigravity-cli.settings,
  # .mcpServers, .skills, … (see the home-manager module docs) — settings.json
  # is only written once you provide some.
  programs.antigravity-cli.enable = true;
}
