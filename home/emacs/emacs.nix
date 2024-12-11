{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    ispell
    aspell
    aspellDicts.nl
    aspellDicts.fr
    aspellDicts.en
    hunspell
    hunspellDicts.nl_nl
    hunspellDicts.en-us
    hunspellDicts.fr-any
    graphviz # DOT for org-roam
    mu
    isync
    clang-tools
    emacs-all-the-icons-fonts
    sshfs
    guile
  ];

  programs.doom-emacs = {
    enable = true;
    emacs = pkgs.emacs29-pgtk;
    doomDir = inputs.doom-config;
    tangleArgs = ".";
  };
}
