{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [ ispell ];

  programs.doom-emacs = {
    enable = true;
    doomDir = ./.;
  };
}
