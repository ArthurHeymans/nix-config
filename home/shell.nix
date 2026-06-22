{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  ghostel-shell-integration = pkgs.runCommand "ghostel-shell-integration" { } ''
    install -Dm444 ${pkgs.emacsPackages.ghostel.src}/etc/shell/ghostel.bash $out/etc/ghostel.bash
    install -Dm444 ${pkgs.emacsPackages.ghostel.src}/etc/shell/ghostel.fish $out/etc/ghostel.fish
  '';

  ewm-editor = pkgs.writeShellScriptBin "ewm-editor" ''
    set -euo pipefail

    fallback_editor="''${EWM_EDITOR_FALLBACK:-${pkgs.vim}/bin/vim}"
    socket_name="''${EMACS_SOCKET_NAME:-}"
    runtime_dir="''${XDG_RUNTIME_DIR:-}"

    fallback() {
      if [[ "$fallback_editor" == "ewm-editor" ]]; then
        fallback_editor=${pkgs.vim}/bin/vim
      fi
      exec $fallback_editor "$@"
    }

    if [[ -n "$socket_name" ]]; then
      if [[ "$socket_name" == /* ]]; then
        [[ -S "$socket_name" ]] || socket_name=""
      elif [[ -n "$runtime_dir" ]]; then
        [[ -S "$runtime_dir/emacs/$socket_name" ]] || socket_name=""
      fi
    fi

    if [[ -z "$socket_name" && -n "$runtime_dir" ]]; then
      for candidate in server ewm vt2; do
        if [[ -S "$runtime_dir/emacs/$candidate" ]]; then
          socket_name="$candidate"
          break
        fi
      done

      if [[ -z "$socket_name" ]]; then
        first_socket=$(find "$runtime_dir/emacs" -maxdepth 1 -type s -printf '%f\n' 2>/dev/null | head -n1 || true)
        socket_name="$first_socket"
      fi
    fi

    if [[ -z "$socket_name" ]]; then
      fallback "$@"
    fi

    args=(--alternate-editor=false --socket-name "$socket_name")
    exec ${pkgs.emacs-pgtk}/bin/emacsclient "''${args[@]}" "$@"
  '';
in
{
  imports = [
    ./shell-base.nix
  ];

  home.sessionVariables = {
    EDITOR = "ewm-editor";
    VISUAL = "ewm-editor";
  };

  home.packages = [ ewm-editor ];

  programs.fish = {
    interactiveShellInit = lib.mkAfter ''
      # Ghostel terminal emulator shell integration
      test "$INSIDE_EMACS" = 'ghostel'; and source ${ghostel-shell-integration}/etc/ghostel.fish

      source ${osConfig.programs.ewm.ewmPackage}/etc/emacs-ewm.fish

      set -gx EDITOR ewm-editor
      set -gx VISUAL ewm-editor

      setenv OPENAI_API_KEY $(cat ${config.sops.secrets."environmentVariables/OPENAI_API_KEY".path})
      setenv OPENROUTER_API_KEY $(cat ${
        config.sops.secrets."environmentVariables/OPENROUTER_API_KEY".path
      })
      setenv DEEPSEEK_API_KEY $(cat ${config.sops.secrets."environmentVariables/DEEPSEEK_API_KEY".path})
      setenv ANTHROPIC_API_KEY $(cat ${config.sops.secrets."environmentVariables/ANTHROPIC_API_KEY".path})
      setenv ANTHROPIC_API_KEY_9E $(cat ${
        config.sops.secrets."environmentVariables/ANTHROPIC_API_KEY_9E".path
      })
      setenv GOOGLE_API_KEY $(cat ${config.sops.secrets."environmentVariables/GOOGLE_API_KEY".path})
    '';
    plugins = [
      {
        name = "forgit";
        src = pkgs.fishPlugins.forgit.src;
      }
    ];
  };

  programs.bash.initExtra = ''
    # Ghostel terminal emulator shell integration
    [[ "$INSIDE_EMACS" = 'ghostel' ]] && source ${ghostel-shell-integration}/etc/ghostel.bash

    source ${osConfig.programs.ewm.ewmPackage}/etc/emacs-ewm.bash

    export EDITOR=ewm-editor
    export VISUAL=ewm-editor
  '';
}
