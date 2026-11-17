# Caddy on gmktec-g3

See [`caddy.nix`](caddy.nix) for the guest, routes, certificates and DDNS timer.

## Router and DNS

Keep the guest's static IP (`192.168.0.11`) outside the router's DHCP pool or
reserve it for the MAC in `caddy.nix`. Forward TCP 80 and 443 to Caddy; UDP 443
is optional for HTTP/3. Do not forward the backend ports. Public DNS uses the
WAN IPv4; there is no published AAAA record.

From the LAN, the public hostnames need router NAT loopback or split DNS
pointing them to Caddy. See [Home Assistant setup](home-assistant-setup.md#proxy-and-dashboard)
for proxy trust and the Zigbee2MQTT dashboard.

## T3 Code from a phone

The T3 endpoints are public and use T3's own pairing, with no separate proxy
login. Create a fresh pairing link on each host:

```sh
# Run on m900:
t3 auth pairing create --ttl 10m --base-url https://m900.home.aheymans.xyz
# Run on mj11:
t3 auth pairing create --ttl 10m --base-url https://mj11.home.aheymans.xyz
```

Open the URL in your phone's browser or paste it into **Add environment** in
the T3 Code mobile app. Treat pairing links as passwords. The public HTTPS
origins also work from `app.t3.codes`; the backend `.local` names are LAN-only.

## DDNS and backups

Allow roughly ten minutes for a WAN address change to propagate; records
already cached with a longer TTL can take longer. To force a check, run
`sudo systemctl start gandi-ddns` in the guest.

Renew an expiring Gandi PAT in `secrets/caddy-credentials.yaml` through SOPS,
then redeploy the host. Limit its permissions to the necessary DNS zone where
possible.

Stop `microvm@caddy` before copying `/var/lib/microvms/caddy/var.img` for backup.

Run DDNS unit tests from the checkout:

```sh
python3 -B -m unittest discover -s vms -p 'test_gandi_ddns.py' -v
```
