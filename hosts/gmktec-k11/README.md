# gmktec-k11 GPU unlock

The RTX 3090 uses [gpu-unlock](https://github.com/Zagitta/gpu-unlock) v2.0.0,
pinned in `packages/gpu-unlock.nix`. The module is built for this host's kernel;
NVIDIA 610.43.03 is used only to extract firmware, not to replace the installed
driver. This is a third-party, unsupported GPU modification; upstream reports
higher tensor throughput, not faster memory-bound token generation or gaming.

The initrd includes `gpu_unlock` and its firmware. `gpu_unlock.targets=all`
enables it for supported cards. An initrd service runs before module loading
and PCI coldplug so NVIDIA cannot race the unlock. A reboot is required; do not try to unlock a GPU already in use.

From this checkout **on gmktec-k11**:

```sh
sudo nixos-rebuild boot --flake path:.#gmktec-k11
sudo reboot
```

The `path:` form also includes newly added, not-yet-tracked package files.
After reboot, check for successful unlock messages (not merely module loading):

```sh
sudo journalctl -b -k --grep='gpu_unlock|gpu-unlock'
nvidia-smi
```

The existing Lanzaboote Secure Boot setup is unchanged. If the kernel enforces
module signatures and rejects this module, it needs a trusted signature; do not
disable Secure Boot just to bypass a load failure.

To roll back, select the previous NixOS generation at boot. To remove permanently,
remove the GPU-unlock block and `gpuUnlock` binding from `default.nix`, rebuild,
and reboot. The unlock is not a VBIOS flash and does not persist across a GPU
reset/power cycle.
