# Coding VM

`coding` is a separate MicroVM on `gmktec-g3`, configured in `coding.nix`:

- 16 GiB RAM, four shared vCPUs
- 100 GiB persistent ext4 root disk at `/var/lib/microvms/coding/root.img`
- LAN address `192.168.0.9`, SSH user `arthur`
- T3 Code and Node-based Pi, plus common build tools

The disk is sparse: it grows as data is written, rather than reserving 100 GiB
on the host. Repositories, credentials, temporary build files, and the writable
Nix store/database all live on this disk. Only the host's read-only Nix store is
shared; Hermes's home and credentials are not mounted.

T3 Code runs as the guest's `t3code.service`, listening on loopback and reachable
remotely through T3 Connect. To authorize it, SSH into the guest and run
`t3 connect link --headless`, approve in a browser, then
`sudo systemctl restart t3code`.

Pi is enabled in T3's initial settings. Run `pi`, then `/login`, in the guest to
authorize a model provider. Credentials are not copied from another VM.

The initial deployment uses the host's existing MicroVM service templates and
`/etc/systemd/system.control/microvms.target.d/50-coding.conf` for autostart,
without switching the host configuration or restarting other guests. The Nix
module declares the same VM and autostart for subsequent host rebuilds.

On the host, manage the VM with `sudo systemctl restart microvm@coding` and
`sudo journalctl -u microvm@coding`. Inside the guest, inspect T3 with
`sudo systemctl status t3code` or `t3 connect status`.
