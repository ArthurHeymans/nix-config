{
  pkgs,
  inputs,
  osConfig,
  #emacs-skia-src,
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

  # emacs-skia =
  #   (pkgs.emacs-pgtk.override {
  #     withTreeSitter = true;
  #     srcRepo = true;
  #   }).overrideAttrs
  #     (oldAttrs: {
  #       pname = "emacs-skia";
  #       src = emacs-skia-src;
  #       configureFlags = oldAttrs.configureFlags ++ [
  #         "--with-skia"
  #       ];
  #       buildInputs = oldAttrs.buildInputs ++ [
  #         pkgs.skia
  #         pkgs.libepoxy
  #       ];
  #       preBuild = (oldAttrs.preBuild or "") + ''
  #         mkdir -p src/deps/skia
  #       '';
  #     });
  ghostel-module = pkgs.callPackage ./ghostel-module.nix { };

  # elBeBackForEpkgs =
  #   epkgs:
  #   let
  #     ebb-module = inputs.el-be-back.packages.${pkgs.stdenv.hostPlatform.system}.default;
  #   in
  #   epkgs.trivialBuild {
  #     pname = "el-be-back";
  #     version = "0.1.0";
  #     src = inputs.el-be-back;
  #     postInstall = ''
  #       local ext="${if pkgs.stdenv.isDarwin then "dylib" else "so"}"
  #       install -m444 ${ebb-module}/lib/ebb-module.$ext \
  #         $out/share/emacs/site-lisp/
  #     '';
  #   };
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
    #emacs = emacs-skia;
    emacs = pkgs.emacs-pgtk;
    doomDir = inputs.doom-config;
    tangleArgs = ".";
    provideEmacs = false;
    extraPackages = epkgs: [
      # Use with-grammars to skip tree-sitter-quint: upstream pins rev="release"
      # (a branch, not a commit), so the hash breaks whenever they push.
      (epkgs.treesit-grammars.with-grammars (
        gs: builtins.attrValues (builtins.removeAttrs gs [ "tree-sitter-quint" ])
      ))
      epkgs.mu4e
      epkgs.vterm
      # (elBeBackForEpkgs epkgs)
      osConfig.programs.ewm.ewmPackage
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
        gptel-forge-prs = esuper.gptel-forge-prs.overrideAttrs (attrs: {
          nativeBuildInputs = (attrs.nativeBuildInputs or [ ]) ++ [ pkgs.git ];
        });
        # tramp-rpc depends on msgpack (version "0" declared in Package-Requires).
        # Ensure msgpack is available from melpaPackages during build.
        tramp-rpc = esuper.tramp-rpc.overrideAttrs (attrs: {
          packageRequires = (attrs.packageRequires or [ ]) ++ [ eself.msgpack ];
        });
        # Fix packages using deprecated defun* from cl package
        elnode = fixDeprecatedCl esuper.elnode;
        creole = fixDeprecatedCl esuper.creole;
        fakir = fixDeprecatedCl esuper.fakir;
        web = fixDeprecatedCl esuper.web;
        kv = fixDeprecatedCl esuper.kv;
        db = fixDeprecatedCl esuper.db;
        # Inject pre-built native module into ghostel, similar to how
        # nixpkgs injects the compiled .so into emacs-vterm.
        ghostel = esuper.ghostel.overrideAttrs (old: {
          postInstall = (old.postInstall or "") + ''
            local ext="${if pkgs.stdenv.isDarwin then "dylib" else "so"}"
            install -m444 ${ghostel-module}/lib/ghostel-module.$ext \
              $out/share/emacs/site-lisp/elpa/ghostel-*/
          '';
        });
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
    # package = emacs-skia;
    package = pkgs.emacs-pgtk;
    extraPackages = epkgs: [
      # Use with-grammars to skip tree-sitter-quint: upstream pins rev="release"
      # (a branch, not a commit), so the hash breaks whenever they push.
      (epkgs.treesit-grammars.with-grammars (
        gs: builtins.attrValues (builtins.removeAttrs gs [ "tree-sitter-quint" ])
      ))
      epkgs.mu4e
      epkgs.vterm
      # (elBeBackForEpkgs epkgs)
      osConfig.programs.ewm.ewmPackage
    ];
  };

  # XDG portal config for ewm
  xdg.portal = {
    enable = true;
    config = {
      ewm = {
        default = "gnome;gtk";
        "org.freedesktop.impl.portal.Access" = "gtk";
        "org.freedesktop.impl.portal.Notification" = "gtk";
        "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
      };
    };
  };
}
