{...}: {
  # Codex — OpenAI's coding-agent CLI (binary: `codex`).
  #
  # We only install the package; ~/.codex (auth, config.toml, sessions) stays
  # runtime-managed, so nothing here fights what `codex` writes at runtime.
  # To manage it declaratively instead, set programs.codex.settings, .context,
  # .profiles, … (see the home-manager module docs) — config.toml is only
  # written once you provide some.
  programs.codex.enable = true;
}
