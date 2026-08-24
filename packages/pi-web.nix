{
  lib,
  buildNpmPackage,
  nodejs_22,
  jq,
  runCommand,
  src,
}:

let
  # Some @earendil-works packages are published without integrity hashes in
  # package-lock.json; npm-deps refuses those unless they are git deps.
  # These SRIs were computed from the registry tarballs.
  missingIntegrities = {
    "node_modules/@earendil-works/pi-client" = "sha512-/V5hGHE4Zq+jG0GtwIB9PyBUOGd6gBLZ7lkQYFKchKnxYHeH3rmWC5xw4kpnZKKBuBuFTdLVbU9vEjlAGMMb2A==";
    "node_modules/@earendil-works/pi-protocol" = "sha512-Ox1pciyeSPGEEUcxvR0/dJcrY7C6hrEGA8y71rOsvSIUlXN1Cbp/be/eoL71OGDBk5O97TeQPfWN6Ju/2Ehjww==";
    "node_modules/@earendil-works/pi-tui" = "sha512-udeXFbgEhJ6JiB0uguwNVNkDy2FENfmtQwPcY+/iJ8GWeq18wkal1tKqa5YyeH0IqtX1vG0cGh8zfSYzyzVuLA==";
  };
  patchedSrc = runCommand "pi-web-source"
    {
      nativeBuildInputs = [ jq ];
      passAsFile = [ "integrities" ];
      integrities = builtins.toJSON missingIntegrities;
    }
    ''
    cp -r ${src} "$out"
    chmod -R u+w "$out"
    jq --slurpfile integrities "$integritiesPath" '
      ($integrities[0]) as $sris
      | .packages as $packages
      | .packages |= with_entries(
          if (.key | startswith("node_modules/"))
            and .value.integrity == null
            and .value.resolved != null
          then
            (.key | split("/node_modules/") | last | "node_modules/" + .) as $root
            | if $packages[$root].integrity != null then
                .value.integrity = $packages[$root].integrity
              elif $sris[$root] != null then
                .value.integrity = $sris[$root]
              else .
              end
          else .
          end
        )
    ' "$out/package-lock.json" > "$out/package-lock.json.new"
    mv "$out/package-lock.json.new" "$out/package-lock.json"
  '';
in
buildNpmPackage rec {
  pname = "pi-web";
  version = (lib.importJSON "${src}/package.json").version;

  src = patchedSrc;

  nodejs = nodejs_22;
  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-JCWlPiKeadi9kSc4rMHW5b3zRqmEVoiRFJSU4qrUQE0=";
  npmInstallFlags = [ "--include=peer" ];
  npmPruneFlags = [ "--include=peer" ];

  preInstall = ''
    node <<'NODE'
    const fs = require("node:fs");
    const packageJson = JSON.parse(fs.readFileSync("package.json", "utf8"));
    for (const name of [
      "@earendil-works/pi-agent-core",
      "@earendil-works/pi-ai",
      "@earendil-works/pi-coding-agent",
    ]) {
      packageJson.dependencies[name] = packageJson.devDependencies[name];
      delete packageJson.devDependencies[name];
    }
    fs.writeFileSync("package.json", `''${JSON.stringify(packageJson, null, 2)}\n`);
    NODE
  '';

  postInstall = ''
    package_dir="$out/lib/node_modules/@jmfederico/pi-web"
    if [ ! -x "$package_dir/node_modules/.bin/pi" ]; then
      echo "The Pi Coding Agent peer dependency did not provide its CLI" >&2
      exit 1
    fi
  '';

  meta = {
    description = "Web UI for persistent Pi Coding Agent sessions in real workspaces";
    homepage = "https://pi-web.dev/";
    license = lib.licenses.mit;
    mainProgram = "pi-web";
    platforms = lib.platforms.linux;
  };
}
