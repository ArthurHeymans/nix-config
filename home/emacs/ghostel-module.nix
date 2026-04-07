# Pre-built ghostel native module for Emacs.
# Ghostel links libghostty-vt statically, so the .so only depends on glibc.
# Building from source requires zig + the full ghostty vendored submodule
# with all its dependencies, so we use the upstream release binary instead.
{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  autoPatchelfHook,
}:
let
  version = "0.7.1";
  src = fetchFromGitHub {
    owner = "dakra";
    repo = "ghostel";
    rev = "v${version}";
    hash = "sha256-uLZG3XMpGIkCkYLT7kVZd8jpYzavEsCYP5Qgm/WFMsA=";
  };
  prebuiltModule = fetchurl {
    url = "https://github.com/dakra/ghostel/releases/download/v${version}/ghostel-module-x86_64-linux.so";
    hash = "sha256-yDFOUTmr9ZO0rL6WymLmZqaUPEvO43fUO7IR7BY/dNc=";
  };
in
stdenv.mkDerivation {
  pname = "ghostel-module";
  inherit version src;

  nativeBuildInputs = [ autoPatchelfHook ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm555 ${prebuiltModule} $out/lib/ghostel-module.so
    install -Dm444 -t $out/etc etc/ghostel.*

    runHook postInstall
  '';

  meta = {
    description = "Ghostel native Emacs module (libghostty-vt terminal emulator)";
    homepage = "https://github.com/dakra/ghostel";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
  };
}
