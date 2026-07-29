{ username, ... }: {
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    inherit username;
    homeDirectory = "/home/${username}";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
