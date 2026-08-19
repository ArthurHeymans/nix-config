{
  config,
  pkgs,
  inputs,
  username,
  ...
}:
let
  ewmEmacsPackage = config.home-manager.users.${username}.programs.doom-emacs.finalEmacsPackage;

  patchedEwmPackage = pkgs.callPackage ../packages/ewm.nix {
    src = inputs.ewm;
    emacsPackage = ewmEmacsPackage.emacs or ewmEmacsPackage;
  };

  syscGreetPackage = inputs.sysc-greet.packages.${pkgs.stdenv.hostPlatform.system}.default;

  gslapperPackage = inputs.gslapper.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Second ewm session using plain emacs (programs.emacs from home/emacs/emacs.nix).
  # That package already includes ewmPackage via extraPackages.
  emacsPlainPackage = config.home-manager.users.${username}.programs.emacs.finalPackage;

  ewmEmacsLaunch = pkgs.writeShellScript "ewm-emacs-launch" ''
    exec ${emacsPlainPackage}/bin/emacs \
      --fg-daemon \
      --eval "(require 'ewm)" \
      --eval "(ewm-start-module)" \
      "$@"
  '';

  # Mirrors the upstream ewm-session script but targets ewm-emacs.service.
  ewmEmacsSession = pkgs.writeShellScript "ewm-emacs-session" ''
    if [ -n "$SHELL" ] &&
       grep -q "$SHELL" /etc/shells &&
       ! (echo "$SHELL" | grep -q "false") &&
       ! (echo "$SHELL" | grep -q "nologin"); then
      if [ "$1" != '-l' ]; then
        exec bash -c "exec -l '$SHELL' -c '$0 -l $*'"
      else
        shift
      fi
    fi

    if systemctl --user -q is-active ewm-emacs.service; then
      echo 'Stopping stale EWM (emacs) session...'
      systemctl --user stop ewm-emacs.service
    fi

    systemctl --user reset-failed
    systemctl --user import-environment

    if command -v dbus-update-activation-environment >/dev/null 2>&1; then
      dbus-update-activation-environment --all
    fi

    systemctl --user --wait start ewm-emacs.service
    systemctl --user start --job-mode=replace-irreversibly ewm-shutdown.target
    systemctl --user unset-environment WAYLAND_DISPLAY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP
  '';

  ewmEmacsDesktop = pkgs.writeText "ewm-emacs.desktop" ''
    [Desktop Entry]
    Name=ewm (emacs)
    Comment=Emacs Wayland Manager (plain emacs)
    Exec=ewm-emacs-session
    Type=Application
    DesktopNames=ewm
  '';

  # DesktopNames=ewm reuses the portal/XDG config already set up for the ewm session.
  ewmEmacsService = pkgs.writeText "ewm-emacs.service" ''
    [Unit]
    Description=Emacs Wayland Manager (plain emacs)
    Documentation=https://codeberg.org/ezemtsov/ewm
    BindsTo=graphical-session.target
    Before=graphical-session.target
    Wants=graphical-session-pre.target
    After=graphical-session-pre.target
    Wants=xdg-desktop-autostart.target
    Before=xdg-desktop-autostart.target

    [Service]
    Slice=session.slice
    Type=notify
    WorkingDirectory=%h
    ExecStart=/run/current-system/sw/bin/ewm-emacs-launch
  '';

  ewmEmacsSystemPackage =
    pkgs.runCommand "ewm-emacs-system"
      {
        passthru.providedSessions = [ "ewm-emacs" ];
      }
      ''
        install -Dm755 ${ewmEmacsLaunch} $out/bin/ewm-emacs-launch
        install -Dm755 ${ewmEmacsSession} $out/bin/ewm-emacs-session
        install -Dm644 ${ewmEmacsDesktop} $out/share/wayland-sessions/ewm-emacs.desktop
        install -Dm644 ${ewmEmacsService} $out/lib/systemd/user/ewm-emacs.service
      '';
in
{
  programs.dconf.enable = true;
  programs.xwayland.enable = true;

  # greetd with sysc-greet.
  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
    home = "/var/lib/greeter";
    createHome = true;
  };
  users.groups.greeter = { };

  services.greetd = {
    enable = true;
    settings = {
      terminal.vt = 1;
      default_session = {
        command = "${pkgs.hyprland}/bin/Hyprland -c /etc/greetd/hyprland-greeter-config.conf";
        user = "greeter";
      };
    };
  };

  environment.pathsToLink = [ "/share/wayland-sessions" ];
  environment.etc = {
    "greetd/kitty.conf".source = "${syscGreetPackage}/etc/greetd/kitty.conf";
    "greetd/hyprland-greeter-config.conf".source =
      "${syscGreetPackage}/etc/greetd/hyprland-greeter-config.conf";
    "greetd/sway-greeter-config".source = "${syscGreetPackage}/etc/greetd/sway-greeter-config";
    "greetd/cagebreak-greeter-config".source =
      "${syscGreetPackage}/etc/greetd/cagebreak-greeter-config";
    "polkit-1/rules.d/85-greeter.rules".source =
      "${syscGreetPackage}/etc/polkit-1/rules.d/85-greeter.rules";
  };

  systemd.tmpfiles.rules = [
    "d /var/cache/sysc-greet 0755 greeter greeter -"
    "L+ /usr/share/sysc-greet - - - - ${syscGreetPackage}/share/sysc-greet"
  ];

  security.polkit.enable = true;

  services.dbus.packages = [ pkgs.gcr ];

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  programs.uwsm = {
    enable = true;
  };
  programs.hyprland.withUWSM = true;

  programs.hyprland.enable = true;
  # Niri is temporarily disabled while its current package is incompatible
  # with the nixpkgs revision used by this configuration.

  # Primary ewm session: doom-emacs.
  programs.ewm = {
    enable = true;
    #extraEmacsArgs = "--debug-init  --eval \"(setq debug-on-error t)\"";
    #extraEmacsArgs = "-Q";
    emacsPackage = ewmEmacsPackage;
    ewmPackage = patchedEwmPackage;
  };

  # Second ewm session: plain emacs. Must be in environment.systemPackages so
  # share/wayland-sessions/ is linked into /run/current-system/sw/share/wayland-sessions/,
  # which is where sysc-greet scans for session desktop files.
  environment.systemPackages = [
    ewmEmacsSystemPackage
    syscGreetPackage
    pkgs.kitty
    gslapperPackage
    pkgs.xwayland-satellite
  ];
  services.displayManager.sessionPackages = [ ewmEmacsSystemPackage ];
  systemd.packages = [ ewmEmacsSystemPackage ];

  # EWM has on-demand xwayland-satellite integration: it looks for the binary at
  # startup, creates the X11 sockets itself, and propagates DISPLAY to children.
}
