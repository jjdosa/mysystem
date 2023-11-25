final: prev: with final;
let

  inherit (builtins) split filter isString concatStringsSep;

in
{

  partition-format-encrypt-all-ssd = { root-label, boot-label, force }:
    ''
      ### partition-format ###
      ### https://nixos.org/manual/nixos/stable/index.html#sec-installation-manual-partitioning
      # NOTE: improve conditional?
      if [ -e /dev/disk/by-label/root ]; then
          ${echo} "Unclean device:"
          ${echo} /dev/disk/by-label/root
          if [ ${force} == 'false' ]; then
            ${echo} "Exiting"
            exit 1
          fi
      fi
      checkdevs=($(${lsblk} --path --json \
                  | ${jq} -r \
                     '.blockdevices[]
                     | select((all(.mountpoints[];
                       contains("nix")? or contains("iso")? | not)
                       and (all(.children[]? | .mountpoints[];
                       contains("nix")? or contains("iso")? | not))))
                     | select(has("children") or .mountpoints != [null])
                     | .name' | sort))
      if [ ''${#checkdevs[@]} -gt 0 ]; then
        ${echo} "Unclean devices:"
        for i in ''${!checkdevs[@]}; do
          ${echo} ''${checkdevs[$i]}
        done
        if [ ${force} == 'false' ]; then
          ${echo} "Exiting"
          exit 1
        fi
      fi

      if [ ${force} == 'true' ]; then
        ${echo} "Force format"
        for i in ''${!checkdevs[@]}; do
          ${echo} "Formatting Device Start"
          ${echo} "Formatting Device :"
          ${echo} "''${checkdevs[$i]}"
          ${blkdiscard} -f ''${checkdevs[$i]}
          ${echo} "Formatting Device End"
        done
      fi

      devs=($(${lsblk} --path --json \
             | ${jq} -r \
                '.blockdevices[]
                | select((all(.mountpoints[];
                  contains("nix")? or contains("iso")? | not)
                  and (all(.children[]? | .mountpoints[];
                  contains("nix")? or contains("iso")? | not))))
                | .name' | sort))

      ${echo} "Number of devices: ''${#devs[@]}"

      ${echo} "First device: ''${devs[0]}"

      # create a GPT partition table
      ${parted} -s ''${devs[0]} mklabel gpt

      # add the btrfs partition
      ${parted} -s ''${devs[0]} mkpart btrfs-nvme0 btrfs 512MiB 100%
      ${echo} "solutionmaster" | ${cryptsetup} -q luksFormat ''${devs[0]}p1 --label=root_crypt
      ${echo} "solutionmaster" | ${cryptsetup} open ''${devs[0]}p1 enc0

      # add a boot partition and format
      ${parted} -s ''${devs[0]} mkpart ESP fat32 1MiB 512MiB

      ${parted} -s ''${devs[0]} set 2 esp on

      ${mkfs.fat} -F 32 -n ${boot-label} ''${devs[0]}p2

      # more than 1 device
      devstail=( ''${devs[@]:1} )

      if [ ''${#devstail[@]} -gt 0 ]; then
        for i in ''${!devstail[@]}; do
          ${echo} "Next Device: ''${devstail[$i]}"
          ${parted} -s ''${devstail[$i]} mklabel gpt
          ${parted} -s ''${devstail[$i]} mkpart btrfs-nvme$((i+1)) btrfs 4MiB 100%
          ${echo} "solutionmaster" | ${cryptsetup} -q luksFormat ''${devstail[$i]}p1 --label=root_crypt
          ${echo} "solutionmaster" | ${cryptsetup} open ''${devstail[$i]}p1 enc$((i+1))
        done
      fi
      for i in ''${!devs[@]}; do
        devs_index[$i]=/dev/mapper/enc$i
      done

      ${echo} "Devices for btrfs:"
      ${echo} ''${devs_index[*]}

      if [ ''${#devs_index[@]} -gt 1 ]; then
        ${mkfs.btrfs} -d single -m raid1 -L ${root-label} ''${devs_index[*]}
        ${echo} "Partition format done for ''${devs_index[*]}"
      else
        ${mkfs.btrfs} -d single -m single -L ${root-label} ''${devs_index[*]}
        ${echo} "Partition format done for ''${devs_index[*]}"
      fi

      ${echo} ""
      ${echo} "Put the names of the machine ssd devices into \`devices\` inside \`user-info.nix\`."
      ${echo} ""
      ${echo} "Device names :"
      ${echo} ''${devs[*]}
      ${echo} ""
      ########################################
    '';

  remote-partition-format-encrypt-all-ssd = { root-label, boot-label, force, host, ftn-name ? null }:
    remote-execution-over-ssh { inherit host ftn-name; } ''
      ${partition-format-encrypt-all-ssd { inherit root-label boot-label force; }}
    '';


  partition-format-all-ssd = { root-label, boot-label, force }:
    ''
      ### partition-format ###
      ### https://nixos.org/manual/nixos/stable/index.html#sec-installation-manual-partitioning
      # NOTE: improve conditional?
      if [ -e /dev/disk/by-label/root ]; then
          ${echo} "Unclean device:"
          ${echo} /dev/disk/by-label/root
          if [ ${force} == 'false' ]; then
            ${echo} "Exiting"
            exit 1
          fi
      fi
      checkdevs=($(${lsblk} --path --json \
                  | ${jq} -r \
                     '.blockdevices[]
                     | select((all(.mountpoints[];
                       contains("nix")? or contains("iso")? | not)
                       and (all(.children[]? | .mountpoints[];
                       contains("nix")? or contains("iso")? | not))))
                     | select(has("children") or .mountpoints != [null])
                     | .name' | sort))
      if [ ''${#checkdevs[@]} -gt 0 ]; then
        ${echo} "Unclean devices:"
        for i in ''${!checkdevs[@]}; do
          ${echo} ''${checkdevs[$i]}
        done
        if [ ${force} == 'false' ]; then
          ${echo} "Exiting"
          exit 1
        fi
      fi

      if [ ${force} == 'true' ]; then
        ${echo} "Force format"
        for i in ''${!checkdevs[@]}; do
          ${echo} "Formatting Device Start"
          ${echo} "Formatting Device :"
          ${echo} "''${checkdevs[$i]}"
          ${blkdiscard} -f ''${checkdevs[$i]}
          ${echo} "Formatting Device End"
        done
      fi

      devs=($(${lsblk} --path --json \
             | ${jq} -r \
                '.blockdevices[]
                | select((all(.mountpoints[];
                  contains("nix")? or contains("iso")? | not)
                  and (all(.children[]? | .mountpoints[];
                  contains("nix")? or contains("iso")? | not))))
                | .name' | sort))

      ${echo} "Number of devices: ''${#devs[@]}"

      ${echo} "First device: ''${devs[0]}"

      # create a GPT partition table
      ${parted} -s ''${devs[0]} mklabel gpt

      # add the btrfs partition
      ${parted} -s ''${devs[0]} mkpart btrfs-nvme0 btrfs 512MiB 100%

      # add a boot partition and format
      ${parted} -s ''${devs[0]} mkpart ESP fat32 1MiB 512MiB

      ${parted} -s ''${devs[0]} set 2 esp on

      ${mkfs.fat} -F 32 -n ${boot-label} ''${devs[0]}p2
      ${mlabel} ::"${boot-label}" -i ''${devs[0]}p2

      # more than 1 device
      devstail=( ''${devs[@]:1} )

      if [ ''${#devstail[@]} -gt 0 ]; then
        for i in ''${!devstail[@]}; do
          ${echo} "Next Device: ''${devstail[$i]}"
          ${parted} -s ''${devstail[$i]} mklabel gpt
          ${parted} -s ''${devstail[$i]} mkpart btrfs-nvme$((i+1)) btrfs 4MiB 100%
        done
      fi

      for i in ''${!devs[@]}; do
        devs_index[$i]=''${devs[$i]}p1
      done

      ${echo} "Devices for btrfs:"
      ${echo} ''${devs_index[*]}

      if [ ''${#devs[@]} -gt 1 ]; then
        ${mkfs.btrfs} -f -d single -m raid1 -L ${root-label} ''${devs_index[*]}
        ${echo} "Partition format done for ''${devs_index[*]}"
      else
        ${mkfs.btrfs} -f -d single -m single -L ${root-label} ''${devs_index[*]}
        ${echo} "Partition format done for ''${devs_index[*]}"
      fi

      ${echo} ""
      ${echo} "Put the names of the machine ssd devices into \`devices\` inside \`user-info.nix\`."
      ${echo} ""
      ${echo} "Device names :"
      ${echo} ''${devs[*]}
      ${echo} ""
      ########################################
    '';

  remote-partition-format-all-ssd = { root-label, boot-label, force, host, ftn-name ? null }:
    remote-execution-over-ssh { inherit host ftn-name; } ''
      ${partition-format-all-ssd { inherit root-label boot-label force; }}
    '';


  decrypt-all-ssd = { root-label, boot-label, force }:
    ''
      devs=($(${lsblk} --path --json -x NAME \
             | ${jq} -r \
                '.blockdevices[]
                | select((all(.mountpoints[];
                  contains("nix")? or contains("iso")? | not)
                  and (all(.children[]? | .mountpoints[];
                  contains("nix")? or contains("iso")? | not))))
                | .name' | sort))

      ${echo} "Number of devices: ''${#devs[@]}"

      for i in ''${!devs[@]}; do
        ${echo} "solutionmaster" | ${cryptsetup} open ''${devs[$i]}p1 enc$((i))
      done
    '';

  remote-decrypt-all-ssd = { root-label, boot-label, force, host, ftn-name ? null }:
    remote-execution-over-ssh { inherit host ftn-name; } ''
      ${decrypt-all-ssd { inherit root-label boot-label force; }}
    '';

  create-btrfs-subvolumes = { root-label, mount-point }:
    ''
      ### create subvolumes ###

      ${mount} -t btrfs -L ${root-label} ${mount-point}

      for sv in "" home nix persist log; do
        ${btrfs} subvolume create ${mount-point}/@$sv
      done

      # take an empty *readonly* snapshot of the root subvolume,
      # which we'll eventually rollback to on every boot.
      ${btrfs} subvolume snapshot -r ${mount-point} ${mount-point}/root-blank

      ${umount} ${mount-point}
    '';

  remote-create-btrfs-subvolumes = { root-label, mount-point, host, ftn-name ? null }:
    remote-execution-over-ssh { inherit host ftn-name; } ''
      ${create-btrfs-subvolumes { inherit root-label mount-point; }}
    '';

  create-btrfs-swap = { root-label, mount-point }:
    ''
      ### create subvolumes ###

      ${mount} -t btrfs -L ${root-label} ${mount-point}

      ${btrfs} subvolume create ${mount-point}/@swap

      ${umount} ${mount-point}
    '';

  remote-create-btrfs-swap = { root-label, mount-point, host, ftn-name ? null }:
    remote-execution-over-ssh { inherit host ftn-name; } ''
      ${create-btrfs-swap { inherit root-label mount-point; }}
    '';

  mount-btrfs-subvolumes = { root-label, boot-label, mount-point }:
    ''
      ### Mount the subvolumes ###

      for sv in "" home nix persist; do
        ${mount} -m -L ${root-label} -o subvol=@$sv,compress=zstd,noatime ${mount-point}/$sv
      done
      ${mount} -m -L ${root-label} -o subvol=@log,compress=zstd,noatime ${mount-point}/var/log
      ${mount} -m -L ${boot-label} ${mount-point}/boot

    '';

  remote-mount-btrfs-subvolumes = { root-label, boot-label, mount-point, host, ftn-name ? null }:
    remote-execution-over-ssh { inherit host ftn-name; } ''
      ${mount-btrfs-subvolumes { inherit root-label boot-label mount-point; }}
    '';
  # https://github.com/NixOS/nixpkgs/issues/156829#issuecomment-1034159729
  mount-btrfs-swap = { root-label, boot-label, mount-point }:
    ''
      ${mount} -m -L ${root-label} -o subvol=@swap,noatime ${mount-point}/swap

      ${btrfs} filesystem mkswapfile --size 16g --uuid clear ${mount-point}/swap/swapfile
      ${swapon} ${mount-point}/swap/swapfile
    '';
      # ${truncate} -s 0 ${mount-point}/swap/swapfile
      # ${chattr} +C ${mount-point}/swap/swapfile
      # ${btrfs} property set ${mount-point}/swap/swapfile compression none
      # ${dd} if=/dev/zero of=${mount-point}/swap/swapfile bs=1M count=8192 status=progress
      # ${chmod} 0600 ${mount-point}/swap/swapfile
      # ${mkswap} ${mount-point}/swap/swapfile


  remote-mount-btrfs-swap = { root-label, boot-label, mount-point, host, ftn-name ? null }:
    remote-execution-over-ssh { inherit host ftn-name; } ''
      ${mount-btrfs-swap { inherit root-label boot-label mount-point; }}
    '';


  set-wg-key = { machine }:
    ''
      umask 077
      ${wg} genkey > $PWD/private
      ${wg} pubkey < $PWD/private > $PWD/public
      cd $PWD/secrets
      ${cat} ../private | ${agenix} -e ${machine}-wg-key.age
      cd ..
      ${echo} ""
      ${echo} "Put the WireGuard public key into the comment above \`${machine}-wg-key.age\` inside \`secrets/secrets.nix\`."
      ${echo} ""
      ${echo} "WireGuard public key :"
      ${cat} $PWD/public
      ${rm} $PWD/private
    '';

  rekey-wg-key = { machine }:
    ''
      cd $PWD/secrets
      EDITOR=: ${agenix} -e ${machine}-wg-key.age
      cd ..
    '';

  set-peerix =
    ''
      umask 077
      ${wg} genkey > $PWD/private
      ${wg} pubkey < $PWD/private > $PWD/public
      cd $PWD/secrets && ${cat} ../private | ${agenix} -e peerix.age && cd ..
      ${echo} "wireguard public key :"
      ${cat} $PWD/public
      ${rm} $PWD/private
    '';

  rekey-peerix =
    ''
      cd $PWD/secrets
      ${cat} ../private | EDITOR=: ${agenix} -e peerix.age
      cd ..
    '';

  set-ssh-key = { mount-point, machine }:
    ''
      ${mkdir} -p ${mount-point}/etc/ssh
      ${rm} -rf ${mount-point}/etc/ssh/ssh_host_ed25519_key
      ${ssh-keygen} -t ed25519 -C "root@${machine}" -f ${mount-point}/etc/ssh/ssh_host_ed25519_key -P ""
      ${echo} ""
      ${echo} "Put the machine ssh public key into \`machines.${machine}.ssh-key\` inside \`user-info.nix\`."
      ${echo} ""
      ${echo} "machine ssh public key :"
      ${cat} ${mount-point}/etc/ssh/ssh_host_ed25519_key.pub
      ${echo} ""
      ${echo} "If WireGuard key is set for the first time,"
      ${echo} "execute \`nix run .#set-wg-key.${machine}\`."
      ${echo} ""
      ${echo} "If WireGuard key is already set and just want to rekey with updated ssh keys,"
      ${echo} "execute \`nix run .#rekey-wg-key.${machine}\`."
      ${echo} ""
      ${echo} "Finally, execute \`nix run .#remote-install-post-wg.${machine}\` to finish installing NixOS."
    '';

  remote-set-ssh-key = { mount-point, machine, host, ftn-name ? null }:
    remote-execution-over-ssh { inherit host ftn-name; } ''
      ${set-ssh-key { inherit mount-point machine; }}
    '';

  remote-install-pre-wg-key = { root-label, boot-label, mount-point, machine, host, force, ftn-name ? null }:
    ''
      ${echo} "Do you really want to partition and format all ssds?"
      ${echo} "WARNING : YOU CANNOT RECOVER DATA AFTER FORMATTING."
      read -p 'Please answer [yes/y] or [no/n] : ' username_input
      # Use a case statement to process the input and execute commands
      case "$username_input" in
        "yes"|"y")
          ${remote-partition-format-all-ssd { inherit root-label boot-label host force ftn-name; }}
          ${echo} "Did you paste the devices names to really want to partition and format all ssds?"
          read -p 'Please answer [yes/y] or [no/n] : ' devicename_input
          case "$devicename_input" in
            "yes"|"y")
              echo "Continue"
              ;;
            "no"|"n")
              echo "Abort"
              # Add the code for command 2 here
              exit 1
              ;;
            *)
              echo "Unknown command: $devicename_input"
              exit 1
              ;;
          esac
          ;;
        "no"|"n")
          echo "Stop partitioning and formatting all ssds and Exit."
          # Add the code for command 2 here
          exit 1
          ;;
        *)
          echo "Unknown command: $username_input"
          exit 1
          ;;
      esac
      ${remote-create-btrfs-subvolumes { inherit root-label mount-point host ftn-name; }}
      ${remote-create-btrfs-swap { inherit root-label mount-point host ftn-name; }}
      ${remote-mount-btrfs-subvolumes { inherit root-label boot-label mount-point host ftn-name; }}
      ${remote-mount-btrfs-swap { inherit root-label boot-label mount-point host ftn-name; }}
      ${remote-set-ssh-key { inherit mount-point machine host ftn-name; }}
    '';

  remote-nix-copy = { mount-point, toplevel, host, ftn-name ? null }:
    remote-execution-over-ssh { inherit host ftn-name; remote-store = mount-point; } ''
      ${echo} ${toplevel}
    '';

  remote-nixos-install = { mount-point, toplevel, host, ftn-name ? null }:
    remote-execution-over-ssh { inherit host ftn-name; } ''
      ${nixos-install} --root ${mount-point} --system ${toplevel} --no-root-passwd
    '';

  remote-install-post-wg-key = { mount-point, toplevel, host, ftn-name ? null }:
    ''
      ${remote-nix-copy { inherit mount-point toplevel host ftn-name; }}
      ${remote-nixos-install { inherit mount-point toplevel host ftn-name; }}
    '';

  deploy = { toplevel }:
    let
      profile = "/nix/var/nix/profiles/system";
    in
    ''
      sudo ${nix-env} --profile ${profile} --set ${toplevel} --substituters "https://cache.nixos.org"
      sudo ${profile}/bin/switch-to-configuration switch
    '';

  remote-deploy = { toplevel, host, user-name, ftn-name ? null }:
    remote-execution-over-ssh { inherit host user-name ftn-name; } ''
      ${deploy { inherit toplevel; }}
    '';
}
