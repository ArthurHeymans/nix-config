# Coding VM

See [`coding.nix`](coding.nix) for the VM and service settings.

## First use

In the guest, run `sudo tailscale up` and approve the login URL. For T3 browser
access over MagicDNS, create a one-time pairing link with
`t3 auth pairing create --ttl 10m --base-url http://coding:13773`.
Use `http://192.168.0.9:13773` as the base URL for LAN access. Neither needs
Tailscale Serve. Treat pairing links as passwords.

For T3 Connect, run `t3 connect link --headless` in the guest, approve in a
browser, then `sudo systemctl restart t3code`. Check with `t3 connect status`.

For API keys, create `/home/arthur/.config/coding/api-keys.env` with mode `0600`.
After changing it, restart `t3code` and reopen Pi sessions to load the new keys.
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

The worker installer creates one `proxy` provider in Pi for Claude, OpenAI,
Muse, and Antigravity. Re-run it to refresh the list. Add `--migrate-t3-favorites` to move
matching Pi favorites in T3 to `proxy` without changing favorites the hub
can't serve. In threads saved with `fleet-claude` or `fleet-codex`, reselect
the model under `proxy`. The installer does not copy `auth.json`. To enroll
an offline worker after it returns, run from the checkout:

```sh
worker=m900
scp scripts/t3-router-worker.py "$worker:~/t3-router-worker.py"
ssh coding "sudo jq -er --arg worker '$worker' '.[\$worker]' /etc/t3-router/worker-keys.json" |
  ssh "$worker" 'python3 ~/t3-router-worker.py https://coding.tail19d694.ts.net --migrate-t3-favorites && rm ~/t3-router-worker.py'
```

## Live deployment handoff

The live router was deployed using unit symlinks under
`/etc/systemd/system.control`. Once the guest generation includes the router
units, remove only those three temporary symlinks and their corresponding
`multi-user.target.wants` symlinks from that directory. Run
`systemctl daemon-reload` and check that the units resolve to the Nix versions.

The initial VM deployment also used
`/etc/systemd/system.control/microvms.target.d/50-coding.conf` on the host for
autostart, before the host configuration declared the VM.
