{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  flake_dir = "/home/${username}/src/nix-config";
  hosts = [
    "x220-nixos"
    "t14s-g6"
    "gmktec-k11"
    "t480-arthur"
    "x201-arthur"
  ];
  notify_email = "arthur@aheymans.xyz";

  build_cmds = lib.concatMapStringsSep "\n" (host: ''
    echo "Building ${host}..."
    nix build "${flake_dir}#nixosConfigurations.${host}.config.system.build.toplevel" \
      --no-link --print-out-paths 2>&1 | tee -a "$log"
    if [ "''${PIPESTATUS[0]}" -ne 0 ]; then
      failed_hosts="$failed_hosts ${host}"
    fi
  '') hosts;
in
{
  systemd.services.nix-flake-update = {
    description = "Nightly nix flake update, build, and push";
    serviceConfig = {
      Type = "oneshot";
      User = username;
      Group = "users";
      WorkingDirectory = flake_dir;
      Environment = [
        "HOME=/home/${username}"
        "PATH=${
          lib.makeBinPath (
            with pkgs;
            [
              nix
              git
              openssh
              coreutils
              gawk
              msmtp
              gnugrep
            ]
          )
        }:/run/wrappers/bin"
      ];
    };
    script = ''
      set -euo pipefail
      log=$(mktemp /tmp/nix-flake-update-XXXXXX.log)
      failed_hosts=""

      send_failure_email() {
        local subject="$1"
        {
          echo "From: nix-auto-update <${notify_email}>"
          echo "To: ${notify_email}"
          echo "Subject: [nix-config] $subject"
          echo "Content-Type: text/plain; charset=utf-8"
          echo ""
          echo "$subject"
          echo ""
          echo "--- log output ---"
          tail -200 "$log"
        } | msmtp -a aheymans ${notify_email}
      }

      trap 'rm -f "$log"' EXIT

      echo "=== Flake update started at $(date) ===" | tee "$log"

      # Pull latest changes first
      git pull --rebase 2>&1 | tee -a "$log" || {
        send_failure_email "git pull failed on $(hostname)"
        exit 1
      }

      # Update flake inputs
      nix flake update 2>&1 | tee -a "$log" || {
        send_failure_email "nix flake update failed on $(hostname)"
        exit 1
      }

      # Check if flake.lock actually changed
      if git diff --quiet flake.lock; then
        echo "No flake input changes, nothing to do." | tee -a "$log"
        exit 0
      fi

      # Build all host configurations
      ${build_cmds}

      if [ -n "$failed_hosts" ]; then
        send_failure_email "Build failed for:$failed_hosts on $(hostname)"
        # Restore flake.lock to avoid committing a broken update
        git checkout flake.lock
        exit 1
      fi

      echo "All builds succeeded, committing and pushing." | tee -a "$log"

      git add flake.lock
      git commit -m "flake: update inputs" 2>&1 | tee -a "$log"
      git push 2>&1 | tee -a "$log" || {
        send_failure_email "git push failed on $(hostname)"
        exit 1
      }

      echo "=== Flake update completed at $(date) ===" | tee -a "$log"
    '';
  };

  systemd.timers.nix-flake-update = {
    description = "Nightly nix flake update timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "03:00";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
  };
}
