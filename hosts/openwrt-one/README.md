# Office subnet router: OpenWrt One

`openwrt` was checked over LAN SSH: `ubus call system board` reports model
**OpenWrt One**, board `openwrt,one`, running OpenWrt 25.12.0-rc4. Its current
LAN address is `192.168.0.151`, Tailscale address `100.110.54.101`. It is **not**
the GL-BE9300 (`192.168.0.145`). It is a DHCP client on `br-lan`, not the home
network's default gateway. Reserve its DHCP lease if using this LAN address.

This is native OpenWrt configuration, not a NixOS flake host. The setup script
owns the named `office*` UCI sections, leaving the existing LAN and Tailscale
zones/forwardings alone. It advertises and routes only:

- `10.0.5.1/32`: office DNS
- `10.93.130.0/24`: lab/Caliptra network

Other advertised routes and the existing exit-node setting are preserved. The
router opts out of Tailscale DNS so that resolving `vpn.office.9e.network` uses
upstream DNS, not the office split-DNS server behind its own tunnel (which would
create a bootstrap dependency). Clients still use Tailscale DNS. No
`10.0.0.0/8` route is installed. Add any additional lab prefixes deliberately to
both WireGuard allowed IPs, both firewall rules, and Tailscale advertisements.

## Prerequisites and key handover

Confirm that office IT permits this use. **Stop every existing copy of this
WireGuard identity before starting the router's tunnel.** Sharing the key and
`10.0.5.23` across active peers causes endpoint roaming, not redundancy. Keep the
old configurations disabled until the router is verified, for rollback.

On the One, install `kmod-wireguard` and `wireguard-tools` using `apk`. Neither
was installed when checked. The kernel module must match the running firmware;
if the release-candidate feeds no longer provide it, upgrade to a supported
firmware first. Do not force-install a mismatched kernel module. Tailscale,
firewall4, `jsonfilter`, the `network.tailscale` interface, and a `tailscale`
firewall zone already exist and are required by the script.

Provision the existing office **private key only**, not the whole wg-quick
configuration, as `/root/office-wg.key` (mode 0600, root-owned) via a secure file
transfer. Do not put it in this repository, a Nix string/store path, a shell
argument, or chat. OpenWrt netifd requires it in `/etc/config/network`; the
script supplies it via UCI stdin and keeps that file mode 0600. Router backups
therefore also contain the key and must be protected. There is no sops-nix
activation service on this OpenWrt host.

## Apply (explicit, not part of a NixOS rebuild)

From this repository, after verifying the router's LAN SSH host key:

```sh
# -O uses legacy SCP because this OpenWrt installation may lack an SFTP server.
scp -O hosts/openwrt-one/setup-office-vpn.sh root@192.168.0.151:/root/
ssh root@192.168.0.151 'sh /root/setup-office-vpn.sh /root/office-wg.key'
```

Do not run the script with shell tracing. It validates the board, key, existing
Tailscale setup, and absence of pending UCI changes before configuring anything.
It prints a root-only backup directory containing the previous network,
firewall, and Tailscale preferences. Rerunning replaces only its own sections.
It reloads services without restarting the whole LAN network.

The WireGuard interface is `office`, address `10.0.5.23/32`, with a 25-second
keepalive to `vpn.office.9e.network:51820`. The office firewall zone masquerades
forwarded traffic so the office sees **10.0.5.23**, independently of Tailscale's
SNAT. Only the two office prefixes are allowed from the Tailscale zone. A second
rule rejects fallback through other zones if the tunnel route disappears
(the router already permits Tailscale-to-LAN forwarding). MTU 1280 plus fw4 MSS
clamping is conservative for nested tunnels; retain the SSH `socat` workaround.

Network/firewall UCI and Tailscale preferences persist across reboot. Include
`/etc/sysctl.d/90-office-router.conf` in `/etc/sysupgrade.conf` to preserve the
explicit forwarding setting across upgrades, and retain the WireGuard packages
in the upgraded image. Remove the temporary `/root/office-wg.key` after success;
the active copy remains in `/etc/config/network`.

## Tailscale control plane and NixOS clients

1. Approve `10.0.5.1/32` and `10.93.130.0/24` on **openwrt** in the Tailscale
   admin console (or configure narrowly scoped `autoApprovers`). Grant only the
   intended users/devices access to these destinations in your tailnet policy.
2. Add a **restricted/split DNS** nameserver `10.0.5.1` for `9e.network`, not a
   global nameserver. Ensure the intended clients may reach UDP and TCP port 53
   on it. MagicDNS alone does not provide office DNS records.
3. Rebuild the NixOS clients. `modules/tailscale.nix` enables client routing
   (loose reverse-path filtering) and uses `extraSetFlags = [ "--accept-routes" ]`.
   This applies to already-enrolled clients without an auth key; `extraUpFlags`
   alone would not. The coding VM also imports this module. Initial enrollment
   still requires `tailscale up`. Hermes's separate tagged-VM policy is unchanged.

## Verification and cleanup

On the router (avoid `uci show network` and `wg showconf`, which expose keys):

```sh
wg show office
ip -4 route get 10.0.5.1
ip -4 route get 10.93.130.1
fw4 check
```

Require a recent handshake and routes via `office`. From an enrolled client,
including one away from home, verify `tailscale debug prefs` has `RouteAll: true`,
then check office DNS and actual lab access:

```sh
dig @10.0.5.1 spyral.lab.9e.network
resolvectl query spyral.lab.9e.network
ssh spyral.lab.9e.network
```

A client-side `ip route get` should use `tailscale0`. Recheck after a router
reboot. Only then delete the disabled `/etc/wireguard/9elements-wg.conf` copies
on m900 and coding, and the `9elements-wg` NetworkManager connections on
t480-arthur and gmktec-k11. Check for and remove any stale per-client office DNS
settings as well. No live connection cleanup is performed by this commit.

## Rollback

Use LAN SSH, stop `office` with `ifdown office`, and restore `network` and
`firewall` from the printed backup directory to `/etc/config/`. Remove
`/etc/sysctl.d/90-office-router.conf`, reload network and firewall, and restore
the old non-default advertised routes with `tailscale set --advertise-routes=...`
from `tailscale-prefs.json` (the checked router previously advertised
`192.168.1.0/24` and was an exit node). Restore `--snat-subnet-routes` according
to the saved `NoSNAT` preference if it differed, and restore `--accept-dns`
according to the saved `CorpDNS` preference. Do not disable other routes or
the exit-node setting inadvertently. Once the router tunnel is down, one old
client connection can be re-enabled if needed.
