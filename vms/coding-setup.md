# Coding VM

`coding` is a separate MicroVM on `gmktec-g3`, configured in `coding.nix`:

- 16 GiB RAM, four shared vCPUs
- 100 GiB persistent ext4 root disk at `/var/lib/microvms/coding/root.img`
- LAN address `192.168.0.9`, SSH user `arthur`
- Tailscale for private remote access; its identity persists in `/var/lib/tailscale`
- T3 Code and Node-based Pi, plus common build tools

The disk is sparse: it grows as data is written, rather than reserving 100 GiB
on the host. Repositories, credentials, temporary build files, and the writable
Nix store/database all live on this disk. Only the host's read-only Nix store is
shared; Hermes's home and credentials are not mounted.

For initial Tailscale enrollment, run `sudo tailscale up` inside the guest and
approve the displayed login URL. Once enrolled, use its Tailscale name `coding`
(subject to your tailnet's MagicDNS and access policies).

T3 Code runs as the guest's `t3code.service`, listening on `0.0.0.0:13773`, like
`t480-arthur` and `gmktec-k11`. The firewall permits that port. Open
`http://coding:13773` over Tailscale, or `http://192.168.0.9:13773` on the LAN.
Neither Tailscale Serve nor HTTPS is needed. For browser login, mint a one-time
pairing link in the guest with
`t3 auth pairing create --ttl 10m --base-url http://coding:13773`.
Treat that link as a password.

The server is also reachable through T3 Connect. To authorize it, SSH into the
guest and run
`t3 connect link --headless`, approve in a browser, then
`sudo systemctl restart t3code`.

Pi is enabled in T3's initial settings. API keys are provisioned separately in
`/home/arthur/.config/coding/api-keys.env` (mode 0600). T3 and new login shells
load this file; key values never enter the Nix store or repository. Restart
`t3code` after changing it, and reopen existing Pi sessions to inherit new keys.
For providers using direct OAuth instead of the fleet router, run `pi`, then
`/login`, in the guest.

## Fleet model router

The services are defined in [`packages/t3-router.nix`](../packages/t3-router.nix).
On a fresh guest, run [`scripts/t3-router-bootstrap.py`](../scripts/t3-router-bootstrap.py)
as root on `coding`, then start `t3-router`, `t3-router-ingress`, and
`t3-router-usage`. Publish inference and the dashboard to the tailnet with
Tailscale Serve, not Funnel. Leave the management API on loopback. Run on
`coding`:

```sh
sudo tailscale serve --bg --https=443 http://127.0.0.1:8318
sudo tailscale serve --bg --https=8443 http://127.0.0.1:8319
```

Inference is at `https://coding.tail19d694.ts.net` and the usage dashboard is
at `https://coding.tail19d694.ts.net:8443/`. Retrieve Keeper's `LOGIN_PASSWORD`
from `/etc/t3-router/usage.env` in a private SSH terminal on `coding`. Keeper
shows request history by worker key, not subscription quotas. In T3, select
`coding` under **Usage → Limits** for the **Fleet router** quota source.

Sign in to Codex once on `coding`. If ChatGPT requires it, enable device code
authentication in your ChatGPT security settings first:

```sh
ssh -t coding 'sudo -u t3-router -H "$(sudo readlink -f /etc/t3-router/cli-proxy-api)" -config /var/lib/t3-router/config.json -codex-device-login -no-browser'
```

After a Nix rebuild, `command -v cli-proxy-api` can be used instead of the
live-deployment symlink.

### Claude subscription through the hub

Select a `proxy/claude-*` model under T3's **Pi** provider. The hub uses its own
Claude OAuth login and has no Claude Console API-key fallback. To renew the
hub login, run:

```sh
ssh -t coding 'sudo -u t3-router -H "$(sudo readlink -f /etc/t3-router/cli-proxy-api)" -config /var/lib/t3-router/config.json -claude-login -no-browser'
```

Open the URL it prints. If the browser is on a different machine and cannot
reach the final `localhost` page, paste the full callback URL into that
private terminal when the CLI prompts. The hub owns and refreshes its OAuth
credentials; don't copy credentials from Pi or Claude Code to it.

### Muse subscription through the hub

Run the hub's Meta device login once on `coding`:

```sh
ssh -t coding 'sudo -u t3-router -H "$(sudo readlink -f /etc/t3-router/cli-proxy-api)" -config /var/lib/t3-router/config.json --meta-login --no-browser'
```

### Antigravity through the hub

Run the login from the machine where you'll open the browser. The SSH tunnel
forwards Google's loopback redirect to the CLI:

```sh
ssh -t -L 127.0.0.1:51121:127.0.0.1:51121 coding \
  'sudo -u t3-router -H "$(sudo readlink -f /etc/t3-router/cli-proxy-api)" -config /var/lib/t3-router/config.json --antigravity-login --no-browser'
```

On `coding`, run `sudo python3 t3-router-bootstrap.py --sync-antigravity-aliases`
against the running hub to keep only Gemini 4 Neon in Antigravity, then
restart `t3-router` to apply the change. Refresh the worker catalog and select
`proxy/ag-gemini-4-neon` in Pi or T3. Neon supports `low`, `medium`, `high`,
and `xhigh`; choose the level in the effort picker. No Pi extension is needed
for the proxy route. For direct OAuth on an individual worker, `pi-antigravity`
adds a separate `/login antigravity` flow.

## Live deployment handoff

The live router was deployed using unit symlinks under
`/etc/systemd/system.control`. Once the guest generation includes the router
units, remove only those three temporary symlinks and their corresponding
`multi-user.target.wants` symlinks from that directory. Run
`systemctl daemon-reload` and check that the units resolve to the Nix versions.

The initial deployment uses the host's existing MicroVM service templates and
`/etc/systemd/system.control/microvms.target.d/50-coding.conf` for autostart,
without switching the host configuration or restarting other guests. The Nix
module declares the same VM and autostart for subsequent host rebuilds.

On the host, manage the VM with `sudo systemctl restart microvm@coding` and
`sudo journalctl -u microvm@coding`. Inside the guest, inspect T3 with
`sudo systemctl status t3code` or `t3 connect status`.
