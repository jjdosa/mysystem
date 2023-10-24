let
  sshUser = "jj";
  sshKey = "/home/jj/.ssh/id_ed25519";
in
{

  nix = {

    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "10.10.100.7";
        inherit sshUser sshKey;
        system = "x86_64-linux";
        maxJobs = 16;
        speedFactor = 4;
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        mandatoryFeatures = [ ];
      }
      {
        hostName = "10.10.100.8";
        inherit sshUser sshKey;
        system = "x86_64-linux";
        maxJobs = 16;
        speedFactor = 4;
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        mandatoryFeatures = [ ];
      }
      # {
      #   hostName = "10.10.100.3";
      #   inherit sshUser sshKey;
      #   system = "x86_64-linux";
      #   maxJobs = 6;
      #   speedFactor = 4;
      #   supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      #   mandatoryFeatures = [ ];
      # }
    ];

  };


  programs.ssh.extraConfig = ''
    Host b3
      HostName 10.10.100.3
      User jj
      IdentityFile ${sshKey}
    Host b7
      HostName 10.10.100.7
      User jj
      IdentityFile ${sshKey}
    Host b8
      HostName 10.10.100.8
      User jj
      IdentityFile ${sshKey}
  '';

  services.openssh.knownHosts."10.10.100.1".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOy9IObSEcyb3+3gGXuG8uUGIUiWAuW6hPjoq0059SvZ";
  services.openssh.knownHosts."10.10.100.2".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGpvlvAsXnWatOi0JLmrzy6ri443CuvujgW4k86i91Sn";
  services.openssh.knownHosts."10.10.100.3".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJRy4shsolok43LnXTrwWnPyJ+Gna6JYLQKxO66w8ZN";
  services.openssh.knownHosts."10.10.100.4".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsGAj/2BqvU6EUKaeW0ojVNl9yIH+N89z5+LvHsnx8k";
  services.openssh.knownHosts."10.10.100.5".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIFkD/jGF/atiNoGlN8WVBUinEfntOr6Vs96B2DWnvUO";
  services.openssh.knownHosts."10.10.100.6".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsRBagBDoPmuzq1jk8G6PiG6qKXwnG1lWy1dXQGLEgb";
  services.openssh.knownHosts."10.10.100.7".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ2C2kjRYFpS5SqZWtZVJ7o73qraXQd3f3egAvoDEcQr";
  services.openssh.knownHosts."10.10.100.8".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOnpu94SKQgPzWN8Ypd+A9+mqjQwkCe6SPTLNXuSR7p3";

}
