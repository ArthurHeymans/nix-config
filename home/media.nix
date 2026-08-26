{
  pkgs,
  hostname,
  ...
}:
{
  programs.mpv = {
    enable = true;
    config.hwdec = "auto";
    scripts = with pkgs.mpvScripts; [ mpris ];
  };

  home.packages = with pkgs; [
    vlc
    spotify
    evince
    nautilus
    mullvad-vpn
    signal-desktop
    telegram-desktop
    calibre
    #libreoffice
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
}
