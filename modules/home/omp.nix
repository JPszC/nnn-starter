{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.omp.homeManagerModules.default];

  # OMP (oh-my-pi) — coding-agent CLI (binary: `omp`).
  #
  # We only install the package; ~/.omp (auth, agent config, sessions) stays
  # runtime-managed. Leave programs.omp.settings unset: when it is set,
  # home-manager overwrites ~/.omp/agent/config.yml on every switch.
  programs.omp = {
    enable = true;
    package = inputs.omp.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      # Stay on the pinned nightly (2026-08-12). That cargo is what published
      # jj-lib 0.44 and what understands `.cargo/config.toml`'s
      # `embed-metadata = false`. The previous nightly (2026-08-04) compiles
      # jj-lib without passing `--extern rand_chacha`, so `secure_config.rs`
      # fails with E0463.
      #
      # That same nightly SIGSEGVs in LLVM's FunctionSpecializer
      # (CodeMetrics::collectEphemeralValues) while compiling `pi-vcs` at
      # opt-level 3. The specializer is skipped for functions with optsize,
      # which Cargo's opt-level "s" sets. Applying "s" to the whole profile
      # instead ICEs in tokio ("invalid source scope") and SIGSEGVs in
      # gix-filter, so only `pi-vcs` is lowered.
      #
      # Cargo still appends the workspace's `lto = "fat"` / `codegen-units = 1`
      # after RUSTFLAGS, so the profile env vars are what actually turn fat LTO
      # off. pcre2-sys 0.2.10 compiles bundled pcre2_compile.c at -O3 (upstream
      # sets PCRE2_SYS_STATIC=1). This GCC segfaults in the lim pass on
      # parse_regex. The cc wrapper appends NIX_CFLAGS_COMPILE after that -O3,
      # so -fno-tree-loop-im disables the crashing pass.
      postPatch =
        (old.postPatch or "")
        + ''
          cat >> Cargo.toml <<'EOF'

          [profile.release.package."pi-vcs"]
          opt-level = "s"
          EOF
        '';
      env =
        (old.env or {})
        // {
          CARGO_PROFILE_RELEASE_LTO = "off";
          CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "16";
          NIX_CFLAGS_COMPILE = "-fno-tree-loop-im";
        };
    });
  };
}
