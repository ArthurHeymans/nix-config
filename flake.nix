{
  description = "Arthur Heymans's nix configuration for NixOS";

  # Add outputs in here for now
  # outputs = inputs: import ./outputs inputs;

  # This is the standard format for flake.nix. `inputs` are the dependencies of the flake,
  # Each item in `inputs` will be passed as a parameter to the `outputs` function after being pulled and built.
  inputs = {
    # There are many ways to reference flake inputs. The most widely used is github:owner/name/reference,
    # which represents the GitHub repository URL + branch/commit-id/tag.

    # Official NixOS package source, using nixos's stable branch by default
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11"; #stable
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; #unstable
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      # url = "github:nix-community/home-manager/release-24.11";

      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs dependencies.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";

    # add git hooks to format nix code before commit
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      # Optional, to download less. Neither the module nor the overlay uses this input.
      inputs.nixpkgs.follows = "";
    };

    ########################  Some non-flake repositories  #########################################

    ########################  My own repositories  #########################################

    doom-config = {
      url = "github:ArthurHeymans/.doom.d";
      flake = false;
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Determinate: downstream Nix + Nixd module for NixOS
    # Use FlakeHub URL as recommended by Determinate docs
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

    # other rust toolchain
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    niri,
    determinate,
    ...
  } @ inputs: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    nixosConfigurations = let
      username = "arthur";
      system = "x86_64-linux";
      specialArgs = {
        inherit username;
        # pkgs = import nixpkgs {
        #   inherit system;
        #   config.allowUnfree = true;
        # };
        # pkgs-unstable = import nixpkgs-unstable {
        #   inherit system;
        #   config.allowUnfree = true;
        # };
        inherit inputs;
      };
    in {
      x220-nixos = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = [
          ./hosts/x220-nixos
          ./users/${username}/nixos.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.extraSpecialArgs = specialArgs // inputs;
            home-manager.users.${username} = import ./users/${username}/home.nix;
          }
        ];
      };
      t14s-g6 = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = [
          ./hosts/t14s-g6
          ./users/${username}/nixos.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.extraSpecialArgs = specialArgs // inputs;
            home-manager.users.${username} = import ./users/${username}/home.nix;
          }
        ];
      };
      gmktec-k11 = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = [
          ./hosts/gmktec-k11
          ./users/${username}/nixos.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            home-manager.extraSpecialArgs = specialArgs // inputs;
            home-manager.users.${username} = import ./users/${username}/home.nix;
          }
        ];
      };
    };
  };
}
