{
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ../../modules/server.nix
    inputs.disko.nixosModules.disko
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  # CrabEFI has volatile EFI variables; always install the fallback EFI path.
  boot.loader.custom = {
    bootloader = "grub";
    grubDevice = "nodev";
    grubUseOSProber = false;
    grubEfiInstallAsRemovable = true;
  };
  boot.loader.grub.configurationLimit = 5;
  boot.loader.grub.extraConfig = ''
    serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
    terminal_input serial console
    terminal_output serial console
  '';
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200n8"
  ];

  # No desktop, display manager, containers, or VM host modules.
  services.fstrim.enable = true;
  services.fwupd.enable = lib.mkForce false;
  services.openssh.settings.KbdInteractiveAuthentication = false;
  security.sudo.wheelNeedsPassword = false;
  users.users.${username}.initialPassword = lib.mkForce null;
  # Match the other hosts: direct HTTP on LAN and Tailscale, without Serve.
  networking.firewall.allowedTCPPorts = [ 13773 ];

  environment.systemPackages = with pkgs; [
    ast-grep
    autoconf
    automake
    bash-language-server
    binutils
    bun
    clang-tools
    cmake
    codex
    deadnix
    diffutils
    fd
    file
    gcc
    gdb
    git-lfs
    gnumake
    go
    gopls
    ipmitool
    jujutsu
    lldb
    ltrace
    netcat-openbsd
    nil
    ninja
    nixd
    nixfmt
    nodejs_24
    nvme-cli
    openssl
    patch
    pkg-config
    pnpm
    python3
    python3Packages.python-lsp-server
    rust-analyzer
    rustup
    shellcheck
    shfmt
    socat
    sqlite
    statix
    strace
    tmux
    tree-sitter
    typescript-language-server
    unzip
    uv
    which
    yq-go
    zip
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
  ];

  home-manager.users.${username} = {
    imports = [ ../../home/llm.nix ];
    systemd.user.services.t3code.Service.WorkingDirectory = "/home/${username}";
    # This machine intentionally has no copy of the workstation's GPG key.
    programs.git.signing.signByDefault = lib.mkForce false;
    programs.jujutsu.settings.signing.behavior = lib.mkForce "keep";
    home.stateVersion = "26.11";
  };

  system.stateVersion = "26.11";
}
