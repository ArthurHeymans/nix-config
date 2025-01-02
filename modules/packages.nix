{pkgs, ...}: {
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

    nix-output-monitor
    #   nixd
    nil
    nixfmt-rfc-style
    alejandra
    statix
    deadnix

    pinentry-gnome3
    gnupg
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
