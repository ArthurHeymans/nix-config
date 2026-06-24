{ ... }: {
  systemd.tmpfiles.rules = [
    "d /srv/soju 0750 root root - -"
  ];

  microvm = {
    vms.soju = {
      config = { lib, ... }: {
        imports = [
          ../users/arthur/nixos.nix
        ];

        microvm = {
          hypervisor = "qemu";
          mem = 256;
          vcpu = 1;

          interfaces = [
            {
              type = "tap";
              id = "vm-soju";
              mac = "02:00:00:00:00:11";
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
              tag = "soju-data";
              source = "/srv/soju";
              mountPoint = "/var/lib/soju";
            }
          ];
        };

        networking = {
          hostName = "soju";
          useDHCP = false;
          useNetworkd = true;
          firewall = {
            enable = true;
            allowedTCPPorts = [ 6667 ];
          };
        };

        systemd.network = {
          enable = true;
          networks."20-lan" = {
            matchConfig.Type = "ether";
            networkConfig = {
              Address = "192.168.0.7/24";
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

        # /var/lib/soju is a virtiofs mount from the host.  systemd's
        # DynamicUser+StateDirectory private-directory migration cannot manage
        # that mount point, so run this tiny dedicated MicroVM service as root
        # and let soju use the mounted working directory directly.
        systemd.services.soju.serviceConfig = {
          DynamicUser = lib.mkForce false;
          StateDirectory = lib.mkForce [ ];
        };

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

          soju = {
            enable = true;
            hostName = "soju.gmktec-g3";
            listen = [ "irc+insecure://:6667" ];
            enableMessageLogging = false;
            extraConfig = ''
              message-store memory
            '';
          };
        };

        system.stateVersion = lib.mkDefault "25.05";
      };
    };
  };
}
