{ inputs, ... }:
{
  systemd.tmpfiles.rules = [
    "d /srv/hermes 0750 arthur users - -"
    "d /srv/hermes/home 0750 arthur users - -"
    "d /srv/hermes/home/.hermes 0700 arthur users - -"
    "d /srv/hermes/home/.hermes/scripts 0700 arthur users - -"
    "d /srv/hermes/home/.hermes/state 0700 arthur users - -"
    "d /srv/hermes/home/repos 0750 arthur users - -"
    "d /srv/hermes/ssh 0700 root root - -"
  ];

  microvm.vms.hermes = {
    config =
      { lib, pkgs, ... }:
      let
        system = pkgs.stdenv.hostPlatform.system;
        llmPackages = inputs.llm-agents.packages.${system};
        gws = inputs.google-workspace-cli.packages.${system}.gws;
        googleWorkspacePython = pkgs.python3.withPackages (pythonPackages: [
          pythonPackages.google-api-python-client
          pythonPackages.google-auth-httplib2
          pythonPackages.google-auth-oauthlib
        ]);
        hermesEnv = "/home/arthur/.hermes/.env";
        swayConfig = pkgs.writeText "hermes-sway-headless.conf" ''
          xwayland enable
          output HEADLESS-1 resolution 1920x1080 position 0,0
          exec ${pkgs.chromium}/bin/chromium \
            --enable-features=UseOzonePlatform \
            --ozone-platform=wayland \
            --remote-debugging-address=127.0.0.1 \
            --remote-debugging-port=9222 \
            --disable-gpu \
            --user-data-dir=/home/arthur/.hermes/chromium \
            --no-first-run \
            --no-default-browser-check \
            about:blank
        '';
        nixConfigPrSkill = pkgs.writeText "hermes-nix-config-pr-skill.md" ''
          ---
          name: nix-config-pr
          description: Make reviewed changes to Arthur's nix-config repository and open a pull request. Use whenever Arthur asks to change NixOS, Home Manager, a host, a VM, or Hermes itself.
          ---

          # Contributing to nix-config

          The repository is `ArthurHeymans/nix-config` and its persistent checkout belongs at
          `/home/arthur/repos/nix-config`.

          When asked to change the Nix configuration:

          1. Check `gh auth status`. If authentication or repository write access is missing,
             stop and tell Arthur what is required.
          2. Clone the repository with `gh repo clone ArthurHeymans/nix-config` if the checkout
             does not exist. Otherwise update it without discarding local work.
          3. Create a topic branch named `hermes/<short-description>`. Never commit or push
             directly to the default branch.
          4. Read `AGENTS.md`, inspect the relevant configuration, and make the smallest change
             that satisfies the request. Never add secrets to the repository.
          5. Run `nix fmt` and the narrowest relevant Nix evaluation or build. Run
             `nix flake check` when practical. Record exactly which checks succeeded or failed.
          6. Commit, push the topic branch, and open a pull request with `gh pr create`.
          7. Reply in the originating conversation with the pull-request URL, a short summary,
             checks run, and any remaining risk or manual follow-up.

          Do not merge the pull request or deploy, switch, or reboot a NixOS host unless Arthur
          explicitly asks. A pull request is the normal completion point.
        '';
        githubCiWatch = pkgs.writeShellApplication {
          name = "github-ci-watch";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.findutils
            pkgs.gh
            pkgs.jq
          ];
          text = ''
            set -euo pipefail

            state_dir="$HOME/.hermes/state/github-ci-watch"
            mkdir -p "$state_dir"

            repos="''${HERMES_GITHUB_REPOS:-}"
            if [ -z "$repos" ]; then
              echo '{"wakeAgent": false}'
              exit 0
            fi

            changed='[]'
            while IFS= read -r repo; do
              repo="$(printf '%s' "$repo" | xargs)"
              [ -n "$repo" ] || continue

              latest="$(gh run list --repo "$repo" --status failure --limit 1 \
                --json databaseId,conclusion,status,url,headBranch,workflowName,displayTitle,createdAt \
                | jq '.[0] // empty')"
              [ -n "$latest" ] || continue

              id="$(printf '%s' "$latest" | jq -r .databaseId)"
              state_file="$state_dir/$(printf '%s' "$repo" | tr / _).last"
              old="$(cat "$state_file" 2>/dev/null || true)"
              if [ "$id" != "$old" ]; then
                printf '%s' "$id" > "$state_file"
                changed="$(jq --arg repo "$repo" --argjson run "$latest" '. + [{repo: $repo, run: $run}]' <<<"$changed")"
              fi
            done <<EOF
            $(printf '%s' "$repos" | tr ',' '\n')
            EOF

            if [ "$(jq length <<<"$changed")" -eq 0 ]; then
              echo '{"wakeAgent": false}'
            else
              jq -n --argjson failures "$changed" '{wakeAgent: true, context: {new_failures: $failures}}'
            fi
          '';
        };
      in
      {
        imports = [
          ../users/arthur/nixos.nix
        ];

        microvm = {
          hypervisor = "qemu";
          mem = 8192;
          vcpu = 4;
          writableStoreOverlay = "/nix/.rw-store";

          interfaces = [
            {
              type = "tap";
              id = "vm-hermes";
              mac = "02:00:00:00:00:12";
              tap.vhost = true;
            }
          ];

          shares = [
            {
              proto = "virtiofs";
              tag = "ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
            }
            {
              proto = "virtiofs";
              tag = "hermes-home";
              source = "/srv/hermes/home";
              mountPoint = "/home/arthur";
            }
            {
              proto = "virtiofs";
              tag = "hermes-ssh";
              source = "/srv/hermes/ssh";
              mountPoint = "/var/lib/ssh";
            }
            {
              proto = "virtiofs";
              tag = "syncthing-data";
              source = "/srv/syncthing";
              mountPoint = "/srv/syncthing";
            }
          ];
        };

        networking = {
          hostName = "hermes";
          useDHCP = false;
          useNetworkd = true;
          firewall = {
            enable = true;
            allowedTCPPorts = [
              22
              6080
            ];
          };
        };

        systemd.network = {
          enable = true;
          networks."20-lan" = {
            matchConfig.Type = "ether";
            networkConfig = {
              Address = "192.168.0.8/24";
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
          isNormalUser = true;
          extraGroups = [ "wheel" ];
        };
        security.sudo.wheelNeedsPassword = false;

        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          trusted-users = [ "arthur" ];
        };

        environment.systemPackages = [
          githubCiWatch
          googleWorkspacePython
          gws
          llmPackages.agent-browser
          llmPackages.hermes-agent
          llmPackages.pi
          pkgs.chromium
          pkgs.dbus
          pkgs.emacs-pgtk
          pkgs.gh
          pkgs.git
          pkgs.google-cloud-sdk
          pkgs.jq
          pkgs.jujutsu
          pkgs.nix
          pkgs.novnc
          pkgs.ripgrep
          pkgs.sway
          pkgs.wayvnc
          pkgs.python3Packages.websockify
        ];

        services = {
          dbus.enable = true;
          openssh = {
            enable = true;
            openFirewall = true;
            hostKeys = [
              {
                path = "/var/lib/ssh/ssh_host_ed25519_key";
                type = "ed25519";
              }
              {
                path = "/var/lib/ssh/ssh_host_rsa_key";
                type = "rsa";
                bits = 4096;
              }
            ];
            settings = {
              PasswordAuthentication = false;
              PermitRootLogin = "no";
            };
          };
          resolved.enable = true;
        };

        systemd.services.hermes-init = {
          wantedBy = [ "multi-user.target" ];
          before = [ "hermes-gateway.service" ];
          environment.HOME = "/home/arthur";
          serviceConfig = {
            Type = "oneshot";
            User = "arthur";
            Group = "users";
          };
          path = [
            pkgs.coreutils
            pkgs.git
          ];
          script = ''
            install -d -m 700 /home/arthur/.ssh /home/arthur/.hermes /home/arthur/.hermes/scripts /home/arthur/.hermes/skills/nix-config-pr /home/arthur/.hermes/state /home/arthur/repos
            ln -sfn ${nixConfigPrSkill} /home/arthur/.hermes/skills/nix-config-pr/SKILL.md
            git config --global --get user.name >/dev/null || git config --global user.name "Arthur Heymans"
            git config --global --get user.email >/dev/null || git config --global user.email "arthur@aheymans.xyz"
            if [ ! -e /home/arthur/.hermes/config.yaml ]; then
              cat > /home/arthur/.hermes/config.yaml <<'EOF'
            toolsets:
              - hermes-cli
              - terminal
              - file
              - web
              - browser
            terminal:
              cwd: /home/arthur/repos
            browser:
              cdp_url: http://127.0.0.1:9222
              allow_private_urls: true
            cron:
              wrap_response: true
            approvals:
              mode: manual
            EOF
              chmod 600 /home/arthur/.hermes/config.yaml
            fi
            if [ ! -e /home/arthur/.hermes/scripts/github-ci-watch.sh ]; then
              ln -s ${githubCiWatch}/bin/github-ci-watch /home/arthur/.hermes/scripts/github-ci-watch.sh
            fi
          '';
        };

        systemd.services.hermes-sway = {
          wantedBy = [ "multi-user.target" ];
          after = [ "hermes-init.service" ];
          wants = [ "hermes-init.service" ];
          path = [ pkgs.dbus ];
          environment = {
            WLR_BACKENDS = "headless";
            WLR_LIBINPUT_NO_DEVICES = "1";
            WLR_RENDERER = "pixman";
            XDG_RUNTIME_DIR = "/run/hermes-wayland";
          };
          serviceConfig = {
            User = "arthur";
            Group = "users";
            RuntimeDirectory = "hermes-wayland";
            RuntimeDirectoryMode = "0700";
            ExecStart = "${pkgs.dbus}/bin/dbus-run-session ${pkgs.sway}/bin/sway -c ${swayConfig}";
            Restart = "on-failure";
          };
        };

        systemd.services.hermes-wayvnc = {
          wantedBy = [ "multi-user.target" ];
          after = [ "hermes-sway.service" ];
          wants = [ "hermes-sway.service" ];
          environment = {
            WAYLAND_DISPLAY = "wayland-1";
            XDG_RUNTIME_DIR = "/run/hermes-wayland";
          };
          serviceConfig = {
            User = "arthur";
            Group = "users";
            ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in {1..50}; do test -S /run/hermes-wayland/wayland-1 && exit 0; sleep 0.2; done; exit 1'";
            ExecStart = "${pkgs.wayvnc}/bin/wayvnc 127.0.0.1 5900";
            Restart = "on-failure";
          };
        };

        systemd.services.hermes-novnc = {
          wantedBy = [ "multi-user.target" ];
          after = [ "hermes-wayvnc.service" ];
          wants = [ "hermes-wayvnc.service" ];
          serviceConfig = {
            ExecStart = "${pkgs.python3Packages.websockify}/bin/websockify --web ${pkgs.novnc}/share/webapps/novnc 0.0.0.0:6080 127.0.0.1:5900";
            Restart = "on-failure";
          };
        };

        systemd.services.hermes-gateway = {
          wantedBy = [ "multi-user.target" ];
          path = [
            googleWorkspacePython
            gws
            llmPackages.agent-browser
            llmPackages.hermes-agent
            llmPackages.pi
            pkgs.bash
            pkgs.chromium
            pkgs.coreutils
            pkgs.emacs-pgtk
            pkgs.findutils
            pkgs.gh
            pkgs.git
            pkgs.google-cloud-sdk
            pkgs.jq
            pkgs.jujutsu
            pkgs.nix
            pkgs.openssh
            pkgs.ripgrep
          ];
          after = [
            "network-online.target"
            "hermes-init.service"
            "hermes-sway.service"
          ];
          wants = [
            "network-online.target"
            "hermes-init.service"
            "hermes-sway.service"
          ];
          environment = {
            HERMES_HOME = "/home/arthur/.hermes";
            HOME = "/home/arthur";
            WAYLAND_DISPLAY = "wayland-1";
            XDG_RUNTIME_DIR = "/run/hermes-wayland";
            XDG_SESSION_TYPE = "wayland";
            BROWSER_CDP_URL = "http://127.0.0.1:9222";
            GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND = "file";
          };
          serviceConfig = {
            User = "arthur";
            Group = "users";
            WorkingDirectory = "/home/arthur/repos";
            EnvironmentFile = "-${hermesEnv}";
            ExecStart = "${llmPackages.hermes-agent}/bin/hermes gateway";
            Restart = "on-failure";
            RestartSec = 10;
          };
        };

        system.stateVersion = lib.mkDefault "25.05";
      };
  };
}
