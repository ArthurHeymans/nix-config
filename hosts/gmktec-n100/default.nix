{ lib, inputs, hostname, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    inputs.disko.nixosModules.disko
    ./disk-config.nix
    inputs.determinate.nixosModules.default
  ];

  # Set hostname
  networking.hostName = hostname;

  # Static IP configuration
  networking.useDHCP = false;
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "192.168.1.100";  # Change this to your desired static IP
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";  # Change this to your gateway
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];  # SSH only
  };

  # Enable SSH with secure defaults
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Minimal user configuration
  users.users.arthur = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = (import ../ssh-keys.nix).sshKeys.arthur;
  };

  # Allow sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Minimal Nix configuration
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [ "https://cache.nixos.org" ];
    trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
  };

  # Minimal package set
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.05";
}
