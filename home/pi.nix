{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  agentDir = "${config.home.homeDirectory}/.pi/agent";
  defaults = builtins.fromJSON (builtins.readFile ./pi/settings.json);
  settings = pkgs.writeText "pi-settings.json" (
    builtins.toJSON (
      defaults
      // {
        packages = defaults.packages ++ [ "${inputs.slop-statistics-src}" ];
      }
    )
  );
  configurePi = pkgs.writeShellApplication {
    name = "configure-pi";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      settings_dir="$HOME/.pi/agent"
      mkdir -p "$settings_dir"

      reconcile() {
        local name="$1" defaults="$2" existing="$settings_dir/$1"
        if [ ! -e "$existing" ]; then
          existing="$defaults"
        fi
        temporary="$(mktemp "$settings_dir/.$name.XXXXXX")"
        trap 'rm -f "$temporary"' EXIT
        jq -e --slurpfile defaults "$defaults" \
          'if type == "object" then . * $defaults[0] else error("Expected a config object") end' \
          "$existing" > "$temporary"
        chmod 600 "$temporary"
        mv "$temporary" "$settings_dir/$name"
      }

      reconcile settings.json ${settings}
      reconcile models.json ${./pi/models.json}
      reconcile web-search.json ${./pi/web-search.json}
    '';
  };
in
{
  # Keep extension configuration in the same directory as Pi, even when XDG
  # variables or legacy ~/.pi configuration would select another location.
  home.sessionVariables.PI_CODING_AGENT_DIR = agentDir;
  systemd.user.sessionVariables.PI_CODING_AGENT_DIR = agentDir;

  home.file =
    lib.mapAttrs'
      (
        name: source:
        lib.nameValuePair ".pi/agent/${name}" {
          inherit source;
          recursive = true;
        }
      )
      {
        "AGENTS.md" = ./pi/AGENTS.md;
        "agents" = ./pi/agents;
        "extensions" = ./pi/extensions;
        "extensions-disabled" = ./pi/extensions-disabled;
        "skills" = ./pi/skills;
        "pi-extensible-workflows/roles" = ./pi/pi-extensible-workflows/roles;
      };

  # Pi and its extensions write configuration back to these files. Reconcile
  # declared values while preserving undeclared preferences and runtime metadata.
  # Credentials, sessions, trust, catalog caches, and workflow state stay unmanaged.
  home.activation.configurePi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe configurePi}
  '';
}
