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

    pi-web = {
      url = "github:ArthurHeymans/pi-web/feat/jj-plugin";
      flake = false;
    };

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
      # Track master until the next release after v1.0.0: nixpkgs removed the
      # now-obsolete boot.bootspec.enable option that v1.0.0 still defines.
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ewm = {
      url = "git+https://codeberg.org/ezemtsov/ewm";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Native Wayland/Skia Emacs maintained by the EWM author.
    emacs-wayland = {
      url = "git+https://codeberg.org/ezemtsov/emacs?ref=wayland";
      flake = false;
    };

    ########################  Some non-flake repositories  #########################################

    ########################  My own repositories  #########################################

    rflasher = {
      url = "github:ArthurHeymans/rflasher";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    doom-config = {
      url = "github:ArthurHeymans/.doom.d";
      flake = false;
    };

    #el-be-back = {
    #  url = "github:ArthurHeymans/el-be-back";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};

    # Temporarily disabled while niri's current package is incompatible with nixpkgs.
    # niri = {
    #   url = "github:sodiboo/niri-flake";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    sysc-greet = {
      url = "github:Nomadcxx/sysc-greet";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gslapper.follows = "sysc-greet/gslapper";

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    google-workspace-cli = {
      url = "github:googleworkspace/cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zmx.url = "github:neurosnap/zmx";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      username = "arthur";
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      preCommitCheck = inputs.pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks.nixfmt.enable = true;
      };
      hosts = {
        x220-nixos = {
          kind = "desktop";
          sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK9XttA9f8RjXTrrhli5lb4y4+uWC7K+uu2yaeLCbWCT arthur@x220-nixos";
        };
        t14s-g6 = {
          kind = "desktop";
          sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGdvTWjJ4Q/XlCV9ziyFkWxvDsMs+veo9uQQBSPZGZB+ arthur@t14s-g6";
        };
        gmktec-k11 = {
          kind = "desktop";
          sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAB1w5zIFawrgTrTXzVfpbV9t7d/FBUm/15NZz40McEA arthur@gmktec-k11";
        };
        gmktec-g3 = {
          kind = "server";
          buildOnUpdate = false;
        };
        t480-arthur = {
          kind = "desktop";
          sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOIhZlW5JLnPVAWQCKGhPcDhhq0jlQamjI6wCx5UKAXZ arthur@t480-arthur";
        };
        x201-arthur = {
          kind = "desktop";
          sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG7kI68/elpmRp017AlpcbWPrWQwjgzcS00VsDdOJhvs arthur@x201-arthur";
        };
        x61-arthur = {
          kind = "desktop";
          buildOnUpdate = false;
          sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGLia2BubtMLFw1tDiDdDtIRcG2Pg0Nl8vTS8q0Z1tng arthur@x61-arthur";
        };
      };
      updateHostNames = builtins.attrNames (
        nixpkgs.lib.filterAttrs (_: host: host.buildOnUpdate or true) hosts
      );
      specialArgs = {
        inherit
          username
          inputs
          hosts
          updateHostNames
          ;
      };

      mkNixos =
        {
          hostname,
          homeModule,
          extraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          specialArgs = specialArgs // {
            inherit hostname;
          };
          modules = [
            ./hosts/${hostname}
            ./users/${username}/nixos.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit username inputs hostname;
              };
              home-manager.users.${username} = import homeModule;
            }
          ]
          ++ extraModules;
        };

      mkSystem =
        hostname:
        mkNixos {
          inherit hostname;
          homeModule = ./users/${username}/home.nix;
          extraModules = [
            # inputs.niri.nixosModules.niri
            inputs.ewm.nixosModules.default
          ];
        };

      mkServer =
        hostname:
        mkNixos {
          inherit hostname;
          homeModule = ./users/${username}/server-home.nix;
        };
    in
    {
      checks.${system}.pre-commit-check = preCommitCheck;

      devShells.${system}.default = pkgs.mkShell {
        shellHook = preCommitCheck.shellHook;
        buildInputs = preCommitCheck.enabledPackages;
      };

      formatter.${system} = pkgs.writeShellApplication {
        name = "nixfmt-repo";
        runtimeInputs = [
          pkgs.findutils
          pkgs.nixfmt
        ];
        text = ''
          if [ "$#" -eq 0 ]; then
            find . \
              -path ./.git -prune -o \
              -path ./.jj -prune -o \
              -path ./.pi-lens -prune -o \
              -path ./result -prune -o \
              -type f -name '*.nix' -print0 \
              | xargs -0 --no-run-if-empty nixfmt
          else
            nixfmt "$@"
          fi
        '';
      };

      nixosConfigurations = nixpkgs.lib.mapAttrs (
        hostname: host: if host.kind == "server" then mkServer hostname else mkSystem hostname
      ) hosts;
    };
}
