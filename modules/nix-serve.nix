{ inputs, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
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
