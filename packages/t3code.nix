{
  pkgs,
  inputs,
  lib,
}:
let
  t3codeVersion = "0.0.44-everythingarthur.2591c1f5";
  # The EverythingArthur fork's vite `t3code:third-party-licenses` plugin downloads
  # SPDX license texts from raw.githubusercontent.com during the production
  # build, but the Nix sandbox has no network and `/.generated/` (its cache
  # directory) is gitignored. Pre-seed that cache with pinned fetchers so
  # the build stays offline. Coupled to SPDX_LICENSE_LIST_VERSION/REVISION
  # and the `generatedNotices` license IDs in the t3code source; if those
  # change, the build will fail with a fetch error and this needs updating.
  spdxLicenseRevision = "c4a7237ec8f4654e867546f9f409749300f1bf4c";
  spdxLicenseCache = pkgs.linkFarm "t3code-spdx-licenses" (
    lib.mapAttrsToList
      (licenseId: hash: {
        name = "${licenseId}.json";
        path = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/spdx/license-list-data/${spdxLicenseRevision}/json/details/${licenseId}.json";
          inherit hash;
        };
      })
      {
        "Apache-2.0" = "sha256-iyt7wmfXAL6UCFzSyDA+Atj4ODKLKnMQ3DqIQNPKErs=";
        "BSD-2-Clause" = "sha256-h2hDpwacR4mNECQyo1vjMqRXz3r/gJTMsYqj315jQJI=";
        "BSD-3-Clause" = "sha256-RXYFS3RBfUAh/9ovY7h/3lJ5Hj7ZTu7yznkwJRtDcwE=";
        "CC0-1.0" = "sha256-gdRg6RFSHhS1Ky/Y4Gl5Wscx6JhspYpdKUFdzAHqoSU=";
        "ISC" = "sha256-VJTDV7IdtsBt1r1r1J1ldZINPVNDQE5vVFkWPmjn5Yo=";
        "MIT" = "sha256-fuCJ3MxiW/GLCrHoDgxLysVYeIT1viXZATuK1sYd1Dk=";
        "Unlicense" = "sha256-itR5uQEH/xGJKbe09Fvk/axB/Aq0J6LEIbwwY52X4fs=";
      }
  );
  t3codeUnwrapped = pkgs.t3code.unwrapped.overrideAttrs (
    finalAttrs: previousAttrs: {
      version = t3codeVersion;
      src = inputs.t3code-src;

      # t3code 0.0.40 compiles a native browser-import helper (and the desktop
      # keyring addon) against libsecret, which the nixpkgs 0.0.38 expression
      # does not pass build inputs for yet. Mirrors current nixpkgs master.
      nativeBuildInputs =
        previousAttrs.nativeBuildInputs
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.pkg-config ];
      buildInputs =
        (previousAttrs.buildInputs or [ ])
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.libsecret ];
      postInstall =
        (previousAttrs.postInstall or "")
        + lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
          install -Dm755 \
            native/browser-secret/build/${pkgs.stdenv.hostPlatform.node.arch}/t3-browser-secret \
            "$out"/libexec/t3code/apps/desktop/prod-resources/browser-secret/t3-browser-secret
        '';

      postPatch = (previousAttrs.postPatch or "") + ''
        # Embed the public production Connect settings in the CLI and desktop builds.
        cp .env.example .env
        mkdir -p .generated/third-party-licenses/spdx/v3.28.0
        chmod -R u+w .generated
        cp ${spdxLicenseCache}/*.json .generated/third-party-licenses/spdx/v3.28.0/
      '';

      pnpmDeps = pkgs.fetchPnpmDeps {
        inherit (finalAttrs)
          pname
          version
          src
          pnpmWorkspaces
          ;
        pnpm = pkgs.pnpm_11;
        fetcherVersion = 4;
        hash = "sha256-yMHoqvIpfLnROuEgts+Q6ZVisJZbzPiBzceg9XKz/Jo=";
      };
    }
  );
  t3codeResourceMonitor = pkgs.t3code.resourceMonitor.overrideAttrs {
    version = t3codeVersion;
    src = inputs.t3code-src;
  };
in
pkgs.t3code.override {
  enableJujutsu = true;
  t3code-unwrapped = t3codeUnwrapped;
  t3code-resource-monitor = t3codeResourceMonitor;
}
