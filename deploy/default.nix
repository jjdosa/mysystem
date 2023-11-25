inputs:
let

  inherit (inputs.nixpkgs.legacyPackages."x86_64-linux") lib;
  inherit (inputs) deploy-rs;
  inherit (inputs.self) nixosConfigurations homeConfigurations;

  activate-nixos = system: deploy-rs.lib.${system}.activate.nixos;
  activate-home = system: deploy-rs.lib.${system}.activate.home-manager;
  activate-custom = system: deploy-rs.lib.${system}.activate.custom;

  host-ips = import ../nixosConfigurations/host-ips.nix;

  server-nodes = __listToAttrs (map (name: {
    inherit name;
    value = {
      hostname = host-ips."${name}";
      profiles."jj" = {
        user = "jj";
        path = activate-home "x86_64-linux" homeConfigurations."jj@server";
      };
    };
  }) [
    "gateway"
    "hproxy"
    "hserver"
    "uyuni"
    "giron"
    "b3"
    "b4"
    "b5"
    "b6"
  ]);

in
{

  magicRollback = false;
  autoRollback = false;

  user = "root";
  sshUser = "jj";
  sshOpts = [ "-o StrictHostKeyChecking=no" ];
  fastConnection = true;

  nodes = {

    lima = {
      hostname = host-ips.lima;
      profiles.system.path = activate-nixos "x86_64-linux" nixosConfigurations.lima;
      profiles."jj" = {
        user = "jj";
        path = activate-home "x86_64-linux" homeConfigurations."jj@lima";
      };
    };

    urubamba = {
      hostname = host-ips.urubamba;
      profiles.system.path = activate-nixos "x86_64-linux" nixosConfigurations.urubamba;
      profiles."jj" = {
        user = "jj";
        path = activate-home "x86_64-linux" homeConfigurations."jj@urubamba";
      };
      profiles."suwonp" = {
        user = "suwonp";
        path = activate-home "x86_64-linux" homeConfigurations."suwonp@urubamba";
      };
    };

    cusco = {
      hostname = host-ips.cusco;
      profiles.system.path = activate-nixos "x86_64-linux" nixosConfigurations.cusco;
      profiles."jj" = {
        user = "jj";
        path = activate-home "x86_64-linux" homeConfigurations."jj@cusco";
      };
    };

    lapaz = {
      hostname = host-ips.lapaz;
      profiles.system.path = activate-nixos "x86_64-linux" nixosConfigurations.lapaz;
      profiles."jj" = {
        user = "jj";
        path = activate-home "x86_64-linux" homeConfigurations."jj@lapaz";
      };
    };

    bogota = {
      hostname = host-ips.bogota;
      profiles.system.path = activate-nixos "x86_64-linux" nixosConfigurations.bogota;
      profiles."jj" = {
        user = "jj";
        path = activate-home "x86_64-linux" homeConfigurations."jj@bogota";
      };
    };

    antofagasta = {
      hostname = host-ips.antofagasta;
      profiles.system.path = activate-nixos "x86_64-linux" nixosConfigurations.antofagasta;
      profiles."jj" = {
        user = "jj";
        path = activate-home "x86_64-linux" homeConfigurations."jj@antofagasta";
      };
    };

    giron = {
      hostname = host-ips.giron;
      profiles.system.path = activate-nixos "x86_64-linux" nixosConfigurations.giron;
      profiles."jj" = {
        user = "jj";
        path = activate-home "x86_64-linux" homeConfigurations."jj@server";
      };
    };

    atacama = {
      hostname = host-ips.atacama;
      profiles.system.path = activate-nixos "x86_64-linux" nixosConfigurations.atacama;
      profiles."jj" = {
        user = "jj";
        path = activate-home "x86_64-linux" homeConfigurations."jj@atacama";
      };
    };

    toledo = {
      hostname = host-ips.toledo;
      profiles.system.path = activate-nixos "x86_64-linux" nixosConfigurations.toledo;
      profiles."jj" = {
        user = "jj";
        path = activate-home "x86_64-linux" homeConfigurations."jj@toledo";
      };
    };

    havana = {
      hostname = host-ips.havana;
      profiles.system.path = activate-nixos "x86_64-linux" nixosConfigurations.havana;
      profiles."jj" = {
        user = "jj";
        path = activate-home "x86_64-linux" homeConfigurations."jj@server";
      };
      profiles."jiwon" = {
        user = "jiwon";
        path = activate-home "x86_64-linux" homeConfigurations."jiwon@havana";
      };
    };

  }
  //
  server-nodes
  ;

}
