{ pkgs, inputs, ... }:
let
  mypackages = inputs.self.packages.${pkgs.system};
in
{

  imports = [
    ./alacritty
    ./kitty
    # ./firefox
    # ./qutebrowser
    ./rofi
    ./zathura.nix
    ./brave.nix
    ./xdg.nix
    ./fonts.nix
    ./images.nix
    ./pdfs.nix
    ./videos.nix
  ];

  home.packages = with pkgs; [

    networkmanager_dmenu
    networkmanagerapplet

    xorg.xkbcomp           # keymaps modifier
    xorg.xrandr            # display manager (X Resize and Rotate protocol)
    xorg.xev
    arandr
    autorandr
    xdotool

    acpilight              # xbacklight drop-in replacement; adjust display brightness
    pavucontrol            # control audio in/out
    i3lock-fancy-rapid

    libreoffice
    zoom-us
    gnome.nautilus
    trayer

    # virtualbox
    anydesk
    slack
    kotatogram-desktop
    solaar                # Linux device manager for the Logitech Unifying Receiver
    scrot                 # cli screen saver

    sweethome3d.application
    discord
  ] ++
  (with mypackages; [
    screenlayout
    mysetxkbmap
    dmenu-scripts
  ]);


  # xsession.enable = true;
  # xsession.initExtra = ''
  #   setxkbmap -option altwin:swap_lalt_lwin -option caps:ctrl_modifier
  # '';

  # xresources.properties = {
  #   "Xft.dpi" = 120;
  #   "Xft.autohint" = 0;
  #   "Xft.hintstyle" = "hintfull";
  #   "Xft.hinting" = 1;
  #   "Xft.antialias" = 1;
  #   "Xft.rgba" = "rgb";
  #   "Xcursor*theme" = "Vanilla-DMZ-AA";
  #   "Xcursor*size" = 24;
  # };
}
