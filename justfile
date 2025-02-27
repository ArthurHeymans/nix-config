# System update and maintenance commands

# Rebuild NixOS system with the t14s-g6 configuration
rebuild:
  sudo nixos-rebuild switch --flake ~/nix-config#t14s-g6

# Update the doom-config flake
update-doom:
  nix flake update doom-config

# Update all flakes
update:
  nix flake update
