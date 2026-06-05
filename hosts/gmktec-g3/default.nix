{inputs, ...}: {
  imports = [
    ../../modules/server.nix
    inputs.disko.nixosModules.disko
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  networking = {
    defaultGateway = "192.168.0.1";
    nameservers = [
      "192.168.0.1"
      "1.1.1.1"
    ];
    useDHCP = false;
    interfaces.enp3s0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.0.5";
          prefixLength = 24;
        }
      ];
    };
  };
}
