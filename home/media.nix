{
  pkgs,
  config,
  hostname,
  ...
}:
{
  home.packages = with pkgs; [
    vlc
    spotify
    mpv
    evince
    nautilus
    mullvad-vpn
    signal-desktop
    calibre
    libreoffice
    gimp
  ];

  xdg.userDirs.enable = true;
  xdg.userDirs.createDirectories = true;
  xdg.userDirs.setSessionVariables = false;

  services.librespot = {
    enable = true;
    settings = {
      device-type = "computer";
      name = "${hostname}-librespot";
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "video/x-matroska" = "mpv.desktop";
      "video/mp4" = "mpv.desktop";
    };
  };
}
