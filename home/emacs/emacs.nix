{
  pkgs,
  inputs,
  ...
}: {
  home.file.".config/eca/config.json".source = ./eca-config.json;
  home.packages = with pkgs; [
    alsa-utils # emacs sound broken
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
    hugo
    mu
    isync
    clang-tools
    emacs-all-the-icons-fonts
    sshfs
    taplo # toml lsp
    guile
    fd
    nodejs
    ffmpeg # for encoding sound
    uv # for MCP server fetch
    unzip
    # emacs-lsp-booster
  ];

  programs.doom-emacs = {
    enable = true;
    emacs = pkgs.emacs-pgtk;
    doomDir = inputs.doom-config;
    tangleArgs = ".";
    provideEmacs = false;
  };

  xdg.desktopEntries.doom-emacs = {
    name = "Doom Emacs";
    comment = "Edit text with Doom Emacs";
    exec = "doom-emacs %F";
    icon = ./gnarly.png;
    categories = [ "Development" "TextEditor" ];
    mimeType = [ "text/english" "text/plain" "text/x-makefile" "text/x-c++hdr" "text/x-c++src" "text/x-chdr" "text/x-csrc" "text/x-java" "text/x-moc" "text/x-pascal" "text/x-tcl" "text/x-tex" "application/x-shellscript" "text/x-c" "text/x-c++" ];
  };

  # separate emacs for toying around with doom without nix in the mix
  programs.emacs= {
    enable = true;
    package = pkgs.emacs-pgtk;
    extraPackages = epkgs: [
      (epkgs.treesit-grammars.with-grammars (grammars: with grammars; [
          tree-sitter-bash
          tree-sitter-nix
          tree-sitter-rust
          tree-sitter-kdl
        ]))
      epkgs.mu4e
    ];
  };
}
