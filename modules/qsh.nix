{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.services.qshFleet;
  fleet = import ../packages/qsh-fleet.nix {
    inherit pkgs username;
    authorizedKeys = config.users.users.${username}.openssh.authorizedKeys.keys;
  };
in
{
  options.services.qshFleet.enable = lib.mkEnableOption "the Tailscale-only qsh user service";

  config = lib.mkMerge [
    { environment.systemPackages = [ fleet.qsh ]; }
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = config.services.tailscale.enable;
          message = "services.qshFleet requires Tailscale";
        }
      ];
      users.users.${username}.linger = true;
      systemd.user.units."qshd.service" = {
        text = fleet.unitText;
        wantedBy = [ "default.target" ];
      };
    })
  ];
}
