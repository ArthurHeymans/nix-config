{
  pkgs,
  config,
  llm-agents,
  ...
}:
let
  opencode = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
  pi = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;
in
{
  home.packages = with pkgs; [
    opencode
    pi
    jq # often used for parsing nixos output in AI agents
  ];

  systemd.user.services.opencode-server = {
    Unit = {
      Description = "OpenCode headless HTTP server";
      After = [ "default.target" ];
    };
    Service = {
      ExecStart = toString (
        pkgs.writeShellScript "opencode-serve" ''
          export OPENCODE_SERVER_PASSWORD=$(cat ${
            config.sops.secrets."environmentVariables/OPENCODE_SERVER_PASSWORD".path
          })
          exec ${opencode}/bin/opencode serve --hostname 0.0.0.0 --port 4096
        ''
      );
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
