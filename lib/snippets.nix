pkgs: mylib:
let

  inherit (builtins) split filter isString concatStringsSep;
  inherit (mylib) get-toplevel get-boot-essential;

  inherit (import ./beon-bnoe.nix)
    get-var-by-env-or-nix
    get-var-by-nix-or-env
    get-var;

in
rec
{

  partition-format =
    { disk, forced, root-label ? "root", boot-label ? "BOOT" }:
    ''
      ### partition-format ###
      ### https://nixos.org/manual/nixos/stable/index.html#sec-installation-manual-partitioning

      if [ ! -e /dev/disk/by-label/root ] || [ ${forced} == 'true' ]
        then # NOTE: improve conditional?

        # create a GPT partition table
        ${pkgs.parted}/bin/parted -s "${disk}" -- mklabel gpt

        # add a boot partition and format
        ${pkgs.parted}/bin/parted -s "${disk}" -- mkpart ESP fat32 1MB 512MB
        ${pkgs.parted}/bin/parted -s "${disk}" -- set 1 esp on
        ${pkgs.dosfstools}/bin/mkfs.fat -F 32 -n ${boot-label} "${disk}p1"

        # add the other partition
        ${pkgs.parted}/bin/parted -s "${disk}" -- mkpart primary 512MB -0GB

        # encrypt the other partition
        echo "solutionmaster" | ${pkgs.cryptsetup}/bin/cryptsetup -q luksFormat "${disk}p2" --label=root_crypt
        echo "solutionmaster" | ${pkgs.cryptsetup}/bin/cryptsetup open "${disk}p2" enc

        # create LVM
        pvcreate /dev/mapper/enc
        vgcreate lvm /dev/mapper/enc

        # create swap and format
        # lvcreate -i 4 --size 8G --name swap lvm
        lvcreate --size 8G --name swap lvm
        mkswap /dev/lvm/swap -L swap
        swapon /dev/lvm/swap

        # create root and format in btrfs
        # lvcreate -i 4 --extents 100%FREE --name ${root-label} lvm
        lvcreate --extents 100%FREE --name ${root-label} lvm
        ${pkgs.btrfs-progs}/bin/mkfs.btrfs /dev/lvm/root -L ${root-label}

      fi

      ########################################
    '';

  create-btrfs-subvolumes = { root-label ? "root", mount-point ? "/mnt" }:
    ''
      ### create subvolumes ###

      mount -t btrfs -L ${root-label} ${mount-point}

      btrfs subvolume create ${mount-point}/root
      btrfs subvolume create ${mount-point}/home
      btrfs subvolume create ${mount-point}/nix
      btrfs subvolume create ${mount-point}/persist
      btrfs subvolume create ${mount-point}/log

      # take an empty *readonly* snapshot of the root subvolume,
      # which we'll eventually rollback to on every boot.
      btrfs subvolume snapshot -r ${mount-point}/root ${mount-point}/root-blank

      umount ${mount-point}
    '';

  mount-btrfs-subvolumes = { root-label ? "root", boot-label ? "BOOT", mount-point ? "/mnt" }:
    ''
      ### Mount the directories ###

      mount -o subvol=root,compress=zstd,noatime -L ${root-label} ${mount-point}

      mkdir ${mount-point}/home
      mount -o subvol=home,compress=zstd,noatime -L ${root-label} ${mount-point}/home

      mkdir ${mount-point}/nix
      mount -o subvol=nix,compress=zstd,noatime -L ${root-label} ${mount-point}/nix

      mkdir ${mount-point}/persist
      mount -o subvol=persist,compress=zstd,noatime -L ${root-label} ${mount-point}/persist

      mkdir -p ${mount-point}/var/log
      mount -o subvol=log,compress=zstd,noatime -L ${root-label} ${mount-point}/var/log

      mkdir -p ${mount-point}/boot
      mount -L ${boot-label} ${mount-point}/boot

    '';


  # btrfs2 is just btrfs that uses @ symbol for subvolumes
  create-btrfs2-subvolumes = { root-label ? "root", mount-point ? "/mnt" }:
    ''
      ### create subvolumes ###

      mount -t btrfs -L ${root-label} ${mount-point}

      for sv in "" home nix persist log; do
        btrfs subvolume create ${mount-point}/@$sv
      done

      # take an empty *readonly* snapshot of the root subvolume,
      # which we'll eventually rollback to on every boot.
      btrfs subvolume snapshot -r ${mount-point} ${mount-point}/root-blank

      umount ${mount-point}
    '';


  # btrfs2 is just btrfs that uses @ symbol for subvolumes
  mount-btrfs2-subvolumes = { root-label ? "root", boot-label ? "BOOT", mount-point ? "/mnt" }:
    ''
      ### Mount the subvolumes ###

      for sv in "" home nix persist; do
        mount -m -L ${root-label} -o subvol=@$sv,compress=zstd,noatime ${mount-point}/$sv
      done
      mount -m -L ${root-label} -o subvol=@log,compress=zstd,noatime ${mount-point}/var/log
      mount -m -L ${boot-label} ${mount-point}/boot

    '';


  mount-new-root = { root-label ? "root", boot-label ? "BOOT", mount-point ? "/mnt" }:
    ''
      ### mount-new-root ###

      umask 0022

      echo "mounting ${mount-point}"
      sudo ${pkgs.coreutils}/bin/mkdir -p "${mount-point}"
      sudo ${pkgs.util-linux}/bin/mount -L ${root-label} "${mount-point}"

      echo "mounting ${mount-point}/boot"
      sudo ${pkgs.coreutils}/bin/mkdir -p "${mount-point}/boot"
      sudo ${pkgs.util-linux}/bin/mount -L ${boot-label} "${mount-point}/boot"

      ######################################
    '';


  mk-wg-key = { path ? "mk-wg-key" }:
    ''
      ${get-var-by-env-or-nix { name = "path"; env-var = "MYSYSTEM_PATH"; nix-var = path; }}

      umask 077
      mkdir -p $path
      wg genkey > "$path"/private
      wg pubkey < "$path"/private > "$path"/public
      cat "$path"/public
    '';

  rekey-wg-key = { label ? "" }:
    ''
      ${get-var-by-env-or-nix { name = "label"; env-var = "MYSYSTEM_LABEL"; nix-var = label; }}
      cd $PWD/secrets
      EDITOR=: agenix -e wg-${label}.age
      cd ..
    '';


  mk-ssh-key = { path ? "mk-ssh-key", label ? "" }:
    ''
      ${get-var-by-env-or-nix { name = "path"; env-var = "MYSYSTEM_PATH"; nix-var = path; }}
      ${get-var-by-env-or-nix { name = "label"; env-var = "MYSYSTEM_LABEL"; nix-var = label; }}

      echo path=$path
      mkdir -p $path
      ssh-keygen -t ed25519 -C "$label" -f "''${path}"/ssh_host_ed25519_key -P ""

      echo ""
      echo "ssh public key :"
      cat ${path}/ssh_host_ed25519_key.pub
    '';


  # FIXME: error I've got
  #  cat ../$file | EDITOR=: agenix -e wg-''${label}.age
  #  wg-toledo.age wasn't created.
  mk-age-file = { file ? "", label ? ""}:
    ''
      ${get-var-by-env-or-nix { name = "file"; env-var = "MYSYSTEM_FILE"; nix-var = file; }}
      ${get-var-by-env-or-nix { name = "label"; env-var = "MYSYSTEM_LABEL"; nix-var = label; }}

      pushd $PWD/secrets
      cat ../$file
      cat ../$file | EDITOR=: agenix -e wg-''${label}.age
      popd
    '';


  switch-after-enter = { system-toplevel, mount-point ? "/mnt", switch-command ? "switch" }:
    ''
      ### switch-after-enter ###

      echo "Setting the profile"

      export PATH=$PATH:"${system-toplevel}/sw/bin"

      sudo nix-env --store "${mount-point}" \
                   -p "${mount-point}/nix/var/nix/profiles/system" \
                   --set "${system-toplevel}"

      sudo mkdir -m 0755 -p "${mount-point}/etc"
      sudo touch "${mount-point}/etc/NIXOS"

      sudo ln -sfn /proc/mounts "${mount-point}/etc/mtab"

      NIXOS_INSTALL_BOOTLOADER=1 \
      sudo nixos-enter \
        --root "${mount-point}" \
        -- \
        /run/current-system/bin/switch-to-configuration ${switch-command}

      sync
      echo "switch-after-enter is done"

      #########################################
    '';

  kexec-after-chroot = { nixosConfiguration, mount-point ? "/mnt" }:
    let
      boot-essential = get-boot-essential nixosConfiguration;
      inherit (boot-essential) kernel initrd cmdLine;
      toplevel= get-toplevel nixosConfiguration;
   in
   ''
      ### kexec-after-chroot ###

      ${pkgs.coreutils}/bin/mkdir -p "${mount-point}/run"
      ln -sfn ${toplevel} "${mount-point}/run/current-system"

      mkdir -p ${mount-point}/proc ${mount-point}/sys ${mount-point}/dev
      ${pkgs.util-linux}/bin/mount --bind /proc "${mount-point}/proc"
      ${pkgs.util-linux}/bin/mount --bind /sys "${mount-point}/sys"
      ${pkgs.util-linux}/bin/mount --bind /dev "${mount-point}/dev"

      ${pkgs.sudo}/bin/sudo chroot "${mount-point}" <<-EOF_CHROOT
        kexec --load ${kernel} --initrd=${initrd} --command-line "${cmdLine}"
        kexec -e
      EOF_CHROOT

      echo "kexec-after-chroot is done."

      #############################################
   '';

  execute-after-chroot = { system-toplevel, mount-point ? "/mnt" }: script:
   ''
      ### execute-after-chroot ###

      ${pkgs.coreutils}/bin/mkdir -p "${mount-point}/run"
      ln -sfn ${system-toplevel} "${mount-point}/run/current-system"

      mkdir -p ${mount-point}/proc ${mount-point}/sys ${mount-point}/dev
      ${pkgs.util-linux}/bin/mount --bind /proc "${mount-point}/proc"
      ${pkgs.util-linux}/bin/mount --bind /sys "${mount-point}/sys"
      ${pkgs.util-linux}/bin/mount --bind /dev "${mount-point}/dev"

      ${pkgs.sudo}/bin/sudo chroot "${mount-point}" <<-EOF_CHROOT
        ${script}
      EOF_CHROOT

      echo "kexec-after-chroot is done."

      #############################################
   '';

  copy-to-remote =
    { host
    , user ? "root"
    , private-key ? null
    , remote-store ? null
    , references
    }:
    let
      store-uri = let
        queries = concatStringsSep "" [
          (if private-key != null then "?ssh-key=${private-key}" else "")
          (if remote-store != null then "?remote-store=${remote-store}" else "")
        ];
      in "ssh://${user}@${host}${queries}";
    in
    ''
      ${pkgs.nixFlakes}/bin/nix copy "${references}" --to "${store-uri}"
    '';

  remote-nixos-install =
    { host
    , user ? "root"
    , private-key ? null
    , remote-store ? "/mnt"
    , system-toplevel
    }:
    remote-execution-over-ssh { inherit host user private-key remote-store;} ''
      ${pkgs.nixos-install}/bin/nixos-install \
          --root "${remote-store}" \
          --system "${system-toplevel}" \
          --no-root-passwd
    '';


  # `remote-execution-over-ssh` makes sure that whenever a script is executed
  # over ssh, all the contexts are present on remote side.
  remote-execution-over-ssh =
    { host
    , user ? "root"
    , private-key ? null
    , remote-store ? null
    , extraArgs ? []
    , trace ? true
    }:
    script:
    let

      references = pkgs.writeStringReferencesToFile script;

      indent = "\t";

      script' = let
        lines = (if trace then [ "set -x\n" ] else []) ++ (filter isString (split "\n" script));
      in concatStringsSep "\n${indent}" lines;

      extraArgs' = [ "-o StrictHostKeyChecking=no"
                     "-o UserKnownHostsFile=/dev/null"
                     "-o \"ServerAliveInterval 2\""
                   ] ++ (if private-key != null then [ "-i ${private-key}" ] else []) ++
                   extraArgs;

      store-uri = let
        queries = concatStringsSep "" [
          (if private-key != null then "?ssh-key=${private-key}" else "")
          (if remote-store != null then "?remote-store=${remote-store}" else "")
        ];
      in "ssh://${user}@${host}${queries}";

    in ''
        ### remote-execution-over-ssh ###

        ${pkgs.nixFlakes}/bin/nix copy "${references}" --to "${store-uri}"

        ${pkgs.openssh}/bin/ssh ${user}@${host} -T ${toString extraArgs'} <<EOF
        ${indent}${script'}
        EOF

        #################################
      '';


}
