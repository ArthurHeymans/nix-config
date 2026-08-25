{ pkgs, ... }: {
  # Enable NetworkManager by default
  networking.networkmanager.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      } # KDE Connect
      {
        from = 20000;
        to = 20999;
      } # Experiments
      # t3 code
      {
        from = 13773;
        to = 13773;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      } # KDE Connect
      {
        from = 20000;
        to = 20999;
      } # Experiments
      # t3 code
      {
        from = 13773;
        to = 13773;
      }
    ];
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      # X11Forwarding = true;
      PermitRootLogin = "no"; # disable root login
      PasswordAuthentication = false; # disable password login
    };
    openFirewall = true;
  };

  # VPN
  services.mullvad-vpn.enable = true;

  # systemd-resolved
  services.resolved.enable = true;

  # transmission torrents
  services.transmission = {
    package = pkgs.transmission_4;
    enable = true;
    openFirewall = true;
  };
}
