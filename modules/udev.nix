{ pkgs, ... }:

let
  glasgow = pkgs.glasgow.overridePythonAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace software/pyproject.toml \
        --replace-fail '"importlib_resources~=6.5.2",' '"importlib_resources>=6.5.2",'
    '';
  });
in
{
  hardware.keyboard.qmk.enable = true;

  services.udev.packages = [
    glasgow
    pkgs.probe-rs-tools
  ];

  # tool to figure out jtag
  environment.systemPackages = [ glasgow ];

  # Programmer and flashing hardware without packaged udev rules.
  services.udev.extraRules = ''
    # EM100
    SUBSYSTEM=="usb", ATTR{idVendor}=="04b4", ATTR{idProduct}=="1235", MODE="0666", TAG+="uaccess"
    # CH341A
    SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="5512", MODE="0666", TAG+="uaccess"
    # CH347T
    SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="55db", MODE="0666", TAG+="uaccess"
    # CH347F
    SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="55de", MODE="0666", TAG+="uaccess"
    # FT4222
    SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="601c", MODE="0666", TAG+="uaccess"
    # Dediprog SF100/SF200/SF600/SF700 (VID:0483 PID:dada)
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="dada", MODE="0666", TAG+="uaccess"
    # 1f3a:efe8 Allwinner Technology sunxi SoC OTG connector in FEL/flashing mode
    SUBSYSTEM=="usb", ATTR{idVendor}=="1f3a", ATTR{idProduct}=="efe8", MODE="0666", TAG+="uaccess"
    # Raiden Debug SPI / Cr50 (Google debug hardware, VID:18d1; product ID varies)
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", TAG+="uaccess"
  '';
}
