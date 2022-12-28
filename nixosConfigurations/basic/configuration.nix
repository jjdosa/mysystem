{ config, lib, pkgs, ... }: {

  system.stateVersion = "22.11";

  nixpkgs = {
   config.allowUnfree = true;
   hostPlatform.system = "x86_64-linux";
  };

  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;

  time.timeZone = "Asia/Seoul";

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    neovim
    curl
    wget
    pciutils
    htop
    git
    tmux
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.forwardX11 = true;
  services.openssh.permitRootLogin = "yes";

  hardware.enableAllFirmware = true;

  users.users.root.openssh.authorizedKeys.keys = config.users.extraUsers.jj.openssh.authorizedKeys.keys;

}
