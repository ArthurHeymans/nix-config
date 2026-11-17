{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  arch = stdenvNoCC.hostPlatform.parsed.cpu.name;
  # Verified against the upstream signed v2.1.0 SHA256SUMS.
  hashes = {
    x86_64 = "sha256-pi2rWGPQ5/Y00FtByqXqRFQbtOpShXTlsgiAjfTuajQ=";
    aarch64 = "sha256-iMlkWUcKU86MM9PgZ5ePAkeEZFDhRhO1L9rwSfmkAjQ=";
  };
in
stdenvNoCC.mkDerivation (final: {
  pname = "qsh";
  version = "2.1.0";
  src = fetchurl {
    url = "https://github.com/VLOD-ZDOV/quic-ssh/releases/download/v${final.version}/qsh-${arch}-linux.tar.gz";
    hash = hashes.${arch};
  };
  dontBuild = true;
  dontStrip = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 qsh "$out/bin/qsh"
    install -Dm755 qshd "$out/bin/qshd"
    install -Dm644 LICENSE "$out/share/licenses/qsh/LICENSE"
    runHook postInstall
  '';
  meta = {
    description = "SSH-like remote shell over QUIC, with TLS/TCP fallback";
    homepage = "https://github.com/VLOD-ZDOV/quic-ssh";
    license = lib.licenses.gpl3Only;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "qsh";
  };
})
