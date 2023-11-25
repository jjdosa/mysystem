{ pkgs }:
let

  inherit (pkgs.lib)
    concatStringsSep
  ;

  inherit (pkgs)
    writeShellApplication
    writeStringReferencesToFile
  ;

  echo = "${pkgs.coreutils}/bin/echo";
  ssh = "${pkgs.openssh}/bin/ssh";
  nix = "${pkgs.nixFlakes}/bin/nix";

  remote-execution-over-ssh =
    { host
    , ftn-name ? null
    , user-name ? "root"
    , ssh-option ? "-o StrictHostKeyChecking=No -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null"
    , ssh-command ? ''${ssh} ${ssh-option} -T "${user-name}@${host}"''
    , runtimeInputs ? []
    , private-key ? null
    , remote-store ? null
    , extraArgs ? []
    , trace ? true
    }:
    snippet:
    let

      indent = "\t";

      snippet-to-script-exec =
        { name
        , text
        , runtimeInputs ? [ ]
        # , meta ? { } # NOTE: not yet included in 23.05. May break after 23.11.
        , checkPhase ? ""
        }:
        let
          inputs = { inherit name text runtimeInputs checkPhase; };
        in "${writeShellApplication inputs}/bin/${name}";

      script-exec =
        let
          script-exec' = snippet-to-script-exec {
            inherit runtimeInputs;
            name = "remote-run";
            text = snippet;
          };
        in if remote-store != null
        then "${remote-store}/${script-exec'}"
        else "${script-exec'}";

      references = writeStringReferencesToFile script-exec;
      private-key-str = if private-key != null then "-i ${private-key}" else "";
      extraArgs' = [ "-o StrictHostKeyChecking=no"
                     "-o UserKnownHostsFile=/dev/null"
                     "-o \"ServerAliveInterval 2\""
                     private-key-str
                   ] ++
                   extraArgs;

      store-uri = let
        queries = concatStringsSep "" [
          (if private-key != null then "?ssh-key=${private-key}" else "")
          (if remote-store != null then "?remote-store=${remote-store}" else "")
        ];
      in "ssh-ng://${user-name}@${host}${queries}";

    in ''
        ### remote-execution-over-ssh ###
        ${if ftn-name != null then ''${echo} "Start : ${ftn-name}"'' else ""}

        handle_error() {
          exit 1
        }
        trap handle_error ERR SIGINT SIGKILL SIGTERM SIGHUP

        NIX_SSHOPTS="${ssh-option}" \
        ${nix} copy ${references} \
           --to "${store-uri}" \
           --no-check-sigs

        ${ssh-command} ${toString extraArgs'} <<EOF
        ${indent}${script-exec}
        EOF

        ${if ftn-name != null then ''${echo} "End : ${ftn-name}"'' else ""}
        #################################
      '';


in remote-execution-over-ssh
