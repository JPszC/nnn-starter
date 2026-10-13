{
  local,
  lib,
  pkgs,
  ...
}: {
  # OpenPGP signing for commits and tags. Keys stay in ~/.gnupg (mutable);
  # generate one with `gpg --full-generate-key` using gitUserEmail.
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    # pinentry-qt is Qt 6 + Qt Wayland, same toolkit as Noctalia, and Stylix
    # themes Qt. The package's default program is the `pinentry` dispatcher,
    # which only auto-picks Qt under KDE and otherwise falls back to curses.
    pinentry.package = pkgs.pinentry-qt;
    pinentry.program = "pinentry-qt";
    # Wayland cannot do an X11-style keyboard grab; leaving it on keeps the
    # prompt from appearing.
    grabKeyboardAndMouse = false;
  };

  # The agent reads pinentry-program once, at start. Switching only rewrites
  # gpg-agent.conf, so the already running agent keeps calling the old binary.
  home.activation.reloadGpgAgent = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${lib.getExe' pkgs.gnupg "gpgconf"} --kill gpg-agent || true
  '';

  programs.git = {
    enable = true;

    signing = {
      format = "openpgp";
      key = local.gitSigningKey;
      signByDefault = true;
    };

    settings = {
      # ⇩ Identity comes from local.nix.
      user.name = local.gitUserName;
      user.email = local.gitUserEmail;

      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      merge.conflictstyle = "zdiff3";
      diff.colorMoved = "default";

      alias = {
        st = "status -sb";
        co = "checkout";
        br = "branch";
        ci = "commit";
        lg = "log --oneline --graph --decorate --all";
      };
    };
  };

  # delta gives syntax-highlighted, side-by-side diffs (themed by Stylix).
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = true;
    };
  };

  programs.lazygit.enable = true;

  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };
}
