{ inputs, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    age.sshKeyPaths = [ "/home/arthur/.ssh/id_ed25519" ];
    secrets.nix_serve_private_key = {
      sopsFile = ../secrets/nix-serve-key.yaml;
      mode = "0400";
    };
  };

  services.nix-serve = {
    enable = true;
    bindAddress = "0.0.0.0";
    secretKeyFile = "/run/secrets/nix_serve_private_key";
  };

  networking.firewall.allowedTCPPorts = [ 5000 ];
}
