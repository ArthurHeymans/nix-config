{
  pkgs,
  src,
  withScreencastSupport ? true,
  emacsPackage ? pkgs.emacs-pgtk,
}:
let
  inherit (pkgs) lib;
  inherit (pkgs) rustPlatform pkg-config;
  inherit (pkgs)
    glib
    libdisplay-info
    libdrm
    libgbm
    libglvnd
    libinput
    libxkbcommon
    pipewire
    seatd
    systemd
    wayland
    ;

  libdisplayInfoRs = pkgs.fetchFromGitHub {
    owner = "ArthurHeymans";
    repo = "libdisplay-info-rs";
    rev = "3911e0344bb2db5839f2c646d25e8c2a8b5223d9";
    hash = "sha256-kjX8SSjZE5IKCoSklE3AVvv622Bb6Tjwu49AdMTky0U=";
  };

  ewmCore = rustPlatform.buildRustPackage {
    pname = "ewm-core";
    version = "0.1.0";
    inherit src;
    sourceRoot = "source/compositor";

    cargoLock = {
      lockFile = "${src}/compositor/Cargo.lock";
      outputHashes = {
        "smithay-0.7.0" = "sha256-TV/GTfSvgfVwIFUGoASU7xm38opIBLjLMf1HeNTW07U=";
      };
    };

    strictDeps = true;

    nativeBuildInputs = [
      pkg-config
      rustPlatform.bindgenHook
    ];

    buildInputs = [
      glib
      libdisplay-info
      libdrm
      libgbm
      libglvnd
      libinput
      libxkbcommon
      seatd
      systemd
      wayland
    ]
    ++ lib.optional withScreencastSupport pipewire;

    buildFeatures = lib.optional withScreencastSupport "screencast";
    buildNoDefaultFeatures = true;

    env.RUSTFLAGS = toString (
      map (arg: "-C link-arg=" + arg) [
        "-Wl,--push-state,--no-as-needed"
        "-lEGL"
        "-lwayland-client"
        "-Wl,--pop-state"
      ]
    );

    # The EWM sources currently use libdisplay-info-rs 0.3 while nixpkgs
    # supplies libdisplay-info 0.4.  Vendor compatible 0.4 bindings under
    # the 0.3 Cargo version until the upstream crate catches up.
    postPatch = ''
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

    postInstall = ''
      mkdir -p $out/share/emacs/site-lisp
      ln -s $out/lib/libewm_core.so $out/share/emacs/site-lisp/ewm-core.so
    '';

    doCheck = false;
  };
in
emacsPackage.pkgs.trivialBuild {
  pname = "ewm";
  version = "0.1.0";
  src = "${src}/lisp";
  packageRequires = [ ewmCore ];
  postInstall = ''
    cp -r ${src}/etc $out/etc
  '';

  meta = {
    description = "Emacs Wayland Manager - Wayland compositor for Emacs";
    homepage = "https://codeberg.org/ezemtsov/ewm";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "ewm-emacs";
  };
}
