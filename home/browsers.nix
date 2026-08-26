{ pkgs, ... }:
{
  home.packages = with pkgs; [
    brave
    ferdium
    firefox
    transmission_4-gtk
    # nyxt
  ];

  xdg.desktopEntries = {
    t3code = {
      name = "T3 Code";
      comment = "Open T3 Code as a desktop app";
      exec = "${pkgs.lib.getExe pkgs.brave} --app=http://localhost:13773";
      icon = "brave-browser";
      categories = [ "Development" ];
    };

    slack-caliptra = {
      name = "Slack - Caliptra Workspace";
      comment = "Open the Caliptra Slack workspace as a desktop app";
      exec = "${pkgs.lib.getExe pkgs.brave} --app=https://caliptraworkspace.slack.com";
      icon = "brave-browser";
      categories = [
        "Network"
        "InstantMessaging"
      ];
    };

    slack-osfw = {
      name = "Slack - OSFW";
      comment = "Open the OSFW Slack workspace as a desktop app";
      exec = "${pkgs.lib.getExe pkgs.brave} --app=https://osfw.slack.com";
      icon = "brave-browser";
      categories = [
        "Network"
        "InstantMessaging"
      ];
    };

    slack-9elements = {
      name = "Slack - 9elements";
      comment = "Open the 9elements Slack workspace as a desktop app";
      exec = "${pkgs.lib.getExe pkgs.brave} --app=https://9elements.slack.com";
      icon = "brave-browser";
      categories = [
        "Network"
        "InstantMessaging"
      ];
    };
  };
}
