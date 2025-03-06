{pkgs, config, ...}: {
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
    ];
  };

  # Load NVIDIA driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Modesetting is required
    modesetting.enable = false;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (only for Turing and later architectures)
    open = false;

    # Enable the Nvidia settings menu
    nvidiaSettings = true;

    # Select the appropriate driver version
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # thunderbolt
  services.hardware.bolt.enable = true;
}
