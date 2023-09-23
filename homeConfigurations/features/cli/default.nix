{ pkgs, inputs, ... }:
let
  mypackages = inputs.self.packages.${pkgs.system};
in
{

  imports = [
    ./bash.nix
    ./bat.nix
    ./direnv.nix
    ./fzf.nix
    ./git.nix
    ./ssh.nix
    ./starship.nix
    ./broot.nix
    ./shellAliases.nix
    ./nix-index.nix
    ./pfetch.nix
    ./htop.nix
    ./giter.nix
    ./git-annex.nix
  ];


  programs.jq.enable = true;         # Command-line JSON processor
  programs.bat.enable = true;
  programs.zoxide.enable = true;
  programs.pandoc.enable = true;
  programs.gpg.enable = true;


  home.packages = with pkgs; [
    comma             # run or install a program by sticking `,` it
    bc                # An arbitrary precision calculator language
    file              # determine file type
    unzip             # list, test and extract compressed files in a ZIP archive
    ncdu              # NCurses Disk Usage
    prettyping        # pretty ping
    diff-so-fancy     # fancy diff
    delta             # stylize diff
    gnused            # stream editor for filtering and transforming text
    coreutils         # a collection of the core utilities
    neofetch          # A fast, highly customizable system info script
    youtube-dl        # download videos from youtube.com or other video platforms
    cmatrix           # Shows a scrolling 'Matrix' like screen in Linux
    pass              # stores, retrieves, generates, and synchronizes passwords securely
    fd                # simple, fast and user-friendly alternative to find
    # exa               # a modern replacement for ls
    ripgrep           # a modern replacement for grep
    httpie            # a modern replacement for curl
    tokei             # LOC analyser
    hyperfine         # command-line benchmarking tool
    procs             # process searcher
    du-dust           # Like du but more intuitive
    grex              # generates regular expressions from user-provided test cases.
    killall           # kill processes by name
    bottom            # alternative to htop & ytop
    tree              # display files in a tree view
    nload             # network traffic monitoring
    bandwhich         # display current network utilization
    magic-wormhole    # Securely and simply transfer data between computers
    sshfs             # mount ssh server
    acpi              # battery check
    jless             # json viewer
    jc
    nixos-shell
    dig
    dasel
    xpra
    lshw
  ] ++
  (with mypackages; [
    tmux
    tex
    trim-generations
  ]);

}
