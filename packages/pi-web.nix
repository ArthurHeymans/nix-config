{
  lib,
  buildNpmPackage,
  nodejs_22,
  jq,
  runCommand,
  src,
}:

let
  patchedSrc = runCommand "pi-web-source" { nativeBuildInputs = [ jq ]; } ''
    cp -r ${src} "$out"
    chmod -R u+w "$out"
    jq '
      .packages as $packages
      | .packages |= with_entries(
          if (.key | startswith("node_modules/"))
            and .value.integrity == null
            and .value.resolved != null
          then
            (.key | split("/node_modules/") | last | "node_modules/" + .) as $root
            | if $packages[$root].integrity != null then
                .value.integrity = $packages[$root].integrity
              elif $root == "node_modules/@earendil-works/pi-tui" then
                .value.integrity = "sha512-9yN8hALfKaxZq7n54EMxqhFCWnMi6LHkraMJ/1YjHiATq75XrI6XDMVppn9EDtiK7Fks8hUe1SDXUTrIvwRWfQ=="
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
  npmDepsHash = "sha256-fMGDqXVySgibDnclng0dXkcj6OUGr3fhZkkBgxQLzVM=";
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
