{
  programs.qutebrowser = {
    enable = true;
    extraConfig = ''

      config.load_autoconfig(False)
      config.set("colors.webpage.darkmode.enabled", True)

      config.bind('M', 'hint links spawn mpv {hint-url}')
      config.bind('Z', 'hint links spawn alacritty -e youtube-dl {hint-url}')
      config.bind('t', 'set-cmd-text -s :open -t')
      config.bind('xb', 'config-cycle statusbar.show always never')
      config.bind('xt', 'config-cycle tabs.show always never')
      config.bind('xx', 'config-cycle statusbar.show always never;; config-cycle tabs.show always never')
      config.bind('xd', 'config-cycle colors.webpage.darkmode.enabled ;; restart')

    '';
  };
}
