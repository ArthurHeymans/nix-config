{ config, lib, pkgs, ... }:

{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    flashprog
    coreboot-utils
    eza
    btop
    tree
    htop
    vim
    wget
    curl
    git
    sysstat
    lm_sensors # for `sensors` command
    acpi
    ethtool
    hdparm
    dmidecode
    parted
    usbutils
    pciutils
    psmisc
    wavemon

    zellij
    #   nixd
    nil
    nixfmt-rfc-style

    pinentry-gnome3
    gnupg
  ];

}
