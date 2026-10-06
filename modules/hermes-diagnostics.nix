{ lib, pkgs, ... }:
{
  # Separate from Arthur's login: no wheel, sudo, or Nix trusted-user access.
  # Journal access is useful for diagnosis, but logs can contain secrets.
  users.users.hermes-diagnostics = {
    isSystemUser = true;
    group = "hermes-diagnostics";
    extraGroups = [ "systemd-journal" ];
    home = "/var/lib/hermes-diagnostics";
    createHome = true;
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [
      ''restrict,from="100.64.0.0/10,fd7a:115c:a1e0::/48" ${lib.trim (builtins.readFile ../secrets/hermes-ssh-key.pub)}''
    ];
  };
  users.groups.hermes-diagnostics = { };
}
