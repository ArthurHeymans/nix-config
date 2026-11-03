{
  inputs,
  pkgs,
  ...
}:
let
  # Build only the CLI package and install completions when available.
  rflasher = inputs.rflasher.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    cargoBuildFlags = [ "--package=rflasher" ];
    cargoTestFlags = [ "--package=rflasher" ];
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.installShellFiles ];

    postInstall = ''
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
  environment.systemPackages = [
    pkgs.flashprog
    rflasher
  ];
}
