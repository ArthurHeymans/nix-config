{
  inputs,
  pkgs,
  ...
}:
let
  # ponytail: compatibility override until flake.lock pins the fixed rflasher package.
  rflasher = inputs.rflasher.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    cargoDeps = pkgs.rustPlatform.importCargoLock {
      lockFile = "${inputs.rflasher}/Cargo.lock";
      outputHashes = {
        "ftdi-0.1.0" = "sha256-dRQqF6TOXLGL6+XW+Y+dSeYbbwpvXTocbq7+FVDv3Og=";
        "nusb-0.2.1" = "sha256-5GrOwak/hiRDNg/CZWcYPYCwxGMZTKEPdIMBJ7D2naI=";
      };
    };
    cargoBuildFlags = [ "--package=rflasher" ];
    cargoTestFlags = [ "--package=rflasher" ];
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.installShellFiles ];

    postPatch = ''
      substituteInPlace src/main.rs \
        --replace-fail 'PathBuf::from("/usr/share/rflasher/chips"),' \
          "PathBuf::from(\"$out/share/rflasher/chips\"),"
    '';

    postInstall = ''
      install -Dm644 chips/vendors/*.ron -t $out/share/rflasher/chips

      completion_generator=$(find target -type f -name gen-completions -perm -0100 -print -quit)
      if [ -n "$completion_generator" ]; then
        completion_dir=$(mktemp -d)
        "$completion_generator" "$completion_dir"
        installShellCompletion --cmd rflasher \
          --bash "$completion_dir/rflasher.bash" \
          --zsh "$completion_dir/_rflasher" \
          --fish "$completion_dir/rflasher.fish"
      fi
    '';
  });
in
{
  # Desktop/development packages shared by laptop and workstation systems.
  environment.systemPackages = with pkgs; [
    acpi
    acpica-tools
    brightnessctl
    coreboot-utils
    deadnix
    em100
    flashprog
    gnupg
    haveged
    hdparm
    linux-wifi-hotspot # TODO re-enable when fixed
    nil
    nix-output-monitor
    nixfmt
    parted
    psmisc
    rflasher
    statix
    wavemon
    wifi-qr
    zellij
    zmx
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.nix-ld.enable = true;
}
