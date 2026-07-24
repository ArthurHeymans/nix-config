{ ... }:
let
  # These are the static IDs assigned by the NixOS Caddy module. Matching
  # them on the host lets the VM write to its virtiofs-backed state directory.
  caddyUid = 239;
  caddyGid = 239;
in
{
  # Keep Caddy's ACME account, certificates, and other state outside the VM.
  users.groups.caddy.gid = caddyGid;
  users.users.caddy = {
    isSystemUser = true;
    group = "caddy";
    uid = caddyUid;
  };

  systemd.tmpfiles.rules = [
    "d /srv/caddy 0750 caddy caddy - -"
  ];

  microvm.vms.caddy = {
    config =
      { lib, ... }:
      {
        microvm = {
          hypervisor = "qemu";
          mem = 512;
          vcpu = 1;

          interfaces = [
            {
              type = "tap";
              id = "vm-caddy";
              mac = "02:00:00:00:00:13";
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
              tag = "caddy-data";
              source = "/srv/caddy";
              mountPoint = "/var/lib/caddy";
            }
          ];
        };

        networking = {
          hostName = "caddy";
          useDHCP = false;
          useNetworkd = true;
          firewall = {
            enable = true;
            allowedTCPPorts = [
              22
              80
              443
            ];
            allowedUDPPorts = [ 443 ];
          };
        };

        systemd.network = {
          enable = true;
          networks."20-lan" = {
            matchConfig.Type = "ether";
            networkConfig = {
              Address = "192.168.0.9/24";
              Gateway = "192.168.0.1";
              DNS = [
                "192.168.0.1"
                "1.1.1.1"
              ];
              DHCP = "no";
            };
          };
        };

        services = {
          caddy = {
            enable = true;
            email = "arthur@aheymans.xyz";

            # Add one entry per public service. Backends can be MicroVMs,
            # containers, or services on other LAN hosts, for example:
            #
            # virtualHosts."service.aheymans.xyz".extraConfig = ''
            #   reverse_proxy 192.168.0.10:8080
            # '';
            virtualHosts = { };
          };

          openssh = {
            enable = true;
            openFirewall = false;
            settings = {
              PasswordAuthentication = false;
              PermitRootLogin = "no";
            };
          };

          resolved.enable = true;
        };

        system.stateVersion = lib.mkDefault "25.05";
      };
  };
}
