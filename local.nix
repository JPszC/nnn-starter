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

  # Samsung ViewFinity S32D70 — 32" 3840×2160 @ 60 Hz on the RTX HDMI port.
  # Scale 1.5 makes this 139 PPI panel a logical 2560×1440 (~96 DPI).
  # `name` is the make/model/serial from `niri msg outputs`.
  # `renderDevice` is the DRM node of the GPU that owns that HDMI port
  # (`/dev/dri/by-path/`); niri must render there or every frame is copied
  # across from the Intel iGPU and animations stutter.
  monitor = {
    name = "Samsung Electric Company LS32D70xE HCNXB01643";
    scale = 1.5;
    width = 3840;
    height = 2160;
    refresh = 60.000;
    renderDevice = "/dev/dri/by-path/pci-0000:01:00.0-render";
  };

  # Pangolin CLI machine client (modules/nixos/pangolin.nix).
  # Credentials are NOT here — they live in secrets/pangolin.env.age (agenix).
  # Set enable = true only after that file exists and secrets.nix has your
  # host SSH pubkey.
  pangolin.enable = true;
}
