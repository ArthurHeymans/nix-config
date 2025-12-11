{ pkgs, hostname, ... }:

let
  jay-git = pkgs.callPackage pkgs.jay.override {
    rustPlatform = pkgs.rustPlatform // {
      buildRustPackage =
        args:
        pkgs.rustPlatform.buildRustPackage (
          args
          // {
            src = pkgs.fetchFromGitHub {
              owner = "mahkoh";
              repo = "jay";
              rev = "c6cebc754681eebb042a020e73aab2d6f71cc857";
              hash = "sha256-i0ZtruAtpYDqdZrYa+FY+g9bZPDzFMfxJtfiMPnYLL0=";
            };
            cargoHash = "sha256-+5+jS4dCFE8hkkHAA4BcB+xtr4UF+px9iVPuQAIijwk=";
          }
        );
    };
  };

  accelSpeed = if hostname == "t480-arthur" then 1.0 else 0.0;
  jayConfig = import ./jay-config.nix { inherit accelSpeed; };
  
  tomlFormat = pkgs.formats.toml { };
  jayConfigFile = tomlFormat.generate "jay-config.toml" jayConfig;

in
{
  home.packages = [
    jay-git
  ];

  home.file.".config/jay/config.toml".source = jayConfigFile;
  home.file.".config/jay/screenshot.sh".source = ./screenshot.sh;
}
