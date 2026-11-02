# M900 Tiny coding server

Headless NixOS configuration matching MJ11's coding stack. Intel i5-6400T,
16 GiB RAM, Kingston 256 GB NVMe (`50026B72825D0A41`). The Philips live USB
is not an installation target.

- SSH: `ssh arthur@m900.local` (authorized keys only; passwordless sudo).
- Pi: `pi`; authenticate with `/login` on this host.
- T3 Code: lingering `arthur` user service on `0.0.0.0:13773`, with TCP 13773
  open in the firewall, matching the other hosts. Open
  `http://m900.local:13773` on the LAN or `http://<tailscale-ip>:13773` after
  enrolling the host in Tailscale. For phone access, use Caddy at
  `https://m900.home.aheymans.xyz` with a fresh pairing link; see
  [Caddy setup](../../vms/caddy-setup.md#t3-code-from-a-phone).
- Service: `systemctl --user status t3code` and
  `journalctl --user -u t3code`.
- Disk: 1 GiB EFI partition and Btrfs root/home/nix subvolumes; zram swap.
- Boot: GRUB removable-media EFI fallback, suitable for its coreboot firmware.

Build from this checkout with
`nix build path:.#nixosConfigurations.m900.config.system.build.toplevel`.
The flake has a local EWM input; keep `/home/arthur/src/ewm` available when
rebuilding on the host. No workstation credentials or private SSH keys are
copied by this configuration.
