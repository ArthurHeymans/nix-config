{ lib, hosts, ... }:
{
  ##################################################################################################################
  #
  # NixOS Configuration
  #
  ##################################################################################################################

  users.users.arthur = {
    # Arthur's authorizedKeys
    openssh.authorizedKeys.keys = import ./ssh-keys.nix { inherit lib hosts; };
  };
}
