{
  inputs,
  pkgs,
  ...
}:
let
  caddyAddress = "192.168.0.9";
  piWebPort = 8504;
  piWebPackage = pkgs.callPackage ../packages/pi-web.nix {
    src = inputs.pi-web;
  };
  piWebConfig = pkgs.writeText "pi-web-config.json" (
    builtins.toJSON {
      host = "0.0.0.0";
      port = piWebPort;
      spawnSessions = true;
      subsessions = true;
      askUser = true;
      pathAccess.allowedPaths = [ "/home/arthur/src" ];
    }
  );
  servicePackages = [
    piWebPackage
    pkgs.bash
    pkgs.coreutils
    pkgs.findutils
    pkgs.git
    pkgs.jq
    pkgs.jujutsu
    pkgs.openssh
    pkgs.ripgrep
  ];
  serviceEnvironment = {
    HOME = "/home/arthur";
    PI_WEB_CONFIG = piWebConfig;
    PI_WEB_DATA_DIR = "/home/arthur/.pi-web";
    PI_WEB_SESSIOND_SOCKET = "/home/arthur/.pi-web/sessiond.sock";
  };
in
{
  systemd.tmpfiles.rules = [
    "d /home/arthur/src 0750 arthur users - -"
    "d /home/arthur/.pi-web 0700 arthur users - -"
  ];

  networking.firewall.extraInputRules = ''
    ip saddr ${caddyAddress} tcp dport ${toString piWebPort} accept
  '';

  environment.systemPackages = [ piWebPackage ];

  systemd.services.pi-web-sessiond = {
    description = "PI WEB session daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    environment = serviceEnvironment;
    path = servicePackages;
    serviceConfig = {
      User = "arthur";
      Group = "users";
      WorkingDirectory = "/home/arthur/src";
      ExecStart = "${piWebPackage}/bin/pi-web-sessiond";
      Restart = "on-failure";
      RestartSec = 2;
      UMask = "0077";
    };
  };

  systemd.services.pi-web = {
    description = "PI WEB web and API server";
    wantedBy = [ "multi-user.target" ];
    after = [ "pi-web-sessiond.service" ];
    wants = [ "pi-web-sessiond.service" ];
    environment = serviceEnvironment;
    path = servicePackages;
    serviceConfig = {
      User = "arthur";
      Group = "users";
      WorkingDirectory = "/home/arthur/src";
      ExecStart = "${piWebPackage}/bin/pi-web-server";
      Restart = "on-failure";
      RestartSec = 2;
      UMask = "0077";
    };
  };

}
