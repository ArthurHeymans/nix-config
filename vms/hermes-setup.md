# Hermes diagnostics setup

Hermes keeps its graphical Chromium session for browser automation, but no
longer exposes VNC or a web desktop.

## SSH identity

`secrets/hermes-ssh-key.yaml` contains the dedicated SOPS-encrypted private key.
Only gmktec-g3 (the VM host), gmktec-k11 and t14s-g6 (for recovery/rotation)
are recipients.
The host decrypts it using `/etc/ssh/ssh_host_ed25519_key`, then copies it into a
single-credential directory in `/run`, shared read-only with Hermes. Neither
plaintext key material nor a decryption key enters the Nix store. The matching
public key is in `secrets/hermes-ssh-key.pub`.

Deploy the host configuration to gmktec-g3 and the diagnostic-account module to
the machines you want Hermes to inspect. The account is `hermes-diagnostics`,
with journal access but no wheel membership, sudo rules, or Nix trust. The SSH
key disables forwarding, PTYs and user SSH rc files, and only accepts connections
from Tailscale addresses. It still permits an ordinary unprivileged shell:
**this is not a strictly read-only account**. Journal access can expose secrets.

## Tailscale enrollment and policy

Before enrolling Hermes, edit your tailnet policy. Add `tag:hermes` and
`tag:managed` to `tagOwners`, owned by your administrator identity. Tag the
intended destination machines `tag:managed` (review any identity-based access
that tagging changes). Add this grant:

```json
{
  "src": ["tag:hermes"],
  "dst": ["tag:managed"],
  "ip": ["tcp:22"]
}
```

Grants and ACLs are additive. Remove/narrow any existing broad rules that also
allow `tag:hermes` to reach other machines or ports; this grant does not override
those rules. Review inbound access to Hermes too. Tailnet rules do not restrict
its existing LAN or internet access.

On gmktec-g3, after deploying and starting the VM:

```sh
ssh arthur@192.168.0.8 \
  'sudo tailscale up --advertise-tags=tag:hermes --accept-routes=false --ssh=false'
```

Complete the interactive login as the tailnet administrator. No reusable
Tailscale enrollment secret is stored in this repository. The node state is
persisted in `/srv/hermes/tailscale`, mounted at `/var/lib/tailscale` in the VM.
Enable MagicDNS so the host names listed in Hermes's diagnostic skill resolve.

## Host-key verification

SSH uses strict host-key checking and batch mode. Provision trusted host keys
in Hermes's persistent `/home/arthur/.ssh/known_hosts` before asking it to connect.
For each machine, obtain its public host key through an existing trusted SSH
connection or its local console:

```sh
sudo cat /etc/ssh/ssh_host_ed25519_key.pub
```

Add `HOSTNAME ssh-ed25519 PUBLIC_KEY` to Hermes's known_hosts, using the MagicDNS
name it will connect to. Do not trust an unverified `ssh-keyscan` result. Then
smoke-test from Hermes:

```sh
ssh hermes-diagnostics@HOSTNAME 'id; systemctl --failed; journalctl -b -n 30 --no-pager'
```

The diagnostic skill asks Hermes to report evidence and propose fixes, and to
request approval before mutations. Remote privilege limits are enforced by the
account; conversational approval is not a security boundary. Verify the chat
gateway only accepts your intended sender identities (its credentials and
allowlist are runtime configuration, not managed here).

## Revocation and rotation

To revoke diagnostic access, remove the public key from the diagnostic-account
module and deploy to the target hosts. Disable/remove the Hermes node in the
Tailscale admin console as well. To rotate, generate a new dedicated key, encrypt
its private half using the `secrets/hermes-ssh-key.yaml` SOPS creation rule, update
the public file, and redeploy targets and gmktec-g3. SOPS restarts the credential
copy service when the secret changes; the VM reads the new file on subsequent
SSH connections.
