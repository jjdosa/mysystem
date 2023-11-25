inputs:
let

  inherit (inputs.nixpkgs.lib) nixosSystem;
  specialArgs = { inherit inputs; };

  nixosSystems = __listToAttrs (map (name: {
    inherit name;
    value = nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [ ./hosts/${name} ];
    };
  }) [ "urubamba"
       "lima"
       "lapaz"
       "bogota"
       "cusco"
       "antofagasta"
       "giron"
       "iguazu"
       "garganta"
       "usb"
       "havana"
       "atacama"
       "toledo"
     ]);

in nixosSystems
