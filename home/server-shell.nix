{ ... }: {
  imports = [
    ./shell-base.nix
  ];

  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };

  programs.bash.initExtra = ''
    export EDITOR=vim
    export VISUAL=vim
  '';
}
