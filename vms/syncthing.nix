{ ... }: {
  systemd.tmpfiles.rules = [
    "d /srv/syncthing 0750 arthur users - -"
    "d /srv/syncthing/data 0750 arthur users - -"
    "d /srv/syncthing/data/docs 0755 arthur users - -"
    "d /srv/syncthing/data/org 0755 arthur users - -"
  ];

  microvm = {
    vms.syncthing = {
      config = { lib, pkgs, ... }: {
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

        systemd.services.syncthing-fix-folders = {
          requiredBy = [ "syncthing.service" ];
          before = [ "syncthing.service" ];
          serviceConfig.Type = "oneshot";
          path = [ pkgs.coreutils pkgs.perl ];
          script = ''
            install -d -m 0755 -o arthur -g users /var/lib/syncthing/data/docs /var/lib/syncthing/data/org
            config=/var/lib/syncthing/.config/syncthing/config.xml
            [ -e "$config" ] || exit 0
            perl -0pi -e '
              s#path="/var/lib/syncthing/docs"#path="/var/lib/syncthing/data/docs"#g;
              s#path="/var/lib/syncthing/org"#path="/var/lib/syncthing/data/org"#g;
              s#(<folder id="ggjkx-55sj4"[^>]*rescanIntervalS=")\d+(")#''${1}60$2#g;
              s#(<folder id="org"[^>]*rescanIntervalS=")\d+(")#''${1}60$2#g;
            ' "$config"
          '';
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
