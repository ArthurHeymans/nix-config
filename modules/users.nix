{username, ...}: {
  # ============================= User related =============================
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "sound"
      "dialout"
      "plugdev"
    ];
    initialPassword = "password";
  };

  # Ensure 'plugdev' group exists
  users.groups.plugdev = { };

  # given the users in this list the right to specify additional substituters via:
  #    1. `nixConfig.substituers` in `flake.nix`
  #    2. command line args `--options substituers http://xxx`
  nix.settings.trusted-users = [username];
}
