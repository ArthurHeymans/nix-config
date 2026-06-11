{inputs, ...}: {
  imports = [
    ../../modules/server.nix
    ../../vms
    inputs.disko.nixosModules.disko
    inputs.microvm.nixosModules.host
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  boot.kernelModules = ["vhost_net"];

  networking = {
    useDHCP = false;
    useNetworkd = true;
  };

  systemd.network = {
    enable = true;

    netdevs."10-br0".netdevConfig = {
      Name = "br0";
      Kind = "bridge";
    };

    networks = {
      "10-enp3s0" = {
        matchConfig.Name = "enp3s0";
        networkConfig.Bridge = "br0";
        linkConfig.RequiredForOnline = "enslaved";
      };

      "20-microvm-taps" = {
        matchConfig.Name = "vm-*";
        networkConfig.Bridge = "br0";
        linkConfig.RequiredForOnline = "enslaved";
      };

      "30-br0" = {
        matchConfig.Name = "br0";
        networkConfig = {
          Address = "192.168.0.5/24";
          Gateway = "192.168.0.1";
          DNS = [
            "192.168.0.1"
            "1.1.1.1"
          ];
        };
        linkConfig.RequiredForOnline = "routable";
      };
    };
  };
}
