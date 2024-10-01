{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.doom-emacs = {
    enable = true;
    doomDir = ./.;
  };
}
