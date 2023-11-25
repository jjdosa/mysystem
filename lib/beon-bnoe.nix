rec {

  # beon = by-env-or-nix
  # if the environment variable is set then use it
  # otherwise use the nix variable if it is not empty
  get-var-by-env-or-nix = { name ? "myvar", env-var ? "MYSYSTEM_VAR", nix-var ? "" }: ''
    if [ -n "${"$"}${env-var}" ]; then
      ${name}="${"$"}${env-var}"
    elif [ -n "${nix-var}" ]; then
      ${name}="${nix-var}"
    else
      echo "No ${name} source found as the environment variable ${env-var} nor the Nix variable."
      exit 1
    fi
  '';

  # bnoe = by-nix-or-env
  # if the nix variable is set then use it
  # otherwise use the environment variable if it is not empty
  get-var-by-nix-or-env = { name ? "myvar", env-var ? "MYSYSTEM_VAR", nix-var ? "" }: ''
    if [ -n "${nix-var}" ]; then
      ${name}="${nix-var}"
    elif [ -n "${"$"}${env-var}" ]; then
      ${name}="${"$"}${env-var}"
    else
      echo "No ${name} source found as the Nix variable nor the environment variable ${env-var}."
      exit 1
    fi
  '';

  get-var = { name ? "myvar", env-var ? "MYSYSTEM_VAR", nix-var ? "", type ? "beon" }@input:
    if type == "beon"
      then get-var-by-env-or-nix { inherit name env-var nix-var; }
      else get-var-by-nix-or-env { inherit name env-var nix-var; };

}
