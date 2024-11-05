{ pkgs, nix-doom-emacs-unstraightened, anyrun, ... }:
{
  ##################################################################################################################
  #
  # All Ryan's Home Manager Configuration
  #
  ##################################################################################################################

  imports = [
    nix-doom-emacs-unstraightened.hmModule
    anyrun.homeManagerModules.default
    ../../home/core.nix

    ../../home/anyrun.nix
    ../../home/alacritty.nix
    ../../home/sway
    ../../home/browsers.nix
    ../../home/media.nix
    ../../home/container.nix
    ../../home/emacs/emacs.nix
    ../../home/shell.nix
    ../../home/dev.nix
    ../../home/llm.nix
    ../../home/security.nix
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
    signing = {
      signByDefault = true;
      key = "4401A5C26DF3FFFDF472F84AA1D13A950A6651BB";
    };
  };
}
