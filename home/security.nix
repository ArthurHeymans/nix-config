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
      allow-emacs-pinentry
    '';
    pinentryPackage = pkgs.pinentry-gnome3;
  };
}
