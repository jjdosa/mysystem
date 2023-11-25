{ pkgs, nixosConfigurations, homeConfigurations }:
let

  inherit (pkgs)
    lib
    writeScriptBin
  ;

  inherit (pkgs.lib)
    flip
  ;

  mylib = import ../lib pkgs;

  inherit (mylib)
    get-user-hostname
    get-toplevel
  ;

  inherit (mylib.snippets)
    mk-ssh-key
    mk-age-file
    mk-wg-key
    remote-install
  ;

  inherit (mylib)
    echo nixos-install blkdiscard
  ;

  text-to-app = name: text:
    let script = writeScriptBin "${name}.sh" ''
        ${text}
      '';
    in { type = "app"; program = "${script}/bin/${name}.sh"; };


  hosts = import ../nixosConfigurations/host-ips.nix;

  host-ips = import ../nixosConfigurations/host-ips.nix;

in
{

  deploy = {
    nixos = lib.flip __mapAttrs nixosConfigurations (name: nixos:
      let
        host = hosts."${name}";
        toplevel = nixos.config.system.build.toplevel;
        profile = "/nix/var/nix/profiles/system";
      in
      text-to-app "deploy-${name}" ''
        nix copy ${toplevel} --to ssh://${host}
        ssh ${host} sudo nix-env --profile ${profile} --set ${toplevel}
        ssh ${host} sudo ${profile}/bin/switch-to-configuration switch
      ''
    );

    home = lib.flip __mapAttrs homeConfigurations (name: home:
      let
        inherit (get-user-hostname name) user hostname;
        host = "${user}@${hosts."${hostname}"}";
        script = home.activationPackage;
      in
      text-to-app "deploy-${name}" ''
        nix copy ${script} --to ssh://${host}
        ssh ${host} ${script}/bin/home-manager-generation
      ''
    );
  };

  auth = {

    mk-ssh-key = text-to-app "mk-ssh-key" ''

      if [ "$#" -ne 2 ]; then
          echo "Expecting two arguments for path and label"
          echo "nix run .#auth.mk-ssh-key {dir} {label}"
          exit 1
      fi

      export MYSYSTEM_PATH=$1
      export MYSYSTEM_LABEL=$2

      ${mk-ssh-key { }}

      unset MYSYSTEM_PATH
      unset MYSYSTEM_LABEL
    '';


    mk-wg-key = text-to-app "mk-wg-key" ''

      if [ "$#" -ne 2 ]; then
          echo "Expecting two arguments for path and label"
          echo "nix run .#auth.mk-ssh-key {dir} {label}"
          exit 1
      fi

      export MYSYSTEM_PATH=$1
      export MYSYSTEM_LABEL=$2

      ${mk-wg-key { }}

      unset MYSYSTEM_PATH
      unset MYSYSTEM_LABEL
    '';


  };


  remote-install = flip __mapAttrs nixosConfigurations (host-name: nixos:
    let
      host = host-ips."${host-name}";
      toplevel = nixos.config.system.build.toplevel;
      profile = "/nix/var/nix/profiles/system";
      root-label = "root";
      boot-label = "BOOT";
      mount-point = "/mnt";
    in
    {
      partition-format-encrypt-all-ssd =
        let ftn-name = "remote-partition-format-encrypt-all-ssd"; in
          text-to-app "${ftn-name}-${host-name}" ''
            ${mylib."${ftn-name}" { inherit root-label boot-label host ftn-name; force = "false"; }}
          '';

      partition-format-all-ssd =
        let
          ftn-name = "remote-partition-format-all-ssd";
          host = host-ips."${host-name}";
        in
        text-to-app "${ftn-name}-${host-name}" ''
          ${mylib."${ftn-name}" { inherit root-label boot-label host ftn-name; force = "false"; }}
        '';

      decrypt-all-ssd =
        let
          ftn-name = "remote-decrypt-all-ssd";
          host = host-ips."${host-name}";
        in
        text-to-app "${ftn-name}-${host-name}" ''
          ${mylib."${ftn-name}" { inherit root-label boot-label host ftn-name; force = "false"; }}
        '';

      create-btrfs-subvolumes =
        let
          ftn-name = "remote-create-btrfs-subvolumes";
          host = host-ips."${host-name}";
        in
        text-to-app "${ftn-name}-${host-name}" ''
          ${mylib."${ftn-name}" { inherit root-label mount-point host ftn-name; }}
        '';

      create-btrfs-swap =
        let
          ftn-name = "remote-create-btrfs-swap";
          host = host-ips."${host-name}";
        in
        text-to-app "${ftn-name}-${host-name}" ''
          ${mylib."${ftn-name}" { inherit root-label mount-point host ftn-name; }}
        '';

      mount-btrfs-subvolumes =
        let
          ftn-name = "remote-mount-btrfs-subvolumes";
          host = host-ips."${host-name}";
        in
        text-to-app "${ftn-name}-${host-name}" ''
          ${mylib."${ftn-name}" { inherit root-label boot-label mount-point host ftn-name; }}
        '';

      mount-btrfs-swap =
        let
          ftn-name = "remote-mount-btrfs-swap";
          host = host-ips."${host-name}";
        in
        text-to-app "${ftn-name}-${host-name}" ''
          ${mylib."${ftn-name}" { inherit root-label boot-label mount-point host ftn-name; }}
        '';

      set-ssh-key =
        let
          ftn-name = "remote-set-ssh-key";
          machine = host-name;
          host = host-ips."${host-name}";
        in
        text-to-app "${ftn-name}-${host-name}" ''
          ${mylib."${ftn-name}" { inherit mount-point host machine ftn-name; }}
        '';

      nix-copy =
        let
          ftn-name = "remote-nix-copy";
          toplevel = get-toplevel nixos;
          host = host-ips."${host-name}";
        in
        text-to-app "${ftn-name}-${host-name}" ''
          ${mylib."${ftn-name}" { inherit mount-point host toplevel ftn-name; }}
        '';

      nixos-install =
        let
          ftn-name = "remote-nixos-install";
          toplevel = get-toplevel nixos;
          host = host-ips."${host-name}";
        in
        text-to-app "${ftn-name}-${host-name}" ''
          ${mylib."${ftn-name}" { inherit mount-point host toplevel ftn-name; }}
        '';

      install-pre-wg-key =
        let
          ftn-name = "remote-install-pre-wg-key";
          host = host-ips."${host-name}";
          machine = host-name;
        in
        text-to-app "${ftn-name}-${host-name}" ''
          ping -c 3 ${host}
          ${mylib."${ftn-name}" {
            inherit root-label boot-label mount-point machine host ftn-name; force = "false"; }}
        '';

      install-post-wg-key =
        let
          ftn-name = "remote-install-post-wg-key";
          toplevel = get-toplevel nixos;
          host = host-ips."${host-name}";
        in
        text-to-app "${ftn-name}-${host-name}" ''
          ${mylib."${ftn-name}" { inherit mount-point host toplevel ftn-name; }}
        '';

    });


  ping-host = flip __mapAttrs nixosConfigurations (host-name: nixos:
    let
      host = host-ips."${host-name}";
    in
    text-to-app "ping-host" ''
      ping -c 3 ${host}
    ''
  );

  set-wg-key = flip __mapAttrs nixosConfigurations (host-name: _:
    let
      ftn-name = "set-wg-key";
      machine = host-name;
    in
    text-to-app "${ftn-name}-${host-name}" ''
      ${mylib."${ftn-name}" { inherit machine; }}
    ''
  );

  set-peerix =
    let
      ftn-name = "set-peerix";
    in
    text-to-app "${ftn-name}" ''
      ${mylib."${ftn-name}"}
    '';

  rekey-wg-key = flip __mapAttrs nixosConfigurations (host-name: _:
    let
      ftn-name = "rekey-wg-key";
      machine = host-name;
    in
    text-to-app "${ftn-name}-${host-name}" ''
      ${mylib."${ftn-name}" { inherit machine; }}
    ''
  );



}
