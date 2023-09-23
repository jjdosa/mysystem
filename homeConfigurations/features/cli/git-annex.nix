# https://interfect.github.io/#!/posts/005-Novaks-Teach-Other-People-git-annex-in-60-Minutes-Or-Less.md
# https://git-annex.branchable.com/walkthrough/
# https://writequit.org/articles/getting-started-with-git-annex.html
{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      git-annex
      git-annex-utils
      git-annex-metadata-gui
    ];
  };
}
