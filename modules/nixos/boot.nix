{
  inputs,
  pkgs,
  ...
}: {
  # BORE scheduler + ThinLTO, optimized for CPUs supporting x86-64-v3.
  boot.kernelPackages =
    inputs.nix-cachyos-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system}.linuxPackages-cachyos-bore-lto-x86_64-v3;

  # systemd-boot on UEFI. If you boot legacy BIOS, swap this for GRUB.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  # Quiet, graphical boot to match the omarchy-style polish.
  boot.plymouth.enable = true;
  boot.kernelParams = ["quiet"];
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
}
