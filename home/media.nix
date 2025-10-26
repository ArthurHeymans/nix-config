{ pkgs, config, hostname, ... }: {
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

  services.librespot = {
    enable = true;
    settings = {
      device-type = "computer";
      name = "${hostname}-librespot";
    };
  };
}
