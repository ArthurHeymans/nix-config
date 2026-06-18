{pkgs, ...}: {
  # Enable containers.
  virtualisation.containers.enable = true;

  # Enable local VM management. swtpm is useful for Windows 11 guests,
  # which expect a TPM 2.0 device during installation.
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
    };
  };
  virtualisation.spiceUSBRedirection.enable = true;

  programs.virt-manager.enable = true;
}
