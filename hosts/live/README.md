# Persistent USB desktop

`live` uses the normal desktop and Home Manager configuration on x86-64
machines. Its unencrypted Btrfs root, home and Nix store persist across
reboots. Zstd compression helps the desktop closure fit on the 32 GB USB.
GRUB supports legacy BIOS and UEFI removable-media boot without changing
firmware boot entries. Secure Boot must be disabled.

The disk configuration targets only `/dev/disk/by-id/usb-PHILIPS_USB-0:0`.
Running its Disko script **erases that drive**. Check the device before
reinstalling; change both device references in this directory for a different
USB drive.

Log in as `arthur` with the shared configuration's initial password
`password`, then change it with `passwd`. No private SSH keys or decrypted
secrets are copied from the installing machine; services using SOPS secrets
need their credentials provisioned separately.

A copy of the configuration is installed at `/home/arthur/src/nix-config`.
Rebuild with:

```sh
sudo nixos-rebuild switch --flake /home/arthur/src/nix-config#live
```

Watch free space when rebuilding: the drive is small, and previous
generations keep their store paths alive. `live` is excluded from the
nightly multi-host build list.
