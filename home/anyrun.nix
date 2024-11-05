{
  inputs,
  pkgs,
  ...
}: {
  programs.anyrun = {
    enable = true;
    config = {
      x = {fraction = 0.5;};
      y = {fraction = 0.3;};
      width = {fraction = 0.3;};
      height = {fraction = 0.3;};
      hideIcons = false;
      ignoreExclusiveZones = true;
      layer = "overlay";
      hidePluginInfo = false;
      closeOnClick = false;
      showResultsImmediately = true;
      maxEntries = null;

      plugins = with inputs.anyrun.packages.${pkgs.system}; [
        applications
        rink
        kidex
        #randr
        dictionary
        symbols
      ];
      # An array of all the plugins you want, which either can be paths to the .so files, or their packages
    };

    # Inline comments are supported for language injection into
    # multi-line strings with Treesitter! (Depends on your editor)
    extraCss =
      /*
      css
      */
      ''
        * {
          all: unset;
          font-size: 1.25rem;
        }

        #window {
          background-color: transparent;
        }

        box#main {
          border-radius: 16px;
          padding: 12px;
          background-color: grey;
          color: @foreground;
          border: solid 3px @cursor;
        }

        #entry {
          padding: 8px 4px 8px 4px;
          background-color: transparent;
        }

        #match {
          min-height: 32px;
          margin: 4px 0 4px 0;
          padding: 0 0 0 4px;
          border-radius: 8px;
          transition-duration: 0.15s, 0.05s;
          transition-property: background-color, color;
        }

        #match:selected {
          background-color: black;
          color: green;
        }

        #match-desc {
          color: blue;
        }
      '';

    extraConfigFiles."applications".text = ''
      Config(
       desktop_actions: false,
       max_entries: 5,
      )
    '';
  };
}
