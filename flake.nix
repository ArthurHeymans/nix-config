{
  description = "Arthur Heymans's nix configuration for NixOS";

  # Add outputs in here for now
  # outputs = inputs: import ./outputs inputs;

  # This is the standard format for flake.nix. `inputs` are the dependencies of the flake,
  # Each item in `inputs` will be passed as a parameter to the `outputs` function after being pulled and built.
  inputs = {
    # There are many ways to reference flake inputs. The most widely used is github:owner/name/reference,
    # which represents the GitHub repository URL + branch/commit-id/tag.

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11"; #stable
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; #unstable
    # nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

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

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ewm = {
      # url = "git+https://codeberg.org/ezemtsov/ewm";
      url = "git+https://codeberg.org/avph/ewm?ref=EmacsScreencast";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ########################  Some non-flake repositories  #########################################

    ########################  My own repositories  #########################################

    doom-config = {
      url = "github:ArthurHeymans/.doom.d";
      flake = false;
    };

    #el-be-back = {
    #  url = "github:ArthurHeymans/el-be-back";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sysc-greet = {
      url = "github:Nomadcxx/sysc-greet";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zmx.url = "github:neurosnap/zmx";
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    username = "arthur";
    system = "x86_64-linux";
    specialArgs = {
      inherit username inputs;
    };

    mkNixos = {
      hostname,
      homeModule,
      extraModules ? [],
    }:
      nixpkgs.lib.nixosSystem {
        specialArgs =
          specialArgs
          // {
            inherit hostname;
          };
        modules =
          [
            ./hosts/${hostname}
            ./users/${username}/nixos.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = (specialArgs // {inherit hostname;}) // inputs;
              home-manager.users.${username} = import homeModule;
            }
          ]
          ++ extraModules;
      };

    mkSystem = hostname:
      mkNixos {
        inherit hostname;
        homeModule = ./users/${username}/home.nix;
        extraModules = [
          inputs.niri.nixosModules.niri
          inputs.sysc-greet.nixosModules.default
          inputs.ewm.nixosModules.default
        ];
      };

    mkServer = hostname:
      mkNixos {
        inherit hostname;
        homeModule = ./users/${username}/server-home.nix;
      };
  in {
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;
    nixosConfigurations = {
      x220-nixos = mkSystem "x220-nixos";
      t14s-g6 = mkSystem "t14s-g6";
      gmktec-k11 = mkSystem "gmktec-k11";
      gmktec-g3 = mkServer "gmktec-g3";
      t480-arthur = mkSystem "t480-arthur";
      x201-arthur = mkSystem "x201-arthur";
      x61-arthur = mkSystem "x61-arthur";
    };
  };
}
