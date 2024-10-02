{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    ispell
    aspell
    aspellDicts.nl
    aspellDicts.fr
    aspellDicts.en
    graphviz # DOT for org-roam
    mu
    isync
    clang-tools
  ];

  programs.doom-emacs = {
    enable = true;
    doomDir = ./.;
  };
}
