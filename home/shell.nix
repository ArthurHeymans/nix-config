{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    fzf
    grc
  ];

  programs.fish = {
    enable = true;
    interactiveShellInit = ''alias ls='eza --icons=auto'
        '';
    plugins = [
      { name = "grc"; src = pkgs.fishPlugins.grc.src; } # colorized command output
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; } # fuzzy finding
      { name = "forgit"; src = pkgs.fishPlugins.forgit.src; } # fuzzy git
      { name = "hydro"; src = pkgs.fishPlugins.hydro.src; } # info about git
    ];
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      #format = "$shlvl$shell$username$hostname$nix_shell$git_branch$git_commit$git_state$git_status$directory$jobs$cmd_duration$character";
      add_newline = false;

      line_break.disabled = true;
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
}