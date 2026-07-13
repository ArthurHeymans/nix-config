{
  inputs,
  pkgs,
  ...
}:
let
  zmx = inputs.zmx.packages.${pkgs.stdenv.hostPlatform.system}.zmx.overrideAttrs (old: {
    # zmx's .zon and zig2nix lock disagree; use the dependency captured in the lock.
    postPatch = (old.postPatch or "") + ''
      substituteInPlace build.zig.zon \
        --replace-fail "git+https://github.com/ghostty-org/ghostty.git/?ref=HEAD#53bd14fecfd68c6c0ab64d37b5943247299e2b40" "git+https://github.com/ghostty-org/ghostty.git/?ref=HEAD#c74f6d56d1feef473033057bc0ff7e3f00cf6421" \
        --replace-fail "ghostty-1.3.2-dev-5UdBC7meIAWzGmyD-DFyCREkFQyRFzHTZZ2heWLRXl5X" "ghostty-1.3.2-dev-5UdBC8HuDgWFQtz8pKQ-0HH6z0Cb_PKbI0R7AunQhdDF"
    '';
  });
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
