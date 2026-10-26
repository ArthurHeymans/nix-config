{ inputs, hosts, ... }:
{
  microvm.vms.coding.config =
    { lib, pkgs, ... }:
    let
      pi = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi.override {
        useBun = false;
      };
      t3code = import ../packages/t3code.nix { inherit pkgs inputs lib; };
      tools = with pkgs; [
        bash
        cargo
        cloudflared
        cmake
        coreutils
        curl
        file
        findutils
        gcc
        gh
        git
        gnumake
        jq
        jujutsu
        nix
        nodejs
        openssh
        pkg-config
        python3
        ripgrep
        rustc
        tmux
        unzip
      ];
    in
    {
      _module.args.hosts = hosts;
      imports = [ ../users/arthur/nixos.nix ];

      microvm = {
        hypervisor = "qemu";
        mem = 16384;
        vcpu = 4;
        writableStoreOverlay = "/nix/.rw-store";
        # Persist the whole guest, including repos, credentials, build trees,
        # the writable store, and its database, on one sparse 100 GiB disk.
        volumes = [
          {
            image = "/var/lib/microvms/coding/root.img";
            mountPoint = "/";
            size = 102400;
          }
        ];
        shares = [
          {
            proto = "virtiofs";
            tag = "ro-store";
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
            readOnly = true;
          }
        ];
        interfaces = [
          {
            type = "tap";
            id = "vm-coding";
            mac = "02:00:00:00:00:13";
            tap.vhost = true;
          }
        ];
      };

      # Override the default MicroVM tmpfs mount options for the ext4 root.
      fileSystems."/" = {
        options = lib.mkForce [
          "defaults"
          "x-initrd.mount"
        ];
        neededForBoot = true;
      };
      boot.tmp.useTmpfs = false;

      networking = {
        hostName = "coding";
        useDHCP = false;
        useNetworkd = true;
        firewall.enable = true;
      };
      systemd.network = {
        enable = true;
        networks."20-lan" = {
          matchConfig.Type = "ether";
          networkConfig = {
            Address = "192.168.0.9/24";
            Gateway = "192.168.0.1";
            DNS = [
              "192.168.0.1"
              "1.1.1.1"
            ];
            DHCP = "no";
          };
        };
      };

      users.users.arthur = {
        uid = 1000;
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      };
      security.sudo.wheelNeedsPassword = false;
      services.openssh = {
        enable = true;
        openFirewall = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
        };
      };
      services.resolved.enable = true;
      programs.nix-ld.enable = true;
      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [ "arthur" ];
      };
      environment.systemPackages = tools ++ [
        pi
        t3code
      ];
      environment.extraInit = ''
        if [ -r "$HOME/.config/coding/api-keys.env" ]; then
          set -a
          . "$HOME/.config/coding/api-keys.env"
          set +a
        fi
      '';

      systemd.services.coding-init = {
        wantedBy = [ "multi-user.target" ];
        before = [ "t3code.service" ];
        path = [
          pkgs.coreutils
          pkgs.git
        ];
        environment.HOME = "/home/arthur";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "arthur";
          Group = "users";
        };
        script = ''
          install -d -m 700 "$HOME/repos" "$HOME/.t3" "$HOME/.t3/userdata"
          if [ ! -e "$HOME/.t3/userdata/settings.json" ]; then
            printf '%s\n' '{"providerInstances":{"pi":{"driver":"pi","enabled":true,"config":{}}}}' \
              > "$HOME/.t3/userdata/settings.json"
            chmod 600 "$HOME/.t3/userdata/settings.json"
          fi
          git config --global --get user.name >/dev/null || git config --global user.name "Arthur Heymans"
          git config --global --get user.email >/dev/null || git config --global user.email "arthur@aheymans.xyz"
        '';
      };
      systemd.services.t3code = {
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "coding-init.service"
        ];
        wants = [ "network-online.target" ];
        requires = [ "coding-init.service" ];
        path = tools ++ [ pi ];
        environment.HOME = "/home/arthur";
        serviceConfig = {
          User = "arthur";
          Group = "users";
          WorkingDirectory = "/home/arthur/repos";
          EnvironmentFile = "-/home/arthur/.config/coding/api-keys.env";
          ExecStart = "${lib.getExe' t3code "t3"} start --no-browser --host 127.0.0.1 --port 13773";
          Restart = "on-failure";
          RestartSec = 5;
          UMask = "0077";
        };
      };
      system.stateVersion = "25.05";
    };
}
