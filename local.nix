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
  gitSigningKey = "642406F6C6F65A79!";

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

  # NetBird client (modules/nixos/netbird.nix).
  # The setup key is NOT here — it lives in secrets/netbird-setup-key.age (agenix).
  # Set enable = true only after that file exists and secrets.nix has your
  # host SSH pubkey. For self-hosted NetBird also add:
  #   managementUrl = "https://netbird.example.com:443";
  netbird.enable = true;

  # Send public traffic through tun2proxy (modules/nixos/tun2proxy.nix).
  # The proxy URL is NOT here — one line in secrets/tun2proxy-proxy.age:
  #   socks5://user:pass@host:port
  # git add that file (Nix only sees tracked files). Private ranges and
  # NetBird stay off the tunnel. Optional extra CIDRs that stay direct:
  #   extraBypass = [ "203.0.113.10/32" ];
  # tun stop | tun start | tun restart
  # stop tears the tunnel down immediately and points DNS back at the LAN.
  tun2proxy.enable = true;
}
