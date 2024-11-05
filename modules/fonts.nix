{ config, lib, pkgs, ... }:

{
    fonts = {
    packages = with pkgs; [
      # icon fonts
      material-design-icons
      font-awesome

      # normal fonts
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji

      dejavu_fonts
      hack-font

      fira
      fira-mono
      fira-code
      fira-code-symbols
      fira-code-nerdfont

      (nerdfonts.override {
        fonts = [
          # symbols icon only
          "NerdFontsSymbolsOnly"
          # Characters
          "FiraCode"
          "JetBrainsMono"
          "Iosevka"
        ];
      })
    ];

    # use fonts specified by user rather than default ones
    enableDefaultPackages = false;

    # user defined fonts
    # the reason there's Noto Color Emoji everywhere is to override DejaVu's
    # B&W emojis that would sometimes show instead of some Color emojis
    fontconfig.defaultFonts = {
      serif = [
        "Noto Serif"
        "Noto Color Emoji"
      ];
      sansSerif = [
        "Noto Sans"
        "Noto Color Emoji"
      ];
      monospace = [
        "JetBrainsMono Nerd Font"
        "Noto Color Emoji"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

}
