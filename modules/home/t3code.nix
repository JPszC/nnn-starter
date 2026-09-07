{pkgs, ...}: {
  # T3 Code — GUI (`t3code-desktop`) and CLI (`t3`) for driving coding agents
  # already on this machine (Claude Code, Codex, Cursor). Auth and project
  # state live under T3CODE_HOME (~/.t3code) at runtime.
  #
  # The nixpkgs wrapper can prefix provider CLIs onto PATH. Codex is on by
  # default; Claude is too because we install it (see claude-code.nix). Cursor
  # stays unwrapped — wrapping `code-cursor` would pull a second Electron
  # closure, and the FHS build in cursor.nix is already on the user PATH.
  home.packages = [
    (pkgs.t3code.override {
      enableClaude = true;
      enableCodex = true;
    })
  ];
}
