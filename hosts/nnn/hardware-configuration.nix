# PLACEHOLDER — replace this file with the one generated on your machine:
#
#   sudo nixos-generate-config --show-hardware-config > hosts/nnn/hardware-configuration.nix
#
# It declares your disks, filesystems, kernel modules and CPU microcode. The
# stub below only exists so the flake evaluates before you have real hardware
# config; it will NOT boot a real machine as-is.
{lib, ...}: {
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "sd_mod"
  ];
  boot.kernelModules = ["kvm-intel"];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
