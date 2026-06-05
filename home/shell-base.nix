{pkgs, ...}: {
  home.packages = with pkgs; [
    bat
    file
    fzf
    github-cli
    grc
    just
    nmap
    screen
    yazi
  ];

  home.shell = {
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      if test "$TERM" = "dumb"
        exec sh
      end

      alias ls='eza --icons=auto'
    '';
    plugins = [
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
      {
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      }
      {
        name = "hydro";
        src = pkgs.fishPlugins.hydro.src;
      }
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
      add_newline = false;
      directory = {
        truncate_to_repo = true;
        truncation_length = 0;
      };
      line_break.disabled = true;
      nix_shell.symbol = "❄ ";
      time = {
        disabled = false;
        format = "🕙 $time($style) ";
        style = "bright-white";
        time_format = "%T";
      };
    };
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    options = ["--cmd cd"];
  };

  programs.atuin = {
    enable = true;
    flags = ["--disable-up-arrow"];
  };
}
