{
  # SeaBIOS boots legacy BIOS, so GRUB needs a 1M BIOS-boot partition on GPT.
  # disko sets boot.loader.grub.devices from the EF02 partition.
  # Check the disk name from the installer ISO with `lsblk` (virtio is usually vda).
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/vda";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02";
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
