{ pkgs, ... }:
{
  hardware.keyboard.qmk.enable = true;

  services.udev.packages = [
    # Device permissions only need the rules, not Glasgow's Python/FPGA toolchain.
    (pkgs.runCommand "glasgow-udev-rules" { } ''
      install -Dm644 ${pkgs.glasgow.src}/config/*.rules -t "$out/etc/udev/rules.d"
    '')
    pkgs.probe-rs-tools
  ];

  # Programmer and flashing hardware without packaged udev rules.
  services.udev.extraRules = ''
    # EM100
    SUBSYSTEM=="usb", ATTR{idVendor}=="04b4", ATTR{idProduct}=="1235", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    # CH341A
    SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="5512", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    # CH347T
    SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="55db", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    # CH347F
    SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="55de", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    # FT4222
    SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="601c", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    # Dediprog SF100/SF200/SF600/SF700 and DediBridge runtime (VID:0483 PID:dada)
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="dada", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    # DediBridge installer: original Pico / Pico H ROM bootloader (BOOTSEL).
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="2e8a", ATTR{idProduct}=="0003", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    # DediBridge installer: WCH USB ISP bootloader (not WCH-Link/CH340).
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="4348", ATTR{idProduct}=="55e0", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="1a86", ATTR{idProduct}=="55e0", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    # 1f3a:efe8 Allwinner Technology sunxi SoC OTG connector in FEL/flashing mode
    SUBSYSTEM=="usb", ATTR{idVendor}=="1f3a", ATTR{idProduct}=="efe8", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    # Raiden Debug SPI: Cr50, Ti50, and Servo Micro
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="5014", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="504a", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="501a", MODE="0660", GROUP="plugdev", TAG+="uaccess"
  '';
}
