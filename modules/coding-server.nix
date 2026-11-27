{
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./server.nix
    ./flashing.nix
  ];

  # Headless coding server settings shared across dedicated build/agent hosts.
  services.fstrim.enable = true;
  services.fwupd.enable = lib.mkForce false;
  services.openssh.settings.KbdInteractiveAuthentication = false;
  security.sudo.wheelNeedsPassword = false;
  users.users.${username}.initialPassword = lib.mkForce null;
  # Match the other hosts: direct HTTP on LAN and Tailscale, without Serve.
  networking.firewall.allowedTCPPorts = [ 13773 ];

  # T3 Code's managed Antigravity runtime uses the standard Linux loader.
  programs.nix-ld.enable = true;

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
    imports = [ ../home/llm.nix ];
    systemd.user.services.t3code.Service.WorkingDirectory = "/home/${username}";
    # Headless servers intentionally have no copy of the workstation's GPG key.
    programs.git.signing.signByDefault = lib.mkForce false;
    programs.jujutsu.settings.signing.behavior = lib.mkForce "keep";
  };
}
