{ inputs, ... }:
let
  # These are the static IDs assigned by the NixOS Caddy module. Matching
  # them on the host lets the VM write to its virtiofs-backed state directory.
  caddyUid = 239;
  caddyGid = 239;
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      caddy-basic-auth-password = {
        sopsFile = ../secrets/caddy.yaml;
        key = "basicAuthPassword";
        restartUnits = [
          "caddy-secrets.service"
          "microvm@caddy.service"
        ];
      };
      caddy-gandi-api-token = {
        sopsFile = ../secrets/caddy.yaml;
        key = "gandiApiToken";
        restartUnits = [
          "caddy-secrets.service"
          "microvm@caddy.service"
        ];
      };
    };
  };

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

  systemd.services.caddy-secrets = {
    description = "Export secrets to the Caddy MicroVM";
    wantedBy = [ "multi-user.target" ];
    before = [ "microvm@caddy.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "caddy-secrets";
      RuntimeDirectoryMode = "0750";
    };
    script = ''
      chown ${toString caddyUid}:${toString caddyGid} /run/caddy-secrets
      install -m 0400 -o ${toString caddyUid} -g ${toString caddyGid} \
        /run/secrets/caddy-basic-auth-password \
        /run/caddy-secrets/basic-auth-password
      install -m 0400 -o ${toString caddyUid} -g ${toString caddyGid} \
        /run/secrets/caddy-gandi-api-token \
        /run/caddy-secrets/gandi-api-token
    '';
  };

  systemd.services."microvm@caddy" = {
    after = [ "caddy-secrets.service" ];
    requires = [ "caddy-secrets.service" ];
  };

  microvm.vms.caddy = {
    config =
      { lib, pkgs, ... }:
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
            {
              proto = "virtiofs";
              tag = "caddy-secrets";
              source = "/run/caddy-secrets";
              mountPoint = "/run/caddy-secrets";
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

        systemd.services = {
          caddy-pi-web-auth = {
            description = "Prepare the PI WEB basic-auth password hash";
            requiredBy = [ "caddy.service" ];
            before = [ "caddy.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              User = "caddy";
              Group = "caddy";
              RuntimeDirectory = "caddy-pi-web-auth";
              RuntimeDirectoryMode = "0700";
            };
            script = ''
              password_hash="$(${pkgs.caddy}/bin/caddy hash-password --plaintext "$(cat /run/caddy-secrets/basic-auth-password)")"
              printf 'PI_WEB_PASSWORD_HASH=%s\n' "$password_hash" > /run/caddy-pi-web-auth/environment
              chmod 0600 /run/caddy-pi-web-auth/environment
            '';
          };

          gandi-dynamic-dns = {
            description = "Update Gandi LiveDNS records for the Caddy endpoint";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            path = [
              pkgs.curl
              pkgs.jq
            ];
            serviceConfig = {
              Type = "oneshot";
              User = "caddy";
              Group = "caddy";
            };
            script = ''
              set -euo pipefail

              token="$(cat /run/caddy-secrets/gandi-api-token)"
              curl --fail --silent --show-error \
                -H "Authorization: Bearer $token" \
                https://id.gandi.net/tokeninfo >/dev/null

              public_ip="$(curl --fail --silent --show-error --ipv4 --max-time 15 https://api.ipify.org)"
              case "$public_ip" in
                *[!0-9.]*|"")
                  echo "Public IPv4 discovery returned an invalid address" >&2
                  exit 1
                  ;;
              esac

              endpoint="https://api.gandi.net/v5/livedns/domains/aheymans.xyz/records/pi-web/A"
              current="$(curl --fail --silent --show-error \
                -H "Authorization: Bearer $token" \
                "$endpoint" || true)"

              if [ "$(printf '%s' "$current" | jq -r --arg ip "$public_ip" \
                '(.rrset_values // []) == [$ip]' 2>/dev/null || printf false)" = true ]; then
                echo "pi-web.aheymans.xyz already points to $public_ip"
                exit 0
              fi

              payload="$(jq -nc --arg ip "$public_ip" \
                '{rrset_values: [$ip], rrset_ttl: 300}')"
              curl --fail --silent --show-error \
                --request PUT \
                -H "Authorization: Bearer $token" \
                -H "Content-Type: application/json" \
                --data "$payload" \
                "$endpoint" >/dev/null
              echo "Updated pi-web.aheymans.xyz to $public_ip"
            '';
          };
        };

        systemd.timers.gandi-dynamic-dns = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "1min";
            OnUnitActiveSec = "5min";
            RandomizedDelaySec = "30s";
            Persistent = true;
            Unit = "gandi-dynamic-dns.service";
          };
        };

        services = {
          caddy = {
            enable = true;
            email = "arthur@aheymans.xyz";
            environmentFile = "/run/caddy-pi-web-auth/environment";

            virtualHosts."pi-web.aheymans.xyz".extraConfig = ''
              basic_auth {
                arthur {$PI_WEB_PASSWORD_HASH}
              }
              reverse_proxy gmktec-k11.local:8504
            '';
          };

          avahi = {
            enable = true;
            nssmdns4 = true;
            openFirewall = true;
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
