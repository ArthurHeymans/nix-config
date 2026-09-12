{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  piNode = inputs.llm-agents.packages.${system}.pi.override { useBun = false; };
  t3codeVersion = "0.0.40-piresume.db4155c4";
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

      pnpmDeps = pkgs.fetchPnpmDeps {
        inherit (finalAttrs)
          pname
          version
          src
          pnpmWorkspaces
          ;
        pnpm = pkgs.pnpm_11;
        fetcherVersion = 4;
        hash = "sha256-FsEMNkabp2Nn3DWazt/a3CH0A5iwimKTb/L0cnaExVM=";
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
  t3codeServer = pkgs.writeShellScript "t3code-server" ''
    while ${lib.getExe pkgs.netcat-openbsd} -z 127.0.0.1 13773 >/dev/null 2>&1; do
      ${pkgs.coreutils}/bin/sleep 5
    done
    exec ${lib.getExe' t3code "t3"} serve --host 0.0.0.0 --port 13773
  '';
  jj-hunk = pkgs.rustPlatform.buildRustPackage rec {
    pname = "jj-hunk";
    version = "0.3.0";

    src = pkgs.fetchCrate {
      inherit pname version;
      hash = "sha256-tuMYEmYhwRLS7pSqS1C+DjNZKZcH4FHsRWmZtUSVBY8=";
    };

    cargoHash = "sha256-S8m3+wFebuezIwqW9Lxtd7PcDUfwJu1VeLMjJopqcSE=";

    # Integration tests shell out to `jj-hunk` itself before the binary is
    # installed in PATH; `cargo install --locked jj-hunk` succeeds locally.
    doCheck = false;
  };
in
{
  home.packages = with pkgs; [
    entire
    piNode
    jj-hunk
    jq # often used for parsing nixos output in AI agents
    t3code
  ];

  systemd.user.services.t3code = {
    Unit = {
      Description = "T3 Code server";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      ExecStart = t3codeServer;
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
