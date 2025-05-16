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
  services.udev.packages = [ probe-rs-udev-rules ];

  # WCH Link rules are included in the probe-rs rules file
  # so we don't need the extraRules anymore
}
