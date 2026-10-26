{ hosts, ... }:
let
  dongleSerial = "684263f1f7e1ed119f7ef75162c613ac";
  dongle = "/dev/serial/by-id/usb-Nabu_Casa_SkyConnect_v1.0_${dongleSerial}-if00-port0";
in
{
  # Only grant the VM runner access to this SkyConnect, not all USB devices.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="10c4", ATTR{idProduct}=="ea60", ATTR{serial}=="${dongleSerial}", GROUP="kvm", MODE="0660"
  '';

  microvm.vms.home-assistant.config =
    { lib, pkgs, ... }:
    {
      _module.args.hosts = hosts;
      imports = [ ../users/arthur/nixos.nix ];

      microvm = {
        hypervisor = "qemu";
        mem = 4096;
        vcpu = 2;
        interfaces = [
          {
            type = "tap";
            id = "vm-ha";
            mac = "02:00:00:00:00:14";
            tap.vhost = true;
          }
        ];
        devices = [
          {
            bus = "usb";
            path = "vendorid=0x10c4,productid=0xea60";
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
        ];
        # Keep HA's UI state, Zigbee pairing/keys, MQTT messages and SSH keys.
        volumes = [
          {
            image = "/var/lib/microvms/home-assistant/var.img";
            mountPoint = "/var";
            size = 32768;
          }
        ];
      };

      networking = {
        hostName = "home-assistant";
        useDHCP = false;
        useNetworkd = true;
        firewall = {
          enable = true;
          allowedTCPPorts = [
            8123
            8080
          ];
        };
      };
      systemd.network = {
        enable = true;
        networks."20-lan" = {
          matchConfig.Type = "ether";
          networkConfig = {
            Address = "192.168.0.10/24";
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

      services.home-assistant = {
        enable = true;
        extraComponents = [
          "analytics"
          "google_translate"
          "homeassistant_sky_connect"
          "isal"
          "met"
          "mqtt"
          "radio_browser"
          "shopping_list"
        ];
        config = {
          default_config = { };
          homeassistant.unit_system = "metric";
          "automation ui" = "!include automations.yaml";
          "scene ui" = "!include scenes.yaml";
          "script ui" = "!include scripts.yaml";
        };
      };
      # Create writable UI files once; never replace them on rebuild/restart.
      systemd.tmpfiles.rules = [
        "d /var/lib/hass 0750 hass hass - -"
        "f /var/lib/hass/automations.yaml 0600 hass hass - []"
        "f /var/lib/hass/scenes.yaml 0600 hass hass - []"
        "f /var/lib/hass/scripts.yaml 0600 hass hass - {}"
      ];

      # Both clients live here, so no unauthenticated MQTT listener on the LAN.
      services.mosquitto = {
        enable = true;
        listeners = [
          {
            address = "127.0.0.1";
            port = 1883;
            omitPasswordAuth = true;
            settings.allow_anonymous = true;
            acl = [ "topic readwrite #" ];
          }
        ];
      };

      services.zigbee2mqtt = {
        enable = true;
        settings = {
          version = 5;
          mqtt.server = "mqtt://127.0.0.1:1883";
          homeassistant.enabled = true;
          serial = {
            port = dongle;
            adapter = "ember";
            baudrate = 115200;
            rtscts = true;
          };
          frontend = {
            enabled = true;
            host = "0.0.0.0";
            port = 8080;
          };
          permit_join = false;
        };
      };
      systemd.services.zigbee2mqtt = {
        serviceConfig.EnvironmentFile = "/var/lib/zigbee2mqtt/network.env";
        requires = [
          "mosquitto.service"
          "zigbee2mqtt-secrets.service"
        ];
        after = [
          "mosquitto.service"
          "zigbee2mqtt-secrets.service"
        ];
      };
      systemd.services.zigbee2mqtt-secrets = {
        description = "Initialize persistent Zigbee network identity";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "zigbee2mqtt";
          Group = "zigbee2mqtt";
          StateDirectory = "zigbee2mqtt";
          StateDirectoryMode = "0700";
          WorkingDirectory = "/var/lib/zigbee2mqtt";
          UMask = "0077";
        };
        script = ''
          # Keep generated identity outside the Nix-managed configuration.yaml.
          if [ ! -e network.env ]; then
            ${pkgs.python3}/bin/python3 - <<'PY' > network.env.tmp
          import json
          import secrets

          identity = {
              "network_key": list(secrets.token_bytes(16)),
              "pan_id": secrets.randbelow(0xfffe) + 1,
              "ext_pan_id": list(secrets.token_bytes(8)),
          }
          for name, value in identity.items():
              print(f"ZIGBEE2MQTT_CONFIG_ADVANCED_{name.upper()}={json.dumps(value, separators=(',', ':'))}")
          PY
            mv network.env.tmp network.env
          fi
        '';
      };

      system.stateVersion = lib.mkDefault "26.05";
    };
}
