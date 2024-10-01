{ pkgs, nix-doom-emacs-unstraightened, ... }:
{
  ##################################################################################################################
  #
  # All Ryan's Home Manager Configuration
  #
  ##################################################################################################################

  imports = [
    nix-doom-emacs-unstraightened.hmModule
    ../../home/core.nix

    ../../home/alacritty.nix
    ../../home/sway
    ../../home/browsers.nix
    ../../home/media.nix
    ../../home/container.nix
    ../../home/emacs/emacs.nix
    ../../home/shell.nix
    #   ../../home/fcitx5
    #    ../../home/i3
    #    ../../home/programs
    #    ../../home/rofi
    #    ../../home/shell
  ];

  programs.git = {
    enable = true;
    userName = "Arthur Heymans";
    userEmail = "arthur@aheymans.xyz";
  };
}
