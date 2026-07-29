{ inputs, ... }:
{
  ##################################################################################################################
  #
  # All Arthur's Home Manager Configuration
  #
  ##################################################################################################################

  imports = [
    inputs.nix-doom-emacs-unstraightened.hmModule
    inputs.sops-nix.homeManagerModules.sops
    # niri.homeModules.niri is injected automatically by niri.nixosModules.niri
    ../../home/options.nix
    ../../home/core.nix
    ../../home/version-control.nix

    ../../home/alacritty.nix
    ../../home/browsers.nix
    ../../home/voxtype.nix
    ../../home/syncthing.nix
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
    ../../home/mime.nix
    ../../home/niri
    ../../home/pcb.nix
    ../../home/obs-studio.nix
    ../../home/presenterm.nix
    ../../home/security.nix
    ../../home/shell.nix
    ../../home/sops.nix
    ../../home/sway
    ../../home/wayland
    #   ../../home/fcitx5
    #    ../../home/i3
    #    ../../home/programs
    #    ../../home/rofi
    #    ../../home/shell
  ];
}
