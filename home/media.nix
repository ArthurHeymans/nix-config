{pkgs, ...}: {
  home.packages = with pkgs; [
    vlc
    spotify
    mpv
    evince
    nautilus
    mullvad-vpn
  ];
}
