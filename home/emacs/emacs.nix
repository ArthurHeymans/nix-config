{
  pkgs,
  inputs,
  ...
}:
let
  ecaConfig = import ./eca-config.nix;
  ecaConfigJson = pkgs.runCommand "eca-config.json" {
    nativeBuildInputs = [ pkgs.jq ];
  } ''
    echo '${builtins.toJSON ecaConfig}' | ${pkgs.jq}/bin/jq '.' > $out
  '';
in
{
  home.file.".config/eca/config.json".source = ecaConfigJson;
  home.file.".gnus".source = ./.gnus;
  home.packages = with pkgs; [
    alsa-utils # emacs sound broken
    ispell
    (aspellWithDicts (dicts: with dicts; [en en-computers en-science nl fr]))
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
    poppler-utils
    vips
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
      epkgs.vterm
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

  xdg.desktopEntries.org-protocol = {
    name = "org-protocol";
    comment = "Handle org-protocol";
    exec = "emacsclient -- %u";
    #terminal = "false";
    mimeType=["x-scheme-handler/org-protocol"];
  };

  # separate emacs for toying around with doom without nix in the mix
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;
    extraPackages = epkgs: [
      epkgs.treesit-grammars.with-all-grammars
      epkgs.mu4e
      epkgs.vterm
    ];
  };
}
