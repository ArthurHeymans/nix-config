{ inputs, pkgs, ... }:
let
  zmx = inputs.zmx.packages.${pkgs.stdenv.hostPlatform.system}.zmx;
in
{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    flashprog
    em100
    coreboot-utils
    eza
    btop
    tree
    htop
    nload
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
    linux-wifi-hotspot # TODO re-enable when fixed
    wifi-qr
    haveged
    brightnessctl
    acpica-tools
    zmx

    zellij

    nix-output-monitor
    #   nixd
    nil
    nixfmt
    alejandra
    statix
    deadnix

    gnupg
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.nix-ld.enable = true;
}
