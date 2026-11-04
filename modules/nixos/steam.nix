{pkgs, ...}: {
  # Steam (unfree; allowUnfree is set in flake.nix). The NixOS module sets up
  # the FHS runtime, 32-bit graphics libs, and udev rules for controllers.
  programs.steam = {
    enable = true;
    # Proton-GE for games that need a newer/patched Proton than Valve ships.
    # Select it per-game under Properties → Compatibility.
    extraCompatPackages = [pkgs.proton-ge-bin];
    # Open ports for Remote Play / local network game transfers.
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # Feral GameMode: use `gamemoderun %command%` in Steam launch options.
  programs.gamemode.enable = true;
}
