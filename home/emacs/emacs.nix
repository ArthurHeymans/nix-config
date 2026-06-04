{
  pkgs,
  inputs,
  osConfig,
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

  # EWM's author maintains the PGTK Skia patches on Codeberg.  Keep this
  # pinned instead of following the branch implicitly so rebuilds stay
  # reproducible.
  emacsSkia =
    (pkgs.emacs-pgtk.override {
      withTreeSitter = true;
      srcRepo = true;
    }).overrideAttrs
      (oldAttrs: {
        pname = "emacs-skia";
        version = "30.2-skia-b328605";
        src = pkgs.fetchgit {
          url = "https://codeberg.org/ezemtsov/emacs.git";
          rev = "b328605b4d3fcf17edadf44a68c8ea4d54225a2a";
          hash = "sha256-QiLqCxVyFdjzTrj2DEi089Eenj9SKmZFLHYaall0iJ4=";
        };
        configureFlags = oldAttrs.configureFlags ++ [
          "--with-skia"
        ];
        buildInputs = oldAttrs.buildInputs ++ [
          pkgs.skia
          pkgs.libepoxy
        ];
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [
          pkgs.autoconf
          pkgs.automake
        ];
        preConfigure = (oldAttrs.preConfigure or "") + ''
          ./autogen.sh
        '';
        postInstall = (oldAttrs.postInstall or "") + ''
          rm -f $out/bin/ctags $out/share/man/man1/ctags.1.gz
        '';
      });
  ghostelForEpkgs =
    epkgs:
    let
      zig = pkgs.zig_0_15;
      libExt = pkgs.stdenv.hostPlatform.extensions.sharedLibrary;
      unpackZigArtifact =
        name: artifact:
        pkgs.runCommand name
          {
            nativeBuildInputs = [ zig ];
          }
          ''
            hash=$(zig fetch --global-cache-dir "$TMPDIR" ${artifact})
            mv "$TMPDIR/p/$hash" "$out"
            chmod 755 "$out"
          '';
      ghosttySourceDeps = unpackZigArtifact "ghostty-source" (
        pkgs.fetchurl {
          url = "https://github.com/ghostty-org/ghostty/archive/01825411ab2720e47e6902e9464e805bc6a062a1.tar.gz";
          hash = "sha256-1VUgfGglf4oRjyFYckJdcRPJOstyEhWAAGOirEZ56Yo=";
        }
      );
      ghosttyThemeDeps = unpackZigArtifact "ghostty-themes" (
        pkgs.fetchurl {
          url = "https://deps.files.ghostty.org/ghostty-themes-release-20260323-152405-a2c7b60.tgz";
          hash = "sha256-fWgXdUXh2/dNZqERzEu9hz4xyy4nl+GUjLMpUMrsRnA=";
        }
      );
      waylandProtocolsDeps = unpackZigArtifact "wayland-protocols" (
        pkgs.fetchurl {
          url = "https://gitlab.freedesktop.org/wayland/wayland-protocols/-/archive/1.47/wayland-protocols-1.47.tar.gz";
          hash = "sha256-3S3xSrX0EDgleq7cxLX7msDuAY8/D5SvkJcCjmDTMiM=";
        }
      );
      ghostelZigDeps = pkgs.runCommand "${epkgs.ghostel.pname}-${epkgs.ghostel.version}-zig-deps" { } ''
        mkdir -p $out
        cp -rLT ${pkgs.ghostty.deps} $out
        chmod -R u+w $out
        cp -rLT ${ghosttySourceDeps} "$out/ghostty-1.3.2-dev-5UdBCzaaBwVjJOr-ltYINjybeEOAmLAauH5oq8-cdNGN"
        cp -rLT ${ghosttyThemeDeps} "$out/N-V-__8AAL6FAwBDPampKgDjoxlJYDIn2jv0VaINS4W6CXJN"
        cp -rLT ${waylandProtocolsDeps} "$out/N-V-__8AAFdWDwA0ktbNUi9pFBHCRN4weXIgIfCrVjfGxqgA"
      '';
    in
    epkgs.ghostel.overrideAttrs (old: {
      deps = ghostelZigDeps;
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ zig ];
      env = (old.env or { }) // {
        EMACS_INCLUDE_DIR = "${epkgs.emacs}/include";
      };
      preBuild = ''
        export ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
        mkdir -p "$ZIG_GLOBAL_CACHE_DIR/p"
        cp -rLT ${ghostelZigDeps} "$ZIG_GLOBAL_CACHE_DIR/p"
        chmod -R u+w "$ZIG_GLOBAL_CACHE_DIR/p"

        zig build -Doptimize=ReleaseFast -Dcpu=baseline
        test -f ghostel-module${libExt}
      '';
    });
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
    emacs = emacsSkia;
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
      epkgs.ghostel
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
        # Build ghostel's native Zig module from the package source, like
        # nixpkgs does for vterm, instead of injecting a release binary.
        ghostel = ghostelForEpkgs esuper;
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
    package = emacsSkia;
    extraPackages = epkgs: [
      # Use with-grammars to skip tree-sitter-quint: upstream pins rev="release"
      # (a branch, not a commit), so the hash breaks whenever they push.
      (epkgs.treesit-grammars.with-grammars (
        gs: builtins.attrValues (builtins.removeAttrs gs [ "tree-sitter-quint" ])
      ))
      epkgs.mu4e
      epkgs.vterm
      (ghostelForEpkgs epkgs)
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
