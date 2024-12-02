{...}: {
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "hyprlock"; # dbus/sysd lock command (loginctl lock-session)
        unlock_cmd = ""; # same as above, but unlock
        before_sleep_cmd = "hyprlock"; # command ran before sleep
        after_sleep_cmd = ""; # command ran after sleep
        ignore_dbus_inhibit = false; # whether to ignore dbus-sent idle-inhibit requests (used by e.g. firefox or steam)
        ignore_systemd_inhibit = false; # whether to ignore systemd-inhibit --what=idle inhibitors
      };

      listener = {
        timeout = 300; # in seconds
        on-timeout = "hyprlock"; # command to run when timeout has passed
        on-resume = ""; # command to run when activity is detected after timeout has fired.
      };
    };
  };
}