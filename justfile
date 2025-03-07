# System update and maintenance commands

# Rebuild NixOS system with the current hostname configuration
rebuild:
  sudo nixos-rebuild switch --flake ~/nix-config#$(hostname)

# Update the doom-config flake
update-doom:
  nix flake update doom-config

# Update all flakes
update:
  nix flake update
