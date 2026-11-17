{ pkgs }:
let
  inherit (pkgs) fetchurl stdenvNoCC;
  upstreamBinary =
    {
      pname,
      version,
      url,
      sha256,
      binary,
      patchElf ? false,
    }:
    stdenvNoCC.mkDerivation {
      inherit pname version;
      src = fetchurl { inherit url sha256; };
      sourceRoot = ".";
      nativeBuildInputs = pkgs.lib.optional patchElf pkgs.autoPatchelfHook;
      buildInputs = pkgs.lib.optional patchElf pkgs.glibc;
      dontBuild = true;
      installPhase = ''
        runHook preInstall
        install -Dm755 $(find . -type f -name '${binary}' -print -quit) "$out/bin/${binary}"
        runHook postInstall
      '';
      meta.platforms = [ "x86_64-linux" ];
    };
  proxy = upstreamBinary rec {
    pname = "cli-proxy-api";
    version = "8.0.79";
    binary = pname;
    url = "https://github.com/router-for-me/CLIProxyAPI/releases/download/v${version}/CLIProxyAPI_${version}_linux_amd64_no-plugin.tar.gz";
    sha256 = "969c696764143d2b373cd1b1150f67919e257ed67faceef15ac6571ffb67d455";
  };
  keeper = upstreamBinary rec {
    pname = "cpa-usage-keeper";
    version = "2.1.1";
    binary = pname;
    patchElf = true;
    url = "https://github.com/Willxup/cpa-usage-keeper/releases/download/v${version}/cpa-usage-keeper_v${version}_linux_amd64.tar.gz";
    sha256 = "c53bb8a25eff741f022097bad394e68b186fad3446396948c263953199df1c8b";
  };
  gateway = pkgs.writeText "t3-router.Caddyfile" ''
    {
      admin off
    }
    :8318 {
      bind 127.0.0.1
      @inference path /v1/models /v1/messages /v1/messages/count_tokens /v1/responses /v1/chat/completions
      route {
        reverse_proxy @inference 127.0.0.1:8317
        respond 404
      }
    }
  '';
  sandbox = {
    NoNewPrivileges = true;
    PrivateTmp = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    UMask = "0077";
    Restart = "on-failure";
    RestartSec = "5s";
  };
in
{
  packages = { inherit proxy keeper; };
  services = {
    t3-router = {
      description = "T3 Code subscription and API router";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        HOME = "/var/lib/t3-router";
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      };
      serviceConfig = sandbox // {
        User = "t3-router";
        StateDirectory = "t3-router";
        StateDirectoryMode = "0700";
        WorkingDirectory = "/var/lib/t3-router";
        ExecStart = "${proxy}/bin/cli-proxy-api -config /var/lib/t3-router/config.json";
      };
      unitConfig.ConditionPathExists = "/var/lib/t3-router/config.json";
    };
    t3-router-ingress = {
      description = "Expose only inference routes from the private T3 Code router";
      after = [ "t3-router.service" ];
      wants = [ "t3-router.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = sandbox // {
        DynamicUser = true;
        ExecStart = "${pkgs.caddy}/bin/caddy run --config ${gateway} --adapter caddyfile";
      };
    };
    t3-router-usage = {
      description = "T3 Code router usage dashboard";
      after = [ "t3-router.service" ];
      wants = [ "t3-router.service" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        APP_HOST = "127.0.0.1";
        APP_PORT = "8319";
        CPA_BASE_URL = "http://127.0.0.1:8317";
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      };
      serviceConfig = sandbox // {
        DynamicUser = true;
        StateDirectory = "t3-router-usage";
        StateDirectoryMode = "0700";
        WorkingDirectory = "/var/lib/t3-router-usage";
        EnvironmentFile = "/etc/t3-router/usage.env";
        ExecStart = "${keeper}/bin/cpa-usage-keeper";
      };
      unitConfig.ConditionPathExists = "/etc/t3-router/usage.env";
    };
  };
}
