# M900 Tiny coding server

Headless NixOS configuration matching MJ11's coding stack. Intel i5-6400T,
16 GiB RAM, Kingston 256 GB NVMe (`50026B72825D0A41`). The Philips live USB
is not an installation target.

- SSH: `ssh arthur@m900.local` (authorized keys only; passwordless sudo).
- Pi: `pi`; authenticate with `/login` on this host.
- T3 Code: lingering `arthur` user service, listening only on `127.0.0.1:13773`.
  Access with T3 Connect or
  `ssh -N -L 13774:127.0.0.1:13773 arthur@m900.local`, then open
  `http://127.0.0.1:13774`.
- Service: `systemctl --user status t3code` and
  `journalctl --user -u t3code`.
- Disk: 1 GiB EFI partition and Btrfs root/home/nix subvolumes; zram swap.
- Boot: GRUB removable-media EFI fallback, suitable for its coreboot firmware.

Build from this checkout with
`nix build path:.#nixosConfigurations.m900.config.system.build.toplevel`.
The flake has a local EWM input; keep `/home/arthur/src/ewm` available when
rebuilding on the host. No workstation credentials or private SSH keys are
copied by this configuration.
