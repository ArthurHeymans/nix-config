{
  config,
  pkgs,
  inputs,
  username,
  ...
}:
let
  ewmEmacsPackage = config.home-manager.users.${username}.programs.doom-emacs.finalEmacsPackage;

  libdisplayInfoRs = pkgs.fetchFromGitHub {
    owner = "ArthurHeymans";
    repo = "libdisplay-info-rs";
    rev = "3911e0344bb2db5839f2c646d25e8c2a8b5223d9";
    hash = "sha256-kjX8SSjZE5IKCoSklE3AVvv622Bb6Tjwu49AdMTky0U=";
  };

  ewmPatch = pkgs.writeText "ewm-libdisplay-info-rs-0.4.patch" (
    builtins.concatStringsSep "\n" [
      "diff --git a/nix/default.nix b/nix/default.nix"
      "index 4b6a078fba..72b2099db1 100644"
      "--- a/nix/default.nix"
      "+++ b/nix/default.nix"
      "@@ -8,6 +8,17 @@"
      "   inherit (pkgs) rustPlatform pkg-config;"
      "   inherit (pkgs) glib libdisplay-info libdrm libgbm libglvnd libinput libxkbcommon pipewire seatd systemd wayland;"
      " "
      "+  # Temporary crates.io patch until libdisplay-info-rs 0.4 is released and"
      "+  # Smithay accepts it. Keep the Cargo package versions at 0.3.0 so this also"
      "+  # satisfies Smithay's current `libdisplay-info = \"0.3\"` requirement, while"
      "+  # using the updated bindings and wrappers for the native 0.4 ABI."
      "+  libdisplay-info-rs = pkgs.fetchFromGitHub {"
      "+    owner = \"ArthurHeymans\";"
      "+    repo = \"libdisplay-info-rs\";"
      "+    rev = \"3911e0344bb2db5839f2c646d25e8c2a8b5223d9\";"
      "+    hash = \"sha256-kjX8SSjZE5IKCoSklE3AVvv622Bb6Tjwu49AdMTky0U=\";"
      "+  };"
      "+"
      "   gitTrackedFiles = lib.fileset.gitTracked ./..;"
      " "
      "   # Rust compositor core - only rebuilds when compositor/ changes"
      "@@ -29,6 +40,25 @@"
      " "
      "     strictDeps = true;"
      " "
      "+    postPatch = ''"
      "+      cp -r \${libdisplay-info-rs} .nix-libdisplay-info-rs"
      "+      chmod -R u+w .nix-libdisplay-info-rs"
      "+"
      "+      # Cargo patches must satisfy the existing 0.3 requirements. The fork is"
      "+      # source-compatible but was versioned 0.4 for its eventual release."
      "+      substituteInPlace \\"
      "+        .nix-libdisplay-info-rs/libdisplay-info/Cargo.toml \\"
      "+        .nix-libdisplay-info-rs/libdisplay-info-sys/Cargo.toml \\"
      "+        --replace-fail 'version = \"0.4.0\"' 'version = \"0.3.0\"'"
      "+"
      "+      cat >> Cargo.toml <<'EOF'"
      "+"
      "+      [patch.crates-io]"
      "+      libdisplay-info = { path = \".nix-libdisplay-info-rs/libdisplay-info\" }"
      "+      libdisplay-info-sys = { path = \".nix-libdisplay-info-rs/libdisplay-info-sys\" }"
      "+      EOF"
      "+    '';"
      "+"
      "     nativeBuildInputs = ["
      "       pkg-config"
      "       rustPlatform.bindgenHook"
    ]
  );

  # Patch the online EWM flake source in Nix so its Rust build uses the
  # libdisplay-info-rs fork that supports native libdisplay-info 0.4.
  patchedEwmSource = pkgs.applyPatches {
    name = "ewm-patched-source";
    src = inputs.ewm;
    patches = [ ewmPatch ];
  };
  patchedEwmPackage = pkgs.callPackage "${patchedEwmSource}/nix/default.nix" {
    emacsPackage = ewmEmacsPackage.emacs or ewmEmacsPackage;
  };

  patchedNiriPackage =
    inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable.overrideAttrs
      (old: {
        postPatch = (old.postPatch or "") + ''
          cp -r ${libdisplayInfoRs} .nix-libdisplay-info-rs
          chmod -R u+w .nix-libdisplay-info-rs

          substituteInPlace \
            .nix-libdisplay-info-rs/libdisplay-info/Cargo.toml \
            .nix-libdisplay-info-rs/libdisplay-info-sys/Cargo.toml \
            --replace-fail 'version = "0.4.0"' 'version = "0.3.0"'

          cat >> Cargo.toml <<'EOF'

          [patch.crates-io]
          libdisplay-info = { path = ".nix-libdisplay-info-rs/libdisplay-info" }
          libdisplay-info-sys = { path = ".nix-libdisplay-info-rs/libdisplay-info-sys" }
          EOF
        '';
      });

  patchedSyscGreetPackage =
    inputs.sysc-greet.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
      (old: {
        # Replacing a store path in a Nix string does not remove its dependency
        # context, so discard the old context and explicitly restore only the
        # packages referenced by the rewritten install script.
        postInstall =
          builtins.unsafeDiscardStringContext (
            builtins.replaceStrings
              [ "${pkgs.niri}/bin/niri msg" ]
              [ "${patchedNiriPackage}/bin/niri msg" ]
              old.postInstall
          )
          + ''
            # Keep these paths in the derivation closure and build sandbox.
            : ${patchedNiriPackage} ${pkgs.kitty} ${pkgs.hyprland} ${pkgs.sway} ${pkgs.socat}
          '';
      });

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

  # greetd with sysc-greet. This is configured directly because the upstream
  # module closes over an unpatched pkgs.niri in its sysc-greet package.
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
        command = "${patchedNiriPackage}/bin/niri -c /etc/greetd/niri-greeter-config.kdl";
        user = "greeter";
      };
    };
  };

  environment.pathsToLink = [ "/share/wayland-sessions" ];
  environment.etc = {
    "greetd/kitty.conf".source = "${patchedSyscGreetPackage}/etc/greetd/kitty.conf";
    "greetd/niri-greeter-config.kdl".source = "${patchedSyscGreetPackage}/etc/greetd/niri-greeter-config.kdl";
    "greetd/hyprland-greeter-config.conf".source = "${patchedSyscGreetPackage}/etc/greetd/hyprland-greeter-config.conf";
    "greetd/sway-greeter-config".source = "${patchedSyscGreetPackage}/etc/greetd/sway-greeter-config";
    "greetd/cagebreak-greeter-config".source = "${patchedSyscGreetPackage}/etc/greetd/cagebreak-greeter-config";
    "polkit-1/rules.d/85-greeter.rules".source = "${patchedSyscGreetPackage}/etc/polkit-1/rules.d/85-greeter.rules";
  };

  systemd.tmpfiles.rules = [
    "d /var/cache/sysc-greet 0755 greeter greeter -"
    "L+ /usr/share/sysc-greet - - - - ${patchedSyscGreetPackage}/share/sysc-greet"
  ];

  security.polkit.enable = true;

  services.dbus.packages = [ pkgs.gcr ];

  programs.sway.enable = true;

  programs.uwsm = {
    enable = true;
  };
  programs.hyprland.withUWSM = true;

  programs.hyprland.enable = true;
  programs.niri.enable = true;
  programs.niri.package = patchedNiriPackage; # recent-windows requires 25.11+

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
    patchedSyscGreetPackage
    pkgs.kitty
    gslapperPackage
    pkgs.xwayland-satellite
  ];
  services.displayManager.sessionPackages = [ ewmEmacsSystemPackage ];
  systemd.packages = [ ewmEmacsSystemPackage ];

  # EWM has on-demand xwayland-satellite integration: it looks for the binary at
  # startup, creates the X11 sockets itself, and propagates DISPLAY to children.
}
