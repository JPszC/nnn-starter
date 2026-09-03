# Personal, machine-local settings.
#
# This file is tracked by git with neutral placeholder defaults, but is marked
# "skip-worktree" so your edits here are never staged or committed:
#
#     git update-index --skip-worktree local.nix     # hide local changes
#     git update-index --no-skip-worktree local.nix  # un-hide (e.g. to edit defaults)
#
# Put your real identity below; it flows into flake.nix and the modules.
{
  # Login user and machine identity.
  username = "jpszc";
  hostName = "iapetus";
  fullName = "JPszC"; # shown as the user account description

  # Locale / location.
  timeZone = "America/Caracas";

  # Git identity (modules/home/git.nix).
  gitUserName = "Jaime Pereira";
  gitUserEmail = "JPszC@pm.me";

  # Primary display scale (modules/home/niri.nix, output eDP-1).
  monitorScale = 1.0;
}
