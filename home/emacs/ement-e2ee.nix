{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  ement-e2ee = pkgs.rustPlatform.buildRustPackage {
    pname = "ement-e2ee";
    version = "0.1.0";
    src = inputs.ement-e2ee;

    cargoLock = {
      lockFile = "${inputs.ement-e2ee}/Cargo.lock";
      outputHashes = {
        "matrix-sdk-crypto-0.18.0" = "sha256-1+M5H5eoGLQXglHSp0rP1QioNJDRa6AiM0koWdvp5Do=";
        "ruma-0.16.0" = "sha256-Ce1A7NHaYlSm2B0IF1YX2ZgLkNWhyigMFOdO9Ho6U1I=";
      };
    };

    meta = {
      description = "Transparent E2EE proxy for ement.el";
      homepage = "https://github.com/bhw-foss/ement-e2ee";
      license = lib.licenses.asl20;
      mainProgram = "ement-e2ee";
    };
  };
  homeserver = "https://matrix.org";
in
{
  home.packages = [ ement-e2ee ];

  home.file.".config/ement-e2ee/config.toml".text = ''
    # Change this if your Matrix account uses another homeserver.
    listen = "127.0.0.1:8009"
    homeserver = "${homeserver}"
    log_level = "info"
  '';

  systemd.user.services.ement-e2ee = {
    Unit = {
      Description = "Transparent E2EE proxy for ement.el";
      After = [ "network-online.target" ];
    };
    Service = {
      ExecStart = "${ement-e2ee}/bin/ement-e2ee serve";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
