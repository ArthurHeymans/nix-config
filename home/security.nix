{pkgs, ...}: {
  programs.gpg = {
    enable = true;
  };
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableExtraSocket = true;
    enableFishIntegration = true;
    extraConfig = ''
      allow-loopback-pinentry
    '';
    # allow-emacs-pinentry
    pinentry.package = pkgs.pinentry-gnome3;
    defaultCacheTtl = 604800;
    maxCacheTtl = 604800;
  };
  home.packages = with pkgs; [
    sops
    gcr
  ];
}
