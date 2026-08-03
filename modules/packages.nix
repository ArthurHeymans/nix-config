{
  inputs,
  pkgs,
  ...
}:
let
  # Add runtime data and shell completions missing from the upstream package.
  rflasher = inputs.rflasher.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    cargoBuildFlags = [ "--package=rflasher" ];
    cargoTestFlags = [ "--package=rflasher" ];
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.installShellFiles ];

    postPatch = ''
      substituteInPlace src/main.rs \
        --replace-fail 'PathBuf::from("/usr/share/rflasher/chips"),' \
          "PathBuf::from(\"$out/share/rflasher/chips\"),"
    '';

    postInstall = ''
      install -Dm644 crates/rflasher-chips/data/vendors/*.ron -t $out/share/rflasher/chips

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
