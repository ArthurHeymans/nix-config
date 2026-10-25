{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  ement-e2ee = pkgs.rustPlatform.buildRustPackage {
    pname = "ement-e2ee";
    version = "0.19.1";
    src = inputs.ement-e2ee;

    cargoLock.lockFile = "${inputs.ement-e2ee}/Cargo.lock";

    # reqwest's native certificate loader also runs in the sandboxed tests.
    env.SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

    meta = {
      description = "Transparent E2EE proxy for ement.el";
      homepage = "https://github.com/bhw-foss/ement-e2ee";
      license = lib.licenses.gpl3Plus;
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
