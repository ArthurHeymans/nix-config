{ lib, pkgs, ... }:
let
  # EWM uses EDNC inside Emacs for org.freedesktop.Notifications.  Mako can be
  # activated directly by D-Bus, so wrap its binary and service files to stay
  # out of EWM sessions while keeping it available for other Wayland desktops.
  makoNonEwm = pkgs.symlinkJoin {
    name = "mako-non-ewm";
    paths = [ pkgs.mako ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/mako
      makeWrapper ${lib.getExe pkgs.mako} $out/bin/mako \
        --run 'case ":''${XDG_CURRENT_DESKTOP:-}:" in *:ewm:*|*:EWM:*) echo "mako is disabled for EWM sessions; use EDNC instead." >&2; exit 1;; esac; if @SYSTEMCTL@ --user -q is-active ewm.service ewm-emacs.service 2>/dev/null; then echo "mako is disabled for EWM sessions; use EDNC instead." >&2; exit 1; fi'
      substituteInPlace $out/bin/mako \
        --replace-fail @SYSTEMCTL@ ${pkgs.systemd}/bin/systemctl

      rm $out/share/dbus-1/services/fr.emersion.mako.service
      cat > $out/share/dbus-1/services/fr.emersion.mako.service <<'EOF'
      [D-BUS Service]
      Name=org.freedesktop.Notifications
      Exec=@MAKO@
      SystemdService=mako.service
      EOF
      substituteInPlace $out/share/dbus-1/services/fr.emersion.mako.service \
        --replace-fail @MAKO@ $out/bin/mako

      rm $out/share/systemd/user/mako.service
      cat > $out/share/systemd/user/mako.service <<'EOF'
      [Unit]
      Description=Lightweight Wayland notification daemon
      Documentation=man:mako(1)
      PartOf=graphical-session.target
      After=graphical-session.target

      [Service]
      Type=dbus
      BusName=org.freedesktop.Notifications
      ExecCondition=/bin/sh -c 'case ":''${XDG_CURRENT_DESKTOP:-}:" in *:ewm:*|*:EWM:*) exit 1;; esac; if @SYSTEMCTL@ --user -q is-active ewm.service ewm-emacs.service 2>/dev/null; then exit 1; fi; [ -n "$WAYLAND_DISPLAY" ]'
      ExecStart=@MAKO@
      ExecReload=@MAKOCTL@ reload
      EOF
      substituteInPlace $out/share/systemd/user/mako.service \
        --replace-fail @MAKO@ $out/bin/mako \
        --replace-fail @MAKOCTL@ ${lib.getExe' pkgs.mako "makoctl"} \
        --replace-fail @SYSTEMCTL@ ${pkgs.systemd}/bin/systemctl
    '';
  };
in
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
    package = makoNonEwm;
    settings.height = 1000;
  };

  services.network-manager-applet.enable = true;
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };
}
