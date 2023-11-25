pkgs:
let

  inherit (pkgs.lib)
    makeExtensible
    splitString
    elemAt
    composeManyExtensions
  ;

  mylib = makeExtensible (self: let
      callLibs = file: import file pkgs self;
    in {

      inherit (pkgs) writeShellApplication writeStringReferencesToFile writeScriptBin;
      get-toplevel = nixos: nixos.config.system.build.toplevel;
      get-isoimage = nixos: nixos.config.system.build.isoImage;
      lsblk = "${pkgs.util-linux}/bin/lsblk";
      mount = "${pkgs.util-linux}/bin/mount";
      umount = "${pkgs.util-linux}/bin/umount";
      blkdiscard = "${pkgs.util-linux}/bin/blkdiscard";
      swapon = "${pkgs.util-linux}/bin/swapon";
      partx = "${pkgs.util-linux}/bin/partx";
      mlabel = "${pkgs.mtools}/bin/mlabel";
      mkswap = "${pkgs.util-linux}/bin/mkswap";
      jq = "${pkgs.jq}/bin/jq";
      cat = "${pkgs.coreutils}/bin/cat";
      echo = "${pkgs.coreutils}/bin/echo";
      touch = "${pkgs.coreutils}/bin/touch";
      mkdir = "${pkgs.coreutils}/bin/mkdir";
      ln = "${pkgs.coreutils}/bin/ln";
      sync = "${pkgs.coreutils}/bin/sync";
      cp = "${pkgs.coreutils}/bin/cp";
      chmod = "${pkgs.coreutils}/bin/chmod";
      truncate = "${pkgs.coreutils}/bin/truncate";
      rm = "${pkgs.coreutils}/bin/rm";
      parted = "${pkgs.parted}/bin/parted";
      partprobe = "${pkgs.parted}/bin/partprobe";
      mkfs.fat = "${pkgs.dosfstools}/bin/mkfs.fat";
      mkfs.btrfs = "${pkgs.btrfs-progs}/bin/mkfs.btrfs";
      btrfs = "${pkgs.btrfs-progs}/bin/btrfs";
      cryptsetup = "${pkgs.cryptsetup}/bin/cryptsetup";
      nix = "${pkgs.nixFlakes}/bin/nix";
      nix-env = "${pkgs.nixFlakes}/bin/nix-env";
      nixos-enter = "${pkgs.nixos-install-tools}/bin/nixos-enter";
      nixos-install = "${pkgs.nixos-install-tools}/bin/nixos-install";
      ssh = "${pkgs.openssh}/bin/ssh";
      ssh-keygen = "${pkgs.openssh}/bin/ssh-keygen";
      ssh-copy-id = "${pkgs.openssh}/bin/ssh-copy-id";
      chattr = "${pkgs.e2fsprogs}/bin/chattr";

      wg = "${pkgs.wireguard-tools}/bin/wg";
      agenix = "${pkgs.agenix}/bin/agenix";

      remote-execution-over-ssh = import ./remote-execution-over-ssh.nix { inherit pkgs; };

      get-boot-essential = nixosConfiguration:
        let inherit (nixosConfiguration.config.system) build;
        in {
          kernel = "${build.toplevel}/kernel";
          initrd = "${build.netbootRamdisk or build.toplevel}/initrd";
          cmdLine = "init=${build.toplevel}/init";
        };

      snippets = callLibs ./snippets.nix;

      get-user-hostname = str: let
        list = splitString "@" str;
      in {
        user = elemAt list 0;
        hostname = elemAt list 1;
      };

    });

in mylib.extend (
    composeManyExtensions [
      (import ./remote-install/snippets.nix)
    ])
