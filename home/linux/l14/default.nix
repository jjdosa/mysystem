{ config, pkgs , lib , ... }:

{

  imports = [
    ../common
  ];


  xresources.properties = {
    "Xft.dpi" = 90;
    "Xft.autohint" = 0;
    "Xft.hintstyle" = "hintfull";
    "Xft.hinting" = 1;
    "Xft.antialias" = 1;
    "Xft.rgba" = "rgb";
    "Xcursor*theme" = "Vanilla-DMZ-AA";
    "Xcursor*size" = 24;
  };


  xsession.enable = true;
  xsession.initExtra = ''

    # make trackpad and trackpoint faster
    xinput set-prop "ELAN0672:00 04F3:3187 Touchpad" 335 1
    xinput set-prop "TPPS/2 Elan TrackPoint" 335 0.5

    # disble the trackpad
    xinput set-prop "ELAN0672:00 04F3:3187 Touchpad" "Device Enabled" 0

    # Below does not work. Maybe overwritten by something somewhere
    # ${pkgs.xorg.xkbcomp}/bin/setxkbmap -option altwin:swap_lalt_lwin -option caps:ctrl_modifier
    ${pkgs.xorg.xkbcomp}/bin/setxkbmap -option caps:ctrl_modifier

  '';


  home.packages = with pkgs; [
    myhaskell-full
    mypython-full
    myjupyter-full
  ];


  home.file = {
    ".config/xmobar/xmobarrc".source = ../../services/xmonad/xmobarrc-laptop;
  };

}
