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
              rev = "a2e21cb926664cfc1980f8a38ec1aa34a7792c19";
              hash = "sha256-uhTi2CWSuLq+mgclcZwTSp1i2BKAqs7vt2wL9MJH+UE=";
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
