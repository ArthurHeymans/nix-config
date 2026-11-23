{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.my.virtualisation.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable local containers, libvirtd/QEMU, and virt-manager.";
  };

  config = lib.mkIf config.my.virtualisation.enable {
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
  };
}
