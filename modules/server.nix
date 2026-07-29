{ lib, ... }: {
  imports = [
    ./base.nix
  ];

  networking = {
    firewall.enable = true;
    networkmanager.enable = lib.mkDefault false;
    useDHCP = lib.mkDefault true;
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.resolved.enable = true;
}
