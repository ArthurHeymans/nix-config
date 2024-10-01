{pkgs, ...}: {
  ##################################################################################################################
  #
  # All Ryan's Home Manager Configuration
  #
  ##################################################################################################################

  imports = [
    ../../home/core.nix

    ../../home/alacritty.nix
    ../../home/sway
    ../../home/browsers.nix
    ../../home/media.nix
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
