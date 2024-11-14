{
  nix-doom-emacs-unstraightened,
  anyrun,
  ...
}: {
  ##################################################################################################################
  #
  # All Ryan's Home Manager Configuration
  #
  ##################################################################################################################

  imports = [
    nix-doom-emacs-unstraightened.hmModule
    anyrun.homeManagerModules.default
    ../../home/core.nix

    ../../home/alacritty.nix
    ../../home/anyrun.nix
    ../../home/browsers.nix
    ../../home/container.nix
    ../../home/dev.nix
    ../../home/emacs/emacs.nix
    ../../home/hyprland
    ../../home/llm.nix
    ../../home/media.nix
    ../../home/obs-studio.nix
    ../../home/security.nix
    ../../home/shell.nix
    ../../home/sway
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
