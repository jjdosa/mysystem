# This is the same as ./btrfs.nix but it uses @ symbol for the subvolumes
{ lib, ... }: with lib;
let
  wipeBtrfsRoot = ''
    mkdir -p /btrfs
    mount -o subvol=/ /dev/disk/by-label/root /btrfs

    if [ -e "/btrfs/root/dontwipe" ]; then
      echo "Not wiping root"
    else
      echo "Cleaning subvolume"
      btrfs subvolume list -o /btrfs/root | cut -f9 -d ' ' |
      while read subvolume; do
        btrfs subvolume delete "/btrfs/$subvolume"
      done && btrfs subvolume delete /btrfs/root

      echo "Restoring blank subvolume"
      btrfs subvolume snapshot /btrfs/root-blank /btrfs/root
    fi

    umount /btrfs
    rmdir /btrfs
  '';
in
{

  boot.initrd = {
    supportedFilesystems = [ "btrfs" ];
    # luks.devices =
    #   let
    #     nameValuePair-l = imap (i: dev: nameValuePair "enc${toString i}" { device = dev;} ) devices;
    #   in listToAttrs nameValuePair-l;
    # luks.reusePassphrases = true;
  };
  # boot.initrd.postDeviceCommands = lib.mkBefore wipeBtrfsRoot;

  fileSystems."/" =
    { device = "/dev/disk/by-label/root";
      fsType = "btrfs";
      options = [ "subvol=@" "compress=zstd" "noatime" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-label/root";
      fsType = "btrfs";
      options = [ "subvol=@home" "compress=zstd" "noatime" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-label/root";
      fsType = "btrfs";
      options = [ "subvol=@nix" "compress=zstd" "noatime" ];
    };

  fileSystems."/persist" =
    { device = "/dev/disk/by-label/root";
      fsType = "btrfs";
      options = [ "subvol=@persist" "compress=zstd" "noatime" ];
      neededForBoot = true;
    };

  fileSystems."/var/log" =
    { device = "/dev/disk/by-label/root";
      fsType = "btrfs";
      options = [ "subvol=@log" "compress=zstd" "noatime" ];
      neededForBoot = true;
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
    };

  fileSystems."/swap" =
    { device = "/dev/disk/by-label/root";
      fsType = "btrfs";
      options = [ "subvol=@swap" "noatime" ];
    };

  swapDevices = [ { device = "/swap/swapfile"; } ];

  # services.btrfs.autoScrub.enable = true;
}
