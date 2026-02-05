{ pkgs, ... }:
{
  imports = [ ./waybar.nix ];

  home.packages = with pkgs; [
    cliphist
    grim
    networkmanagerapplet
    pavucontrol
    playerctl
    slurp
    swaybg
    swaylock
    waypipe
    wl-clipboard
    xdg-user-dirs
  ];

  services.blueman-applet.enable = true;

  services.mako = {
    enable = true;
    settings.height = 1000;
  };

  services.network-manager-applet.enable = true;
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };
}
