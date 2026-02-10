{
  pkgs,
  inputs,
  emacs-skia-src,
  ...
}:
let
  ecaConfig = import ./eca-config.nix;
  ecaConfigJson =
    pkgs.runCommand "eca-config.json"
      {
        nativeBuildInputs = [ pkgs.jq ];
      }
      ''
        echo '${builtins.toJSON ecaConfig}' | ${pkgs.jq}/bin/jq '.' > $out
      '';
  tree-sitter-ron = pkgs.tree-sitter.buildGrammar {
    language = "ron";
    version = "0.2.0";
    src = pkgs.fetchFromGitHub {
      owner = "tree-sitter-grammars";
      repo = "tree-sitter-ron";
      rev = "78938553b93075e638035f624973083451b29055";
      hash = "sha256-Sp0g6AWKHNjyUmL5k3RIU+5KtfICfg3o/DH77XRRyI0=";
    };
  };
  emacs-skia =
    (pkgs.emacs-pgtk.override {
      withTreeSitter = true;
      srcRepo = true;
    }).overrideAttrs
      (oldAttrs: {
        pname = "emacs-skia";
        src = emacs-skia-src;
        configureFlags = oldAttrs.configureFlags ++ [
          "--with-skia"
        ];
        buildInputs = oldAttrs.buildInputs ++ [
          pkgs.skia
          pkgs.libepoxy
        ];
        preBuild = (oldAttrs.preBuild or "") + ''
          mkdir -p src/deps/skia
        '';
      });
in
{
  home.file.".config/eca/config.json".source = ecaConfigJson;
  home.file.".gnus".source = ./.gnus;
  home.packages = with pkgs; [
    alsa-utils # emacs sound broken
    ispell
    (aspellWithDicts (
      dicts: with dicts; [
        en
        en-computers
        en-science
        nl
        fr
      ]
    ))
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
    emacs-lsp-booster
    mcp-proxy
    sshfs
    taplo # toml lsp
    guile
    fd
    nodejs
    ffmpeg # for encoding sound
    uv # for MCP server fetch
    unzip
    socat
    dtach
    abduco
    poppler-utils
    vips
    tmux
    # emacs-lsp-booster
  ];

  programs.doom-emacs = {
    enable = true;
    emacs = emacs-skia;
    doomDir = inputs.doom-config;
    tangleArgs = ".";
    provideEmacs = false;
    extraPackages = epkgs: [
      (epkgs.treesit-grammars.with-all-grammars.overrideAttrs (old: {
        buildCommand = old.buildCommand + ''
          ln -s ${tree-sitter-ron}/parser lib/libtree-sitter-ron.so
        '';
      }))
      epkgs.mu4e
      epkgs.vterm
    ];
    emacsPackageOverrides =
      eself: esuper:
      let
        # Fix packages using deprecated cl macros (defun*, loop, etc.)
        # These need cl-lib equivalents (cl-defun, cl-loop, etc.)
        fixDeprecatedCl =
          pkg:
          pkg.overrideAttrs (attrs: {
            postPatch = (attrs.postPatch or "") + ''
              # Replace deprecated cl macros with cl-lib equivalents
              find . -name "*.el" -exec sed -i \
                -e 's/(defun\*/(cl-defun/g' \
                -e 's/(defmacro\*/(cl-defmacro/g' \
                -e 's/(loop /(cl-loop /g' \
                -e 's/(return /(cl-return /g' \
                {} \;
              # Add (require 'cl-lib) to main elisp files
              for f in *.el; do
                if [ -f "$f" ]; then
                  sed -i '1s/^/(require '"'"'cl-lib)\n/' "$f" || true
                fi
              done
            '';
          });
      in
      {
        gptel-forge = esuper.gptel-forge.overrideAttrs (attrs: {
          nativeBuildInputs = (attrs.nativeBuildInputs or [ ]) ++ [ pkgs.git ];
        });
        # Fix packages using deprecated defun* from cl package
        elnode = fixDeprecatedCl esuper.elnode;
        creole = fixDeprecatedCl esuper.creole;
        fakir = fixDeprecatedCl esuper.fakir;
        web = fixDeprecatedCl esuper.web;
        kv = fixDeprecatedCl esuper.kv;
        db = fixDeprecatedCl esuper.db;
      };
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

  xdg.desktopEntries.org-protocol = {
    name = "org-protocol";
    comment = "Handle org-protocol";
    exec = "emacsclient -- %u";
    #terminal = "false";
    mimeType = [ "x-scheme-handler/org-protocol" ];
  };

  # separate emacs for toying around with doom without nix in the mix
  programs.emacs = {
    enable = true;
    package = emacs-skia;
    extraPackages = epkgs: [
      (epkgs.treesit-grammars.with-all-grammars.overrideAttrs (old: {
        buildCommand = old.buildCommand + ''
          ln -s ${tree-sitter-ron}/parser lib/libtree-sitter-ron.so
        '';
      }))
      epkgs.mu4e
      epkgs.vterm
    ];
  };
}
