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
  host_name = config.networking.hostName;

  build_cmds = lib.concatMapStringsSep "\n" (host: ''
    echo "Building ${host}..."
    set +e
    nh os build -H ${host} --no-nom "${flake_dir}" 2>&1 | tee -a "$log"
    build_status="''${PIPESTATUS[0]}"
    set -e
    if [ "$build_status" -ne 0 ]; then
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
              coreutils
              gawk
              git
              gnugrep
              gnupg
              jq
              jujutsu
              msmtp
              nh
              nix
              openssh
            ]
          )
        }:/run/wrappers/bin"
      ];
    };
    script = ''
            set -euo pipefail
            log=$(mktemp /tmp/nix-flake-update-XXXXXX.log)
            lock_before=$(mktemp /tmp/nix-flake-lock-before-XXXXXX.json)
            failed_hosts=""
            old_change=""
            update_change=""
            main_before=""
            main_moved="false"

            cleanup() {
              if [ -n "$old_change" ]; then
                jj edit "$old_change" >/dev/null 2>&1 || true
              fi
              rm -f "$log" "$lock_before"
            }

            send_email() {
              local subject="$1"
              local body="$2"
              local include_log="''${3:-false}"
              {
                echo "From: nix-auto-update <${notify_email}>"
                echo "To: ${notify_email}"
                echo "Subject: [nix-config] $subject"
                echo "Content-Type: text/plain; charset=utf-8"
                echo ""
                echo "$body"
                if [ "$include_log" = "true" ]; then
                  echo ""
                  echo "--- log output (last 200 lines) ---"
                  tail -200 "$log"
                fi
              } | msmtp -a aheymans ${notify_email}
            }

            updated_inputs() {
              local before="$1"
              local after="$2"

              jq -r -n --slurpfile before "$before" --slurpfile after "$after" '
                def nodes($file):
                  $file[0].nodes
                  | to_entries
                  | map({key: .key, locked: .value.locked})
                  | map(select(.locked != null));
                def locked_label($locked):
                  if $locked.rev? then ($locked.rev | tostring)[0:12]
                  elif $locked.lastModified? then ($locked.lastModified | tostring)
                  elif $locked.narHash? then ($locked.narHash | tostring)[0:20]
                  else "changed"
                  end;
                (nodes($before) | INDEX(.key)) as $old |
                (nodes($after) | INDEX(.key)) as $new |
                (
                  (($old | keys_unsorted[]) as $key |
                    select($new[$key] == null) |
                    "- \($key): removed"),
                  (($new | keys_unsorted[]) as $key |
                    select($old[$key] == null or $old[$key].locked != $new[$key].locked) |
                    if $old[$key] == null then
                      "- \($key): added " + locked_label($new[$key].locked)
                    else
                      "- \($key): " + locked_label($old[$key].locked) + " -> " + locked_label($new[$key].locked)
                    end)
                )
              ' | sort
            }

            abandon_update() {
              if [ "$main_moved" = "true" ] && [ -n "$main_before" ]; then
                jj bookmark set main -r "$main_before" --allow-backwards >/dev/null 2>&1 || true
                main_moved="false"
              fi
              if [ -n "$update_change" ]; then
                jj abandon "$update_change" >/dev/null 2>&1 || true
                update_change=""
              fi
            }

            fail() {
              local subject="$1"
              local body="$2"
              abandon_update
              send_email "$subject" "$body" true
              exit 1
            }

            trap cleanup EXIT

            echo "=== Flake update started at $(date) ===" | tee "$log"

            old_change=$(jj log --no-graph -r @ -T 'change_id')
            main_before=$(jj log --no-graph -r main -T 'change_id')

            # Fetch latest changes first, then do the automated update in its own jj change.
            jj git fetch 2>&1 | tee -a "$log" || \
              fail "jj git fetch failed on ${host_name}" "jj git fetch failed before attempting the nightly flake update."

            jj new main@origin -m "flake: update inputs" 2>&1 | tee -a "$log" || \
              fail "jj new failed on ${host_name}" "Could not create the temporary flake update change."
            update_change=$(jj log --no-graph -r @ -T 'change_id')
            cp flake.lock "$lock_before"

            # Update flake inputs
            nix flake update 2>&1 | tee -a "$log" || \
              fail "nix flake update failed on ${host_name}" "nix flake update failed on the temporary jj change."

            # Check if flake.lock actually changed
            if [ -z "$(jj diff --summary -- flake.lock)" ]; then
              echo "No flake input changes, nothing to do." | tee -a "$log"
              abandon_update
              send_email "no flake input changes on ${host_name}" "No flake input changes were available during the nightly update."
              exit 0
            fi

            input_summary=$(updated_inputs "$lock_before" flake.lock || echo "- flake.lock changed; failed to summarize inputs")
            if [ -z "$input_summary" ]; then
              input_summary="- flake.lock changed; no locked input changes detected"
            fi

            # Build all host configurations
            ${build_cmds}

            if [ -n "$failed_hosts" ]; then
              fail "build failed for:$failed_hosts on ${host_name}" "Build failed for:$failed_hosts.

      Updated inputs attempted:
      $input_summary"
            fi

            echo "All builds succeeded, committing and pushing." | tee -a "$log"

            printf 'flake: update inputs\n\nUpdated inputs:\n%s\n' "$input_summary" | \
              jj desc --stdin 2>&1 | tee -a "$log" || \
              fail "jj desc failed on ${host_name}" "Could not set the flake update commit message."
            jj bookmark set main -r "$update_change" 2>&1 | tee -a "$log" || \
              fail "jj bookmark set failed on ${host_name}" "Could not move the main bookmark to the flake update change."
            main_moved="true"
            jj git push --bookmark main 2>&1 | tee -a "$log" || \
              fail "jj git push failed on ${host_name}" "jj git push failed after all builds succeeded.

      Updated inputs:
      $input_summary"

            echo "=== Flake update completed at $(date) ===" | tee -a "$log"
            send_email "flake inputs updated on ${host_name}" "Nightly flake input update succeeded.

      Updated inputs:
      $input_summary

      Built hosts: ${lib.concatStringsSep " " hosts}"
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
