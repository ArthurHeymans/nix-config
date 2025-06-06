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
    delta
    graphviz # DOT for org-roam
    mu
    isync
    clang-tools
    emacs-all-the-icons-fonts
    sshfs
    taplo # toml lsp
    guile
    fd
    nodejs_24
    ffmpeg # for encoding sound
    uv # for MCP server fetch
    # emacs-lsp-booster
  ];

  programs.doom-emacs = {
    enable = true;
    emacs = pkgs.emacs-pgtk;
    doomDir = inputs.doom-config;
    tangleArgs = ".";
  };
}
