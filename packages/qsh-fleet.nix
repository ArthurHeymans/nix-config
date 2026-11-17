{
  pkgs,
  username,
  authorizedKeys,
}:
let
  qsh = pkgs.callPackage ./qsh.nix { };
  keys = pkgs.writeText "qsh-fleet-authorized-keys" (pkgs.lib.concatLines authorizedKeys);
  config = pkgs.writeText "qsh-fleet.toml" ''
    tcp = true
    host_key = ".local/state/qsh-fleet/host_ed25519"
    # Use only the declarative keys, not the user's other SSH or qsh keys.
    use_ssh_authorized_keys = true
    authorized_keys_file = [".local/state/qsh-fleet/authorized_keys"]
    use_qsh_authorized_keys = false
    allow_users = [${builtins.toJSON username}]
    password_authentication = false
    totp = "off"
    permit_user_rc = false
    allow_agent_forwarding = false
    allow_tcp_forwarding = false
    allow_stream_local_forwarding = false
    x11_forwarding = false
  '';
  start = pkgs.writeShellApplication {
    name = "qshd-fleet";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      umask 077
      state="$HOME/.local/state/qsh-fleet"
      mkdir -p -- "$state"
      # qshd's StrictModes checks the whole key path. Install a regular
      # private file rather than pointing it into the shared Nix store.
      tmp=$(mktemp "$state/authorized_keys.XXXXXXXX")
      trap 'rm -f -- "$tmp"' EXIT
      install -m 600 ${keys} "$tmp"
      mv -Tf -- "$tmp" "$state/authorized_keys"
      trap - EXIT

      address=$(/run/current-system/sw/bin/tailscale ip -4)
      if [[ ! $address =~ ^100\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo 'No Tailscale IPv4 address; refusing to start qshd.' >&2
        exit 1
      fi
      cd "$HOME"
      exec ${qsh}/bin/qshd -c ${config} serve --listen "$address:4422"
    '';
  };
  unitText = ''
    [Unit]
    Description=qshd on the Tailscale address (user mode)
    ConditionUser=${username}
    StartLimitIntervalSec=0

    [Service]
    ExecStart=${start}/bin/qshd-fleet
    Restart=on-failure
    RestartSec=15s
    UMask=0077

    [Install]
    WantedBy=default.target
  '';
  unit = pkgs.writeText "qshd.service" unitText;
in
pkgs.runCommand "qsh-fleet-${qsh.version}" { passthru = { inherit qsh unitText; }; } ''
  mkdir -p "$out/bin" "$out/share/systemd/user"
  ln -s ${qsh}/bin/qsh ${qsh}/bin/qshd "$out/bin/"
  ln -s ${unit} "$out/share/systemd/user/qshd.service"
''
