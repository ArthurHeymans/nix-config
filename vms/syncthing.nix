{ ... }: {
  systemd.tmpfiles.rules = [
    "d /srv/syncthing 0750 arthur users - -"
  ];

  microvm = {
    vms.syncthing = {
      config = { lib, ... }: {
        imports = [
          ../users/arthur/nixos.nix
        ];

        microvm = {
          hypervisor = "qemu";
          mem = 1024;
          vcpu = 2;

          interfaces = [
            {
              type = "tap";
              id = "vm-syncthing";
              mac = "02:00:00:00:00:10";
              tap.vhost = true;
            }
          ];

          shares = [
            {
              proto = "virtiofs";
              tag = "ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
            }
            {
              proto = "virtiofs";
              tag = "syncthing-data";
              source = "/srv/syncthing";
              mountPoint = "/var/lib/syncthing";
            }
          ];
        };

        networking = {
          useDHCP = false;
          useNetworkd = true;
          firewall.enable = true;
        };

        systemd.network = {
          enable = true;
          networks."20-lan" = {
            matchConfig.Type = "ether";
            networkConfig = {
              Address = "192.168.0.6/24";
              Gateway = "192.168.0.1";
              DNS = [
                "192.168.0.1"
                "1.1.1.1"
              ];
              DHCP = "no";
            };
          };
        };

        users.users.arthur = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
        };

        security.sudo.wheelNeedsPassword = false;

        services = {
          openssh = {
            enable = true;
            openFirewall = true;
            settings = {
              PasswordAuthentication = false;
              PermitRootLogin = "no";
            };
          };

          resolved.enable = true;

          syncthing = {
            enable = true;
            user = "arthur";
            openDefaultPorts = true;
            dataDir = "/var/lib/syncthing";
            configDir = "/var/lib/syncthing/.config/syncthing";
            guiAddress = "127.0.0.1:8384";
          };
        };

        system.stateVersion = lib.mkDefault "25.05";
      };
    };
  };
}
