{pkgs, ...}: {
  home.packages = with pkgs; [
    brave
    ferdium
    firefox
    transmission_4-gtk
    nyxt
  ];

  services.syncthing.enable = true;

  xdg.desktopEntries.firefox-tridactyl = {
    name = "Firefox (Tridactyl)";
    genericName = "Web Browser";
    comment = "Firefox with Tridactyl profile";
    exec = "firefox --no-remote -P tridactyl %u";
    icon = "firefox";
    type = "Application";
    categories = [ "Network" "WebBrowser" ];
    mimeType = [ "text/html" "x-scheme-handler/http" "x-scheme-handler/https" ];
  };
}
