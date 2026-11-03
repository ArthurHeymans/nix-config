#!/bin/sh
# Run on the OpenWrt One, not on a NixOS host. Never run with shell tracing.
set +x
set -eu
set -f
umask 077

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

[ "$(id -u)" = 0 ] || fail 'Run as root on the OpenWrt One.'
[ "$#" = 1 ] || fail "Usage: sh $0 /root/office-wg.key"
[ "$(ubus call system board | jsonfilter -e '@.board_name')" = 'openwrt,one' ] ||
    fail 'This setup is only for the OpenWrt One (not the GL-BE9300).'
[ -f /lib/netifd/proto/wireguard.sh ] && command -v wg >/dev/null ||
    fail 'Install matching kmod-wireguard and wireguard-tools packages first.'
[ -n "$(ubus call network get_proto_handlers | jsonfilter -e '@.wireguard')" ] ||
    fail 'Restart networking once after installing WireGuard, then rerun this script.'
[ "$(uci -q get network.tailscale.device)" = tailscale0 ] ||
    fail 'Expected the existing network.tailscale interface on tailscale0.'
uci show firewall | grep -q "\.name='tailscale'$" ||
    fail 'Expected the existing tailscale firewall zone.'
[ "$(tailscale status --json | jsonfilter -e '@.BackendState')" = Running ] ||
    fail 'Enroll/start Tailscale before configuring the office tunnel.'
[ -z "$(uci changes network)$(uci changes firewall)" ] ||
    fail 'Commit or revert pending network/firewall UCI changes first.'

# Validate without logging the key or putting it in process arguments.
private_key="$(cat "$1")"
[ "${#private_key}" = 44 ] || fail 'Invalid WireGuard private key length.'
case "$private_key" in
    *[!A-Za-z0-9+/=]*) fail 'Invalid WireGuard private key encoding.' ;;
esac
printf '%s\n' "$private_key" | wg pubkey >/dev/null 2>&1 ||
    fail 'Invalid WireGuard private key.'

# Preserve other advertised subnets and the existing exit-node setting.
# Default routes are managed separately by Tailscale's advertise-exit-node flag.
prefs="$(tailscale debug prefs)"
current_routes="$(printf '%s\n' "$prefs" | jsonfilter -e '@.AdvertiseRoutes[*]')"
advertise_routes='10.0.5.1/32,10.93.130.0/24'
for route in $current_routes; do
    case "$route" in
        0.0.0.0/0|::/0|10.0.5.1/32|10.93.130.0/24) ;;
        *) advertise_routes="$advertise_routes,$route" ;;
    esac
done

backup="$(mktemp -d /root/office-vpn-backup.XXXXXX)"
cp -p /etc/config/network /etc/config/firewall "$backup/"
printf '%s\n' "$prefs" > "$backup/tailscale-prefs.json"
printf '%s\n' "Backup: $backup (contains secrets; keep private)."

# These named sections are owned by this script. Replacing them avoids duplicate
# peers, routes, and firewall rules on subsequent runs.
for section in network.office network.office_peer firewall.office \
    firewall.office_forward firewall.office_no_fallback; do
    uci -q delete "$section" || :
done

# OpenWrt netifd stores the private key in root-only /etc/config/network.
# Feed it through stdin, never `uci set ...private_key=...` in argv.
uci batch <<EOF
set network.office=interface
set network.office.proto='wireguard'
set network.office.private_key='$private_key'
set network.office.mtu='1280'
add_list network.office.addresses='10.0.5.23/32'
set network.office_peer=wireguard_office
set network.office_peer.public_key='JlxiVd9bn7s5pI/B4BOvApS0rxuM34ClZNDmMCKIBEs='
set network.office_peer.endpoint_host='vpn.office.9e.network'
set network.office_peer.endpoint_port='51820'
set network.office_peer.persistent_keepalive='25'
set network.office_peer.route_allowed_ips='1'
add_list network.office_peer.allowed_ips='10.0.5.1/32'
add_list network.office_peer.allowed_ips='10.93.130.0/24'
set firewall.office=zone
set firewall.office.name='office'
add_list firewall.office.network='office'
set firewall.office.family='ipv4'
set firewall.office.input='REJECT'
set firewall.office.output='ACCEPT'
set firewall.office.forward='REJECT'
set firewall.office.masq='1'
set firewall.office.mtu_fix='1'
set firewall.office_forward=rule
set firewall.office_forward.name='Tailscale to office only'
set firewall.office_forward.src='tailscale'
set firewall.office_forward.dest='office'
set firewall.office_forward.family='ipv4'
set firewall.office_forward.proto='all'
add_list firewall.office_forward.dest_ip='10.0.5.1/32'
add_list firewall.office_forward.dest_ip='10.93.130.0/24'
set firewall.office_forward.target='ACCEPT'
set firewall.office_no_fallback=rule
set firewall.office_no_fallback.name='Reject office fallback through other zones'
set firewall.office_no_fallback.src='tailscale'
set firewall.office_no_fallback.dest='*'
set firewall.office_no_fallback.family='ipv4'
set firewall.office_no_fallback.proto='all'
add_list firewall.office_no_fallback.dest_ip='10.0.5.1/32'
add_list firewall.office_no_fallback.dest_ip='10.93.130.0/24'
set firewall.office_no_fallback.target='REJECT'
EOF
unset private_key
chmod 600 /etc/config/network
uci commit network
uci commit firewall
chmod 600 /etc/config/network
fw4 check

# Resolving vpn.office.9e.network must use upstream DNS, not the split-DNS
# server inside the tunnel it is trying to establish. Do this before ifup.
tailscale set --accept-dns=false

# No full network restart: preserve the LAN and Tailscale management session.
# Forwarding is already enabled on this router; persist it explicitly as well.
printf 'net.ipv4.ip_forward=1\n' > /etc/sysctl.d/90-office-router.conf
sysctl -p /etc/sysctl.d/90-office-router.conf
grep -qxF /etc/sysctl.d/90-office-router.conf /etc/sysupgrade.conf ||
    printf '/etc/sysctl.d/90-office-router.conf\n' >> /etc/sysupgrade.conf
/etc/init.d/firewall reload
/etc/init.d/network reload
ifup office

# ifup queues an asynchronous netifd operation; a zero exit status does not
# mean the interface actually came up. Never advertise an absent tunnel.
up=false
for _attempt in 1 2 3 4 5 6 7 8 9 10; do
    up="$(ubus call network.interface.office status | jsonfilter -e '@.up')"
    [ "$up" = true ] && break
    sleep 1
done
[ "$up" = true ] || fail 'Office interface did not come up; inspect netifd logs.'
wg show office >/dev/null

# fw4 masquerading on the office egress is deliberate: the office must see
# 10.0.5.23 even if Tailscale's own netfilter/SNAT implementation changes.
tailscale set --snat-subnet-routes=true --advertise-routes="$advertise_routes"
printf '%s\n' 'Configured. Verify the handshake, then approve routes and split DNS in Tailscale.'
