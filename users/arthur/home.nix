{
#  niri,
  nix-doom-emacs-unstraightened,
  sops-nix,
  ...
}: {
  ##################################################################################################################
  #
  # All Arthur's Home Manager Configuration
  #
  ##################################################################################################################

  imports = [
    nix-doom-emacs-unstraightened.hmModule
    sops-nix.homeManagerModules.sops
 #   niri.homeModules.niri
    ../../home/core.nix

    ../../home/alacritty.nix
    ../../home/browsers.nix
    ../../home/container.nix
    ../../home/crypto.nix
    ../../home/dev.nix
    ../../home/emacs/emacs.nix
    ../../home/email.nix
    ../../home/hyprland
    ../../home/keyboard.nix
    ../../home/kitty.nix
    ../../home/llm.nix
    ../../home/media.nix
#    ../../home/niri
    ../../home/pcb.nix
    ../../home/obs-studio.nix
    ../../home/presenterm.nix
    ../../home/security.nix
    ../../home/shell.nix
    ../../home/sops.nix
    ../../home/sway
    #   ../../home/fcitx5
    #    ../../home/i3
    #    ../../home/programs
    #    ../../home/rofi
    #    ../../home/shell
  ];

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Arthur Heymans";
        email = "arthur@aheymans.xyz";
      };
      github.user = "ArthurHeymans";
    };
    signing = {
      signByDefault = true;
      key = "4401A5C26DF3FFFDF472F84AA1D13A950A6651BB";
    };
    ignores = [
      ".aider*"
      ".envrc"
      ".direnv"
      ".direnv/*"
      ".dir-locals.el"
    ];
  };
}
