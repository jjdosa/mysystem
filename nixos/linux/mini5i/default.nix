{ config, pkgs, ... }:
{
  imports = [
    ../../common
    ../../linux/common
    ../virtualisation
    ./hardware-configuration.nix
    ./wireguard
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "mini5i";
    networkmanager = {
      enable   = true;
      packages = [ pkgs.networkmanager ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

}