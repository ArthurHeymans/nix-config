{
  ##################################################################################################################
  #
  # NixOS Configuration
  #
  ##################################################################################################################

  users.users.arthur = {
    # Arthur's authorizedKeys
    openssh.authorizedKeys.keys = (import ../../hosts/ssh-keys.nix).sshKeys.arthur;
  };
}
