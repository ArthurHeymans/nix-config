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
  version = "0.14.0";
  src = fetchFromGitHub {
    owner = "dakra";
    repo = "ghostel";
    rev = "v${version}";
    hash = "sha256-QycHizu59inuZkBsHqOx2sOf0wkIq64K9t2xM2QL1pY=";
  };
  prebuiltModule = fetchurl {
    url = "https://github.com/dakra/ghostel/releases/download/v${version}/ghostel-module-x86_64-linux.so";
    hash = "sha256-iALk4pAVTk/vG6CDSUCpCgrNzMBbORBwEgKo0bRRiwI=";
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
