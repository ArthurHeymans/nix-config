{
  pkgs,
  inputs,
  lib,
}:
let
  sourceVersion =
    (builtins.fromJSON (builtins.readFile (inputs.t3code-src + "/apps/server/package.json"))).version;
  t3codeVersion = "${sourceVersion}-everythingarthur.${builtins.substring 0 8 inputs.t3code-src.rev}";
  t3codeUnwrapped = pkgs.t3code.unwrapped.overrideAttrs (
    finalAttrs: previousAttrs: {
      version = t3codeVersion;
      src = inputs.t3code-src;

      postPatch = (previousAttrs.postPatch or "") + ''
        # Embed the public production Connect settings in the CLI and desktop builds.
        cp .env.example .env
      '';

      pnpmDeps = pkgs.fetchPnpmDeps {
        inherit (finalAttrs)
          pname
          version
          src
          pnpmWorkspaces
          ;
        pnpm = pkgs.pnpm_12;
        fetcherVersion = 5;
        hash = "sha256-mnk//lvHJbON8MRoOAIA5dXX1r7pHJvW5q+/Lqk5MRk=";
      };
    }
  );
  t3codeResourceMonitor = pkgs.t3code.resourceMonitor.overrideAttrs {
    version = t3codeVersion;
    src = inputs.t3code-src;
  };
  t3code = pkgs.t3code.override {
    enableJujutsu = true;
    t3code-unwrapped = t3codeUnwrapped;
    t3code-resource-monitor = t3codeResourceMonitor;
  };
  # T3 downloads its headless browser at runtime, outside autoPatchelf's reach.
  # Keep its libraries local to T3 and inherited by the browser subprocesses.
  browserLibraryPath = lib.makeLibraryPath (
    with pkgs;
    [
      glib
      nspr
      nss
      atk
      at-spi2-atk
      dbus
      libX11
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libXrandr
      libgbm
      expat
      libxcb
      libxkbcommon
      systemd
      alsa-lib
      at-spi2-core
    ]
  );
in
if pkgs.stdenv.hostPlatform.isLinux then
  pkgs.symlinkJoin {
    name = "t3code-${t3codeVersion}";
    paths = [ t3code ];
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      for program in t3 t3code-desktop; do
        rm "$out/bin/$program"
        makeWrapper "${t3code}/bin/$program" "$out/bin/$program" \
          --prefix LD_LIBRARY_PATH : ${lib.escapeShellArg browserLibraryPath}
      done
    '';
    inherit (t3code) meta passthru;
  }
else
  t3code
