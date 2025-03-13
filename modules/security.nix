{...}: {
  services.pcscd.enable = true;
  security.polkit.enable = true;
  security.rtkit.enable = true;
  services.passSecretService.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.greetd.enableKwallet = true;
}
