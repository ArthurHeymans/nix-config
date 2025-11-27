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
              owner = "ArthurHeymans";
              repo = "jay";
              rev = "10adbb2309a80f14f99d88455b9e6cc738f7cb5c";
              hash = "sha256-jXLiWHuoHlbg8Kks8+AuHtF2LDfUA0gdd15L9qGx42I=";
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
