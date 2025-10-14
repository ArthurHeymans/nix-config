{
  pkgs,
  inputs,
  ...
}:
{
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
    extraPackages = epkgs: [
      epkgs.treesit-grammars.with-all-grammars
      epkgs.mu4e
      (epkgs.melpaBuild {
        pname = "agent-shell";
        version = "9999snapshot1";
        packageRequires = [
          epkgs.shell-maker
          (epkgs.melpaBuild {
            pname = "acp";
            version = "9999snapshot1";
            src = builtins.fetchTree {
              type = "github";
              owner = "xenodium";
              repo = "acp.el";
              rev = "041b32f515fd21b0f241c4f2568de15c52378de2";
            };
          })
        ];
        src = builtins.fetchTree {
          type = "github";
          owner = "xenodium";
          repo = "agent-shell";
          rev = "134fd61bc8f6692ca4d2ea917e9616b2f8758461";
        };
      })
    ];
  };

  xdg.desktopEntries.doom-emacs = {
    name = "Doom Emacs";
    comment = "Edit text with Doom Emacs";
    exec = "doom-emacs %F";
    icon = ./gnarly.png;
    categories = [
      "Development"
      "TextEditor"
    ];
    mimeType = [
      "text/english"
      "text/plain"
      "text/x-makefile"
      "text/x-c++hdr"
      "text/x-c++src"
      "text/x-chdr"
      "text/x-csrc"
      "text/x-java"
      "text/x-moc"
      "text/x-pascal"
      "text/x-tcl"
      "text/x-tex"
      "application/x-shellscript"
      "text/x-c"
      "text/x-c++"
    ];
  };

  # separate emacs for toying around with doom without nix in the mix
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;
    extraPackages = epkgs: [
      epkgs.treesit-grammars.with-all-grammars
      epkgs.mu4e
    ];
  };
}
