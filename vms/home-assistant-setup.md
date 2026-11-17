# Home Assistant on gmktec-g3

See [`home-assistant.nix`](home-assistant.nix) for the guest and service settings.
Keep `192.168.0.10` outside the router's DHCP pool or reserve it for the MAC in
that file. Do not forward the backend ports; see [Caddy setup](caddy-setup.md).

## First use

1. Open <https://home.aheymans.xyz> and complete onboarding.
2. In **Settings → Devices & services → Add integration**, add **MQTT**. Use
   broker `127.0.0.1`, port `1883`, with no username or password. This
   integration is UI-managed; Nix only provides its dependencies.
3. Open <https://home.aheymans.xyz/zigbee2mqtt/> from the LAN/VPN and enable
   **Permit join** temporarily. Paired devices appear through MQTT discovery;
   adding them does not need a rebuild. Do not configure ZHA against the same
   dongle.

For a new Home Assistant integration type, add its domain to
`services.home-assistant.extraComponents` and rebuild if its dependencies are
not already present. Make changes to Zigbee2MQTT's main settings in Nix;
frontend edits to those settings are replaced on service restart. Device and
group configuration lives in separate writable files.

## Proxy and dashboard

After its first migration, Home Assistant no longer reads HTTP proxy trust
from YAML. Set Caddy (`192.168.0.11`) as the only trusted proxy using HA's
authenticated WebSocket API: `http/config`, then `http/config/configure`, and
`http/config/promote` after verifying connectivity. These settings are stored
in HA-managed state.

The Zigbee2MQTT sidebar dashboard is also UI-managed. Set its iframe URL to
`https://home.aheymans.xyz/zigbee2mqtt/` through HA's authenticated dashboard
API. It only works on the LAN/VPN because the Zigbee2MQTT frontend itself
has no authentication.

## Zigbee adapter replacement

The current SkyConnect was probed with EmberZNet `7.4.4.0 build 0`; no firmware
change was needed. The host udev rule matches the serial number, but QEMU
selects by vendor/product ID. Revisit selection if another device with the same
USB ID is present. Update both the serial and passthrough settings as needed
when replacing the dongle.

## Backups

Back up `/var/lib/microvms/home-assistant/var.img` off-machine. Stop
`microvm@home-assistant` before copying the disk image, then start it again.
The image contains HA's accounts, integrations, dashboards and history,
Zigbee network and pairing state, MQTT persistence and the SSH host key.
Nix rollback does not restore that state, and this module does not schedule
backups.
