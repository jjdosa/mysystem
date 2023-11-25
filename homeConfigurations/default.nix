inputs:
let

  inherit (inputs) nixpkgs home-manager;
  inherit (home-manager.lib) homeManagerConfiguration;
  inherit (pkgs.lib) elemAt splitString;

  pkgs = nixpkgs.legacyPackages."x86_64-linux";

  getUserHostname = str: let
    list = splitString "@" str;
  in {
    user = elemAt list 0;
    hostname = elemAt list 1;
  };

  homeManagerConfigurations = __listToAttrs (map (name: let
    inherit (getUserHostname name) user hostname;
  in {
    inherit name;
    value = homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs; };
      modules = [ ./users/${user}/${hostname}.nix ];
    };
  }) [ "jj@urubamba"
       "jj@lima"
       "jj@lapaz"
       "jj@bogota"
       "jj@cusco"
       "jj@antofagasta"
       "jj@atacama"
       "jj@toledo"
       "jj@server"
       "jiwon@havana"
       "suwonp@urubamba"
     ]);

in homeManagerConfigurations
