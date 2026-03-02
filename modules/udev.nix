{ pkgs, lib, ... }:

let
  probe-rs-udev-rules = pkgs.stdenv.mkDerivation {
    pname = "probe-rs-udev-rules";
    version = "latest";

    src = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/probe-rs/webpage/dc2ab9668cd2a01ac0c4cd86e84bc5bde512007e/public/files/69-probe-rs.rules";
      hash = "sha256-yjxld5ebm2jpfyzkw+vngBfHu5Nfh2ioLUKQQDY4KYo=";
    };

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -D $src $out/lib/udev/rules.d/69-probe-rs.rules
      runHook postInstall
    '';

    meta = with lib; {
      homepage = "https://probe.rs/docs/getting-started/probe-setup/#udev-rules";
      description = "Probe-rs udev rules for various debug probes including Picoprobe";
      platforms = platforms.linux;
      license = licenses.gpl2Only;
    };
  };
in
{
  services.udev.packages = [
    probe-rs-udev-rules
  ]
  ++ (with pkgs; [
    qmk
    qmk-udev-rules # the only relevant
    qmk_hid
    via
    vial
  ]);

  # WCH Link rules are included in the probe-rs rules file
  # so we don't need the extraRules anymore

  # EM100 programmer rules + ch341a
  services.udev.extraRules = ''
    # EM100
    SUBSYSTEM=="usb", ATTR{idVendor}=="04b4", ATTR{idProduct}=="1235", MODE="0666", TAG+="uaccess"
    # CH341A
    SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="5512", MODE="0666", TAG+="uaccess"
    # CH347T
    SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="55db", MODE="0666", TAG+="uaccess"
    # CH347F
    SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="55de", MODE="0666", TAG+="uaccess"
    # FT4222
    SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="601c", MODE="0666", TAG+="uaccess"
    # Dediprog SF100/SF200/SF600/SF700 (VID:0483 PID:dada)
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="dada", MODE="0666", TAG+="uaccess"
    # 1f3a:efe8 Allwinner Technology sunxi SoC OTG connector in FEL/flashing mode
    SUBSYSTEM=="usb", ATTR{idVendor}=="1f3a", ATTR{idProduct}=="efe8", MODE="0666", TAG+="uaccess"
  '';
}
