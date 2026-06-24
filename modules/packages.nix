{
  inputs,
  pkgs,
  ...
}:
let
  zmx = inputs.zmx.packages.${pkgs.stdenv.hostPlatform.system}.zmx;
in
{
  # Desktop/development packages shared by laptop and workstation systems.
  environment.systemPackages = with pkgs; [
    acpi
    acpica-tools
    brightnessctl
    coreboot-utils
    deadnix
    em100
    flashprog
    gnupg
    haveged
    hdparm
    linux-wifi-hotspot # TODO re-enable when fixed
    nil
    nix-output-monitor
    nixfmt
    parted
    psmisc
    statix
    wavemon
    wifi-qr
    zellij
    zmx
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.nix-ld.enable = true;
}
