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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    # TODO see if needed later
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable-small";
    # nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # home-manager, used for managing user configuration
    home-manager = {
      # url = "github:nix-community/home-manager/master";
      url = "github:nix-community/home-manager/release-24.11";

      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs dependencies.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # TODO secure boot for nixos
    # lanzaboote = {
    #   url = "github:nix-community/lanzaboote/v0.4.1";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # TODO no persistence on nixos
    # impermanence.url = "github:nix-community/impermanence";

    # TODO do I want?
    # community wayland nixpkgs
    # nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    # anyrun - a wayland launcher
    # anyrun = {
    #   url = "github:Kirottu/anyrun";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # TODO generate images for ISO, docker, ...
    # generate iso/qcow2/docker/... image from nixos configuration
    # nixos-generators = {
    #   url = "github:nix-community/nixos-generators";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    sops-nix.url = "github:Mic92/sops-nix";

    # nix-gaming.url = "github:fufexan/nix-gaming";

    # Set up disks from nixos
    # disko = {
    #   url = "github:nix-community/disko/v1.6.1";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # add git hooks to format nix code before commit
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # TODO filesystem based modules in Nix
    # haumea = {
    #   url = "github:nix-community/haumea/v0.2.2";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # TODO runtime sandboxing
    # nixpak = {
    #   url = "github:nixpak/nixpak";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      # Optional, to download less. Neither the module nor the overlay uses this input.
      inputs.nixpkgs.follows = "";
    };

    # anyrun = {
    #   url = "github:anyrun-org/anyrun";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    ########################  Some non-flake repositories  #########################################

    doom-config = {
      url = "github:ArthurHeymans/.doom.d";
      flake = false;
    };

    # doom-emacs is a configuration framework for GNU Emacs.
    # doomemacs = {
    #   url = "github:doomemacs/doomemacs";
    #   flake = false;
    # };

    # TODO I will use waybar?
    # polybar-themes = {
    #   url = "github:adi1090x/polybar-themes";
    #   flake = false;
    # };

    ########################  My own repositories  #########################################

    # my private secrets, it's a private repository, you need to replace it with your own.
    # use ssh protocol to authenticate via ssh-agent/ssh-key, and shallow clone to save time
    # mysecrets = {
    #   url = "git+ssh://git@github.com/ryan4yin/nix-secrets.git?shallow=1";
    #   flake = false;
    # };

    # # my wallpapers
    # wallpapers = {
    #   url = "github:ryan4yin/wallpapers";
    #   flake = false;
    # };

    # nur-ryan4yin.url = "github:ryan4yin/nur-packages";
    # nur-ataraxiasjel.url = "github:AtaraxiaSjel/nur";
  };

  outputs = {
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    ...
  } @ inputs: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    nixosConfigurations = {
      x220-nixos = let
        username = "arthur";
        system = "x86_64-linux";
        specialArgs = {
          inherit username;
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
          inherit inputs;
        };
      in
        nixpkgs.lib.nixosSystem {
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
    };
  };
}
