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
      "video"
      "input"
      "libvirtd"
    ];
    initialPassword = "password";
  };

  # Ensure 'plugdev' group exists
  users.groups.plugdev = { };
}
