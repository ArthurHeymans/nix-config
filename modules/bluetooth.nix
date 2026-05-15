{ ... }:
{
  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman = {
    enable = true;
    # The applet is managed by Home Manager. Leaving the NixOS applet enabled
    # creates a duplicate blueman-applet.service drop-in and systemd rejects
    # the unit because it gets two ExecStart entries.
    withApplet = false;
  };
}
