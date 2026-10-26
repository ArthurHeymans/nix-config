# Caddy on gmktec-g3

`caddy.nix` declares a QEMU MicroVM with 1 vCPU, 512 MiB RAM and a persistent
2 GiB `/var` disk. Its static address is `192.168.0.11`, MAC
`02:00:00:00:00:15`. Keep that address outside the router's DHCP pool or create
a matching DHCP reservation there. Declaring a static VM address does not
configure the router's DHCP server.

Router TCP ports 80 and 443 should forward to this address. UDP 443 is optional
for HTTP/3. There is no published AAAA record; public DNS uses the WAN IPv4.

## Routes and TLS

- `https://home.aheymans.xyz` proxies Home Assistant at `192.168.0.10:8123`.
- `/zigbee2mqtt/` proxies `192.168.0.10:8080`, preserving the path. Zigbee2MQTT
  is configured with the corresponding base URL. This route rejects clients
  outside private LAN/VPN address ranges because its UI is unauthenticated.
  Its access rule uses the actual peer address, not caller-supplied headers.

Home Assistant trusts only Caddy's IP for forwarded headers. Its firewall
allows backend HTTP connections only from Caddy, not arbitrary LAN or public
IPv6 clients. SSH remains available with the usual authorized keys.

This HA version no longer reads HTTP YAML after its first migration. Proxy
trust is configured through its authenticated WebSocket API (`http/config`,
`http/config/configure`, then `http/config/promote` after verifying connectivity).
These settings persist in HA-managed state, alongside the UI-managed MQTT
integration. Nix owns the proxy VM, firewall restrictions and external URL.

TLS certificates are issued and renewed by NixOS ACME using Gandi DNS-01;
Caddy reloads after renewal. The certificate and ACME account persist under
`/var/lib/acme`. No custom Caddy DNS plugin is needed.

The Zigbee2MQTT sidebar dashboard is UI-managed. Its iframe URL is
`https://home.aheymans.xyz/zigbee2mqtt/`, configured through HA's authenticated
dashboard API. It works on the LAN/VPN, not from a public internet client.
Access via the public hostname from the LAN requires router NAT loopback,
or split DNS resolving the hostname to `192.168.0.11`.

## Dynamic DNS

`gandi-ddns.service` discovers the public IPv4 over HTTPS and reconciles only
the `home` A record in `aheymans.xyz`. Other records are left untouched.
The timer runs about one minute after boot and every five minutes afterward,
with up to 30 seconds of jitter. The record TTL is 300 seconds, so a WAN address
change can take roughly ten minutes to propagate through caches. Previously
cached records may retain the old, longer TTL until they expire.

Two IP-discovery services are tried. Non-public and invalid addresses are
rejected. Gandi is updated only if the address or TTL differs. Failures are
reported in the service journal and retried at the next timer activation.

The Gandi PAT is encrypted in `secrets/caddy-credentials.yaml`, readable by the
host and designated recovery hosts through SOPS. The host copies it to a
root-only runtime directory exposed read-only to the guest. ACME and DDNS
consume it through systemd credentials; neither the token nor a plaintext
environment file is embedded in the Nix store. Renew an expiring PAT through
SOPS, then redeploy the host. Keep its Gandi permissions limited to the
necessary DNS zone where possible.

## Operations

```sh
ssh arthur@192.168.0.11
sudo systemctl status caddy gandi-ddns.timer acme-order-renew-home.aheymans.xyz
sudo journalctl -u caddy -u gandi-ddns -u acme-order-renew-home.aheymans.xyz
sudo systemctl start gandi-ddns
```

On the host, manage `microvm@caddy`. Back up
`/var/lib/microvms/caddy/var.img` while the VM is stopped. The old Caddy runner
used `192.168.0.9`, now occupied by the coding VM; the new declaration replaces
that runner rather than restoring its old network settings.

Run DDNS unit tests with:

```sh
python3 -B -m unittest discover -s vms -p 'test_gandi_ddns.py' -v
```
