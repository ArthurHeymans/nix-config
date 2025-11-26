{
  config,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    fzf
    grc
    just
    bat
    ripgrep
    nmap
    screen
    yazi
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

      alias ls='eza --icons=auto'
      setenv OPENAI_API_KEY $(cat ${config.sops.secrets."environmentVariables/OPENAI_API_KEY".path})
      setenv OPENROUTER_API_KEY $(cat ${
        config.sops.secrets."environmentVariables/OPENROUTER_API_KEY".path
      })
      setenv DEEPSEEK_API_KEY $(cat ${config.sops.secrets."environmentVariables/DEEPSEEK_API_KEY".path})
      setenv ANTHROPIC_API_KEY $(cat ${config.sops.secrets."environmentVariables/ANTHROPIC_API_KEY".path})
      setenv ANTHROPIC_API_KEY_9E $(cat ${config.sops.secrets."environmentVariables/ANTHROPIC_API_KEY_9E".path})
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
  };
}
