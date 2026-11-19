{...}: {
  # Codex — OpenAI's coding-agent CLI (binary: `codex`).
  #
  # Use the nixpkgs package unchanged. An overrideAttrs (extra libraries, an
  # AWS-LC prefix) changes the derivation, misses cache.nixos.org, and builds
  # Codex from source. That Cargo build runs one rustc per core; on a 32GB
  # machine the kernel OOM-killed rustc (`cargo-auditable: rustc was terminated
  # by a deadly signal`).
  #
  # ~/.codex (auth, config.toml, sessions) stays runtime-managed, so nothing
  # here fights what `codex` writes at runtime. To manage it declaratively
  # instead, set programs.codex.settings, .context, .profiles, … (see the
  # home-manager module docs) — config.toml is only written once you provide some.
  programs.codex.enable = true;
}
