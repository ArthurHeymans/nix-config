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
- `https://m900.home.aheymans.xyz` proxies T3 Code at `m900.local:13773`.
- `https://mj11.home.aheymans.xyz` proxies T3 Code at `mj11.local:13773`.
- `https://home.aheymans.xyz/zigbee2mqtt/` proxies `192.168.0.10:8080`, preserving
  the path. Zigbee2MQTT
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

## T3 Code from a phone

Each environment gets its own HTTPS origin, not a URL subpath. Caddy preserves
T3 Code's HTTP routes, authentication and WebSocket upgrades. No extra proxy
login is added: T3 Code requires a one-time pairing link, then remembers the
paired device. These two endpoints are public, including from cellular networks.
Only Caddy's existing ports 80/443 need forwarding; do not forward port 13773.

On each host, create a fresh link for your phone:

```sh
# Run on m900:
t3 auth pairing create --ttl 10m --base-url https://m900.home.aheymans.xyz
# Run on mj11:
t3 auth pairing create --ttl 10m --base-url https://mj11.home.aheymans.xyz
```

Paste each resulting pairing URL into **Add environment** in the T3 Code mobile
app, or open it in your phone's browser. Pairing URLs are passwords; do not
publish them. Both environments can be saved in the same mobile app. Public
HTTPS also allows access from `app.t3.codes`; mDNS alone would not work away
from home or provide a publicly trusted certificate.

The Caddy VM resolves the upstream `.local` names through systemd-resolved's
mDNS-capable DNS stub (`127.0.0.53`). mDNS resolution and UDP 5353 are enabled
on its LAN interface only. Caddy queries IPv4 records and refreshes its upstream
cache every minute, so DHCP address changes require no configuration edit.
M900 and MJ11 publish their addresses through the shared Avahi configuration.
If a backend is asleep or offline its route returns a gateway error; the other
routes remain independent.

On home Wi-Fi the public hostnames need NAT loopback, or split DNS pointing
both T3 names to `192.168.0.11`, just like the Home Assistant hostname.

## Dynamic DNS

`gandi-ddns.service` discovers the public IPv4 over HTTPS and reconciles only
the `home`, `m900.home`, and `mj11.home` A records in `aheymans.xyz`.
Other records are left untouched.
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
