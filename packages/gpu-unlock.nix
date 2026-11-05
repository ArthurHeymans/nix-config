{
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  fetchurl,
  python3,
  zstd,
  kernel,
  kernelModuleMakeFlags,
}:
let
  version = "2.0.0";
  nvVersion = "610.43.03";
  src = fetchFromGitHub {
    owner = "Zagitta";
    repo = "gpu-unlock";
    rev = "7eb51bccae0a0b7e599e084d971170e9a1e82d0c";
    hash = "sha256-1KD/J1S1uyI5GGoTwQ1cU/sXeEKlG54exSvi6U+j73M=";
  };
  nvSource = fetchurl {
    url = "https://download.nvidia.com/XFree86/NVIDIA-kernel-module-source/NVIDIA-kernel-module-source-${nvVersion}.tar.xz";
    hash = "sha256-fhGJI8eiPtw2EU1jJzpG4+BOmvmGlaQiA+esLf6fwdw=";
  };
  nvInstaller = fetchurl {
    url = "https://download.nvidia.com/XFree86/Linux-x86_64/${nvVersion}/NVIDIA-Linux-x86_64-${nvVersion}-no-compat32.run";
    hash = "sha256-4IRFHbcwpt8p09dPZVdJxNI248lF99lLUgXoQxj+L5A=";
  };
  firmware = stdenvNoCC.mkDerivation {
    pname = "gpu-unlock-firmware";
    inherit version src;
    nativeBuildInputs = [
      python3
      zstd
    ];
    # Firmware includes ELF images; never rewrite or strip signed NVIDIA blobs.
    dontFixup = true;
    buildPhase = ''
      runHook preBuild
      mkdir nv-source assets
      tar -xf ${nvSource} -C nv-source
      python3 firmware/extract_gsp.py ${nvInstaller} assets
      python3 firmware/extract_boot_assets.py nv-source/NVIDIA-kernel-module-source-${nvVersion} assets
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      install -Dm644 -t $out/lib/firmware/gpu-unlock/${nvVersion} assets/*.bin
      install -Dm644 -t $out/share/licenses/gpu-unlock-firmware assets/NVIDIA-LICENSE firmware/NOTICE.md
      runHook postInstall
    '';
    meta.license = lib.licenses.unfreeRedistributableFirmware;
  };
in
stdenv.mkDerivation {
  pname = "gpu-unlock";
  inherit version src;
  sourceRoot = "${src.name}/kernel/gpu_unlock";
  nativeBuildInputs = kernel.moduleBuildDependencies;
  dontStrip = true;
  dontPatchELF = true;
  makeFlags = kernelModuleMakeFlags ++ [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];
  installPhase = ''
    runHook preInstall
    local flagsArray=()
    concatTo flagsArray makeFlags makeFlagsArray
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      M="$PWD" modules_install "''${flagsArray[@]}" \
      INSTALL_MOD_PATH="$out" INSTALL_MOD_DIR=extra
    runHook postInstall
  '';
  passthru = { inherit firmware; };
  meta = {
    description = "Unlock full-rate NVIDIA GeForce tensor cores before driver initialization";
    homepage = "https://github.com/Zagitta/gpu-unlock";
    license = lib.licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
  };
}
