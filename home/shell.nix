{
  config,
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

    socket_name="''${EMACS_SOCKET_NAME:-}"
    runtime_dir="''${XDG_RUNTIME_DIR:-}"

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

    args=(--alternate-editor=false)
    if [[ -n "$socket_name" ]]; then
      args=(--socket-name "$socket_name" "''${args[@]}")
    fi

    exec ${pkgs.emacs-pgtk}/bin/emacsclient "''${args[@]}" "$@"
  '';
in
{
  home.sessionVariables = {
    EDITOR = "ewm-editor";
    VISUAL = "ewm-editor";
  };

  home.packages = with pkgs; [
    ewm-editor
    fzf
    grc
    just
    bat
    ripgrep
    nmap
    screen
    yazi
    github-cli
    file
  ];

  home.shell = {
    enableFishIntegration = true;
    enableBashIntegration = true;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      if test "$TERM" = "dumb"
        exec sh
      end

      # Ghostel terminal emulator shell integration
      test "$INSIDE_EMACS" = 'ghostel'; and source ${ghostel-shell-integration}/etc/ghostel.fish

      source ${osConfig.programs.ewm.ewmPackage}/etc/emacs-ewm.fish

      set -gx EDITOR ewm-editor
      set -gx VISUAL ewm-editor

      alias ls='eza --icons=auto'
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
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      } # colorized command output
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      } # fuzzy finding
      {
        name = "forgit";
        src = pkgs.fishPlugins.forgit.src;
      } # fuzzy git
      {
        name = "hydro";
        src = pkgs.fishPlugins.hydro.src;
      } # info about git
    ];
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    initExtra = ''

      # Ghostel terminal emulator shell integration
      [[ "$INSIDE_EMACS" = 'ghostel' ]] && source ${ghostel-shell-integration}/etc/ghostel.bash

      source ${osConfig.programs.ewm.ewmPackage}/etc/emacs-ewm.bash

      export EDITOR=ewm-editor
      export VISUAL=ewm-editor
    '';
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      #format = "$shlvl$shell$username$hostname$nix_shell$git_branch$git_commit$git_state$git_status$directory$jobs$cmd_duration$character";
      add_newline = false;

      line_break.disabled = true;
      nix_shell = {
        symbol = "❄ ";
      };
      directory = {
        truncation_length = 0;
        truncate_to_repo = true;
      };
      time = {
        time_format = "%T";
        format = "🕙 $time($style) ";
        style = "bright-white";
        disabled = false;
      };
    };
  };

  # Easy shell environments
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = true;
    #enableFishIntegration = true;
  };

  # zoxide
  programs.zoxide.enable = true;
  programs.zoxide.enableBashIntegration = true;
  programs.zoxide.enableFishIntegration = true;
  programs.zoxide.options = [
    "--cmd cd"
  ];

  programs.atuin = {
    enable = true;
    flags = [ "--disable-up-arrow" ];
  };
}
