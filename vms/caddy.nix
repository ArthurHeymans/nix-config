{
  inputs,
  hosts,
  pkgs,
  ...
}:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops.secrets.caddy_gandi_token = {
    sopsFile = ../secrets/caddy-credentials.yaml;
    key = "gandi_token";
    restartUnits = [ "caddy-credentials.service" ];
  };
  systemd.tmpfiles.rules = [ "d /run/caddy-credentials 0711 root root - -" ];
  systemd.services.caddy-credentials = {
    requires = [ "sops-install-secrets.service" ];
    after = [
      "sops-install-secrets.service"
      "systemd-tmpfiles-setup.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.coreutils}/bin/install -m 0400 -o root -g root \
        /run/secrets/caddy_gandi_token /run/caddy-credentials/gandi-token
    '';
  };
  systemd.services."microvm-virtiofsd@caddy" = {
    requires = [ "caddy-credentials.service" ];
    after = [ "caddy-credentials.service" ];
  };

  microvm.vms.caddy.config =
    { lib, pkgs, ... }:
    {
      _module.args.hosts = hosts;
      imports = [ ../users/arthur/nixos.nix ];

      microvm = {
        hypervisor = "qemu";
        mem = 512;
        vcpu = 1;
        interfaces = [
          {
            type = "tap";
            id = "vm-caddy";
            mac = "02:00:00:00:00:15";
            tap.vhost = true;
          }
        ];
        shares = [
          {
            proto = "virtiofs";
            tag = "ro-store";
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
            readOnly = true;
          }
          {
            proto = "virtiofs";
            tag = "caddy-credentials";
            source = "/run/caddy-credentials";
            mountPoint = "/run/caddy-credentials";
            readOnly = true;
          }
        ];
        volumes = [
          {
            image = "/var/lib/microvms/caddy/var.img";
            mountPoint = "/var";
            size = 2048;
          }
        ];
      };

      networking = {
        hostName = "caddy";
        useDHCP = false;
        useNetworkd = true;
        firewall.enable = true;
      };
      systemd.network = {
        enable = true;
        networks."20-lan" = {
          matchConfig.Type = "ether";
          networkConfig = {
            Address = "192.168.0.11/24";
            Gateway = "192.168.0.1";
            DNS = [
              "192.168.0.1"
              "1.1.1.1"
            ];
            DHCP = "no";
          };
        };
      };
      time.timeZone = "Europe/Brussels";
      users.users.arthur = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      };
      security.sudo.wheelNeedsPassword = false;
      services.openssh = {
        enable = true;
        openFirewall = true;
        hostKeys = [
          {
            path = "/var/lib/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ];
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
        };
      };
      services.resolved.enable = true;

      security.acme = {
        acceptTerms = true;
        defaults.email = "arthur@aheymans.xyz";
        certs."home.aheymans.xyz" = {
          dnsProvider = "gandiv5";
          dnsResolver = "1.1.1.1:53";
          credentialFiles.GANDIV5_PERSONAL_ACCESS_TOKEN_FILE = "/run/caddy-credentials/gandi-token";
        };
      };
      services.caddy = {
        enable = true;
        openFirewall = true;
        virtualHosts."home.aheymans.xyz" = {
          useACMEHost = "home.aheymans.xyz";
          extraConfig = ''
            @zigbee path /zigbee2mqtt /zigbee2mqtt/*
            handle @zigbee {
              # The unauthenticated Zigbee admin UI is not public.
              @external not remote_ip private_ranges 100.64.0.0/10
              respond @external "Zigbee2MQTT is only available on the LAN or VPN." 403
              redir /zigbee2mqtt /zigbee2mqtt/ 308
              reverse_proxy 192.168.0.10:8080
            }
            handle {
              reverse_proxy 192.168.0.10:8123
            }
          '';
        };
      };

      systemd.services.gandi-ddns = {
        description = "Update home.aheymans.xyz with the current public IPv4";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        environment = {
          GANDI_DDNS_DOMAIN = "aheymans.xyz";
          GANDI_DDNS_NAME = "home";
          GANDI_DDNS_TTL = "300";
        };
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          LoadCredential = [ "gandi-token:/run/caddy-credentials/gandi-token" ];
          ExecStart = "${pkgs.python3}/bin/python3 ${./gandi_ddns.py}";
          TimeoutStartSec = "2min";
          NoNewPrivileges = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
        };
      };
      systemd.timers.gandi-ddns = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1min";
          OnUnitActiveSec = "5min";
          RandomizedDelaySec = "30s";
          Unit = "gandi-ddns.service";
        };
      };

      system.stateVersion = lib.mkDefault "26.05";
    };
}
