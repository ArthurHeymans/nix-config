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

in
{
  home.packages = [
    jay-git
  ];

  home.file.".config/jay/config.toml".text =
    let
      accelValue = if hostname == "t480-arthur" then "1.0" else "0.0";
    in
    builtins.replaceStrings [ "@ACCEL_SPEED@" ] [ accelValue ] (builtins.readFile ./config.toml);
  home.file.".config/jay/screenshot.sh".source = ./screenshot.sh;

  # TODO add config here
}
