{ writeShellApplication, nodejs }:

# Pin the CLI; npx caches its npm dependencies on first use. This is a launcher,
# not a fully vendored/offline Nix build of the npm dependency tree.
writeShellApplication {
  name = "playwriter";
  runtimeInputs = [ nodejs ];
  text = ''
    export PLAYWRITER_TELEMETRY=0
    exec npx --yes playwriter@0.9.0 "$@"
  '';
}
