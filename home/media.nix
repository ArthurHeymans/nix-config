{pkgs, ...}: {
  home.packages = with pkgs; [
    vlc
    spotify
    mpv
    evince
    nautilus
    mullvad-vpn
    signal-desktop-bin
    calibre
    libreoffice
  ];

  xdg.userDirs.enable = true;
  xdg.userDirs.createDirectories = true;
}
