{ inputs, pkgs, ... }:
let

  nix-melt = inputs.nix-melt.packages.${pkgs.system}.default;
  # nix-visualize = pkgs.callPackage inputs.nix-visualize { }; # Requires python 2.7. I don't know why

in
{

  imports = [
  ];

  home.packages = with pkgs; [
    nvd          # Nix/NixOS package version diff tool
    rnix-lsp     # Nix language server
    nixfmt
    nix-doc
    nix-tree     # Interactively browse dependency graphs
    nix-diff
    nix-melt
    # nix-visualize
    nix-du       # investigate disk usage
    deadnix      # Find dead code in .nix files
    statix       # Lints and suggestions for the Nix programming language
    any-nix-shell
    nix-query-tree-viewer
    haskellPackages.nix-derivation # Inspecting .drv's
  ];

}
