{ inputs, pkgs }:
let
  system = pkgs.stdenv.hostPlatform.system;
  # Reuse the upstream recipe with the system's overlays and license policy.
  outputs = (import "${inputs.sysc-greet}/flake.nix").outputs (
    inputs.sysc-greet.inputs
    // {
      self = inputs.sysc-greet;
      nixpkgs = inputs.nixpkgs // {
        legacyPackages.${system} = pkgs;
      };
    }
  );
in
outputs.packages.${system}.default
