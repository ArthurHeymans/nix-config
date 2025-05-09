{ pkgs, lib, ... }:

let
  probe-rs-udev-rules = pkgs.stdenv.mkDerivation {
    pname = "probe-rs-udev-rules";
    version = "latest";

    src = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/probe-rs/webpage/518a021690d70f7f740b82fa21a248773d923958/public/files/69-probe-rs.rules";
      hash = "sha256-OBwijJoCg5LrrAcFDekvS69NhVMY5AmSpHi/fPYXNqo=";
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
