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
firmware first. Do not force-install a mismatched kernel module. After the first
installation, restart networking once (`/etc/init.d/network restart`) so netifd
loads the new WireGuard protocol. This briefly interrupts LAN connectivity;
reconnect over LAN SSH before running the setup script. Tailscale,
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
Tailscale setup, registered WireGuard protocol, and absence of pending UCI
changes before configuring anything. It waits for the interface to come up
before advertising routes; an asynchronous `ifup` exit status alone is insufficient.
It prints a root-only backup directory containing the previous network,
firewall, and Tailscale preferences. Rerunning replaces only its own sections.
It reloads services without restarting the whole LAN network. It then restarts
Tailscale and checks its return route via `tailscale0`: netifd can flush the
interface's addresses and table 52 during a network restart. Without restoring
those routes, office requests succeed but their replies take the LAN default
route. Use LAN SSH for deployment because Tailscale briefly reconnects.

The WireGuard interface is `office`, address `10.0.5.23/32`, with a 25-second
keepalive to `vpn.office.9e.network:51820`. The office firewall zone masquerades
forwarded traffic so the office sees **10.0.5.23**, independently of Tailscale's
SNAT. Only the two office prefixes are allowed from the Tailscale zone. A second
rule rejects fallback through other zones if the tunnel route disappears
(the router already permits Tailscale-to-LAN forwarding). MTU 1280 plus fw4 MSS
clamping is conservative for nested tunnels; retain the SSH `socat` workaround.

Network/firewall UCI and Tailscale preferences persist across reboot. The script
adds `/etc/sysctl.d/90-office-router.conf` to `/etc/sysupgrade.conf` to preserve
the explicit forwarding setting across upgrades. Retain the WireGuard packages
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
dig @10.0.5.1 stroh80-bmc.lab.9e.network
resolvectl query stroh80-bmc.lab.9e.network
ping -c 3 10.93.130.205
```

A client-side `ip route get` should use `tailscale0`. Recheck after a router
reboot. Only then delete the disabled `/etc/wireguard/9elements-wg.conf` copies
on m900 and coding, and the `9elements-wg` NetworkManager connections on
t480-arthur and gmktec-k11. Check for and remove any stale per-client office DNS
settings as well. The deployment status below records completed cleanup.

## Live deployment (2026-11-03)

- Installed matching WireGuard packages from the rc4 feeds, restarted netifd
  once to register the protocol, and successfully reapplied the hardened script.
  The return-route recovery fix was deployed and retested.
- Approved only `10.0.5.1/32` and `10.93.130.0/24` through the Tailscale API and
  added restricted DNS `9e.network -> 10.0.5.1`. API readback confirms both.
  Other advertised routes remain unapproved; other DNS settings and ACLs were
  not changed.
- Verified both client routes use `tailscale0` (table 52), split-DNS resolution
  of `stroh80-bmc.lab.9e.network` (`10.93.130.205`), and successful lab pings
  from gmktec-k11, coding, m900, and mj11. The k11 test passed 1252-byte ICMP
  payloads with DF set (1280-byte IP packets) without loss. TCP and UDP DNS
  both passed. An off-site client was not available for testing.
- SSH from k11 through the subnet routes reached `caliptra-pi` (`worker122`)
  and `caliptra-fpga` (`versal`). Both reported SSH client source `10.0.5.23`,
  proving office egress NAT. Each completed a checksum-verified 1 MiB transfer.
  DNS and SSH passed again after rerunning the updated setup script.
- Native `fw4 check` passes; the scoped forwarding/rejection rules and egress
  masquerade chain are installed. Removed the temporary router key file.
- Applied persistent Tailscale route acceptance and loose reverse-path filtering
  on gmktec-k11, coding, m900, and mj11. The preferences survive restart; an
  additional `/etc/sysctl.d/90-office-tailscale-client.conf` persists filtering
  until the declarative module is rebuilt. No full OS rebuild was performed.
- Stopped m900's manually created `9elements-wg` interface. After end-to-end
  verification, deleted the old `/etc/wireguard/9elements-wg.conf` files from
  coding and m900 and removed k11's `9elements-wg` NetworkManager profile.
- **Pending:** t480-arthur is unreachable; its old connection still needs
  disabling/removing before it can reclaim the shared key. gmktec-g3's live
  client settings require sudo access; its declarative module is updated.
- Office DNS itself returns NXDOMAIN for `spyral.lab.9e.network`; this is not a
  tunnel failure. Use the verified BMC record for DNS tests and ask office IT to
  correct the missing record if that name is still needed.

The original pre-deployment network/firewall/Tailscale backup on the router is
`/root/office-vpn-backup.BdMHGm`. Later reruns also created backups, but those
already contain the office configuration. The pre-change API route/DNS state is
saved privately on k11 at
`~/.local/state/office-router/tailnet-routing-dns-before-20261103T090430Z.json`.

## Rollback

Use LAN SSH, stop `office` with `ifdown office`, and restore `network` and
`firewall` from the printed backup directory to `/etc/config/`. Remove
`/etc/sysctl.d/90-office-router.conf` and its `/etc/sysupgrade.conf` entry,
reload network and firewall, and restore
the old non-default advertised routes with `tailscale set --advertise-routes=...`
from `tailscale-prefs.json` (the checked router previously advertised
`192.168.1.0/24` and was an exit node). Restore `--snat-subnet-routes` according
to the saved `NoSNAT` preference if it differed, and restore `--accept-dns`
according to the saved `CorpDNS` preference. Do not disable other routes or
the exit-node setting inadvertently. Restart Tailscale after reloading networking
to restore its return routes. Using the API backup, restore the device's prior
enabled-route list and remove only the added `9e.network` split-DNS entry (PATCH
its value to `null`); preserve any unrelated later changes. Once the router
tunnel is down, one old client connection can be recreated if needed.
