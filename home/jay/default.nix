{ pkgs, hostname, ... }:

let
  accelSpeed = if hostname == "t480-arthur" then 1.0 else 0.0;
  jayConfig = import ./jay-config.nix { inherit accelSpeed; };

  tomlFormat = pkgs.formats.toml { };
  jayConfigFile = tomlFormat.generate "jay-config.toml" jayConfig;
in
{
  home.file.".config/jay/config.toml".source = jayConfigFile;
  home.file.".config/jay/screenshot.sh".source = ./screenshot.sh;
}
