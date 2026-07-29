{ lib, hosts, ... }:
let
  hostKeys = lib.filter (key: key != null) (lib.mapAttrsToList (_: host: host.sshKey or null) hosts);
in
{
  ##################################################################################################################
  #
  # NixOS Configuration
  #
  ##################################################################################################################

  users.users.arthur = {
    # Arthur's authorizedKeys
    openssh.authorizedKeys.keys = hostKeys ++ [
      # Keys that do not correspond to a current NixOS host.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKm4ucwEs89kKGpYrdhPwfnCYeVVDR3ROxqIwjK/98/7 arthur@t41sarthur"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH2swnPv8HuDLr5Eo0gGeHtckis5yxJYtQEUhw4wyAwr u0_a303@localhost" # Phone
    ];
  };
}
