{
  ##################################################################################################################
  #
  # NixOS Configuration
  #
  ##################################################################################################################

  users.users.arthur = {
    # Arthur's authorizedKeys
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKm4ucwEs89kKGpYrdhPwfnCYeVVDR3ROxqIwjK/98/7 arthur@t41sarthur"
    ];
  };
}
