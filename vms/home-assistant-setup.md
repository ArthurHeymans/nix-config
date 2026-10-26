# Home Assistant on gmktec-g3

`home-assistant.nix` declares a QEMU MicroVM with 2 vCPUs, 4 GiB RAM,
and a sparse 32 GiB disk mounted at `/var`:

- Home Assistant: <http://192.168.0.10:8123>
- Zigbee2MQTT: <http://192.168.0.10:8080>
- Mosquitto: `127.0.0.1:1883` inside the VM only, without authentication.
- SSH: `ssh arthur@192.168.0.10` using the usual authorized keys.

Keep `192.168.0.10` outside the router's DHCP pool, or reserve it for
`02:00:00:00:00:14`. The web interfaces are for a trusted LAN; do not forward
their ports from the internet. The Zigbee2MQTT frontend has no authentication.

## First use

1. Open Home Assistant and complete onboarding.
2. In **Settings → Devices & services → Add integration**, add **MQTT**.
   Use broker `127.0.0.1`, port `1883`, with no username or password.
   MQTT broker configuration is UI-managed; Nix provides its dependencies.
3. Open Zigbee2MQTT and temporarily enable **Permit join** while pairing a
   device. Joining is disabled by default. Zigbee2MQTT publishes Home Assistant
   discovery messages, so paired devices appear through the MQTT integration.
4. Do not configure ZHA against the same dongle; Zigbee2MQTT owns it exclusively.

The passed-through adapter is Nabu Casa SkyConnect v1.0, serial
`684263f1f7e1ed119f7ef75162c613ac`, USB ID `10c4:ea60`.
Zigbee2MQTT uses its stable `/dev/serial/by-id/` path with the `ember` driver,
115200 baud and hardware flow control. Firmware was probed as EmberZNet
`7.4.4.0 build 0`; no firmware change was needed.

The host udev rule grants USB access only to this serial number. QEMU selects
by vendor/product ID, so revisit selection if another `10c4:ea60` device is
connected. After replacing the dongle, update both the serial and passthrough
configuration as needed.

## Declarative versus writable configuration

Nix owns the VM, package versions, broker, Home Assistant's base YAML and
Zigbee2MQTT's main settings. Home Assistant owns its integration setup, accounts,
areas, helpers and dashboards. UI automations, scripts and scenes are included
from writable files and survive service restarts and rebuilds.

For a new Home Assistant integration type, add its domain to
`services.home-assistant.extraComponents` and rebuild if dependencies are not
already present. Adding devices through MQTT needs no rebuild.

Zigbee2MQTT keeps device and group configuration in separate writable files.
Its network key, PAN ID and extended PAN ID are randomly generated once in
`/var/lib/zigbee2mqtt/network.env` and loaded through a systemd environment
file. They are not stored in Nix or regenerated on each service start. Main Zigbee2MQTT settings edited through its frontend
are replaced by Nix settings at the next service start; change those in Nix.

## Operations and backups

On gmktec-g3:

```sh
sudo systemctl restart microvm@home-assistant
sudo journalctl -u microvm@home-assistant
```

Inside the guest:

```sh
sudo systemctl status home-assistant mosquitto zigbee2mqtt
sudo journalctl -u zigbee2mqtt
```

Persistent storage is
`/var/lib/microvms/home-assistant/var.img` on the host. It includes:

- `/var/lib/hass`: accounts, integration credentials, UI configuration, history.
- `/var/lib/zigbee2mqtt`: network identity, coordinator backup, paired devices.
- `/var/lib/mosquitto`: retained messages and broker persistence.
- `/var/lib/ssh`: stable SSH host key.

Back this up off-machine. For a consistent whole-disk backup, stop the VM
before copying the image, then start it again. Nix rollback does not roll back
Home Assistant's database or other mutable state. No scheduled backup is
configured by this module.
