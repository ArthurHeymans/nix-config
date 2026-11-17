# Hermes diagnostics setup

Deploy [`hermes.nix`](hermes.nix) on gmktec-g3 and the
[diagnostic account](../modules/hermes-diagnostics.nix) on the target hosts.
The SSH restrictions still allow an ordinary unprivileged shell: this is not
strictly read-only access. The journal may contain secrets.

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

Complete the interactive login as the tailnet administrator. Enable MagicDNS
so the host names listed in Hermes's diagnostic skill resolve.

## Host-key verification

Provision trusted host keys in Hermes's `/home/arthur/.ssh/known_hosts`
before asking it to connect.
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

Conversational approval is not a security boundary. Verify that the chat
gateway only accepts your intended sender identities; its credentials and
allowlist are runtime configuration.

## Revocation and rotation

To revoke diagnostic access, remove the public key from the diagnostic-account
module and deploy to the target hosts. Disable/remove the Hermes node in the
Tailscale admin console as well. To rotate, generate a new dedicated key, encrypt
its private half using the `secrets/hermes-ssh-key.yaml` SOPS creation rule, update
the public file, and redeploy targets and gmktec-g3. SOPS restarts the credential
copy service when the secret changes; the VM reads the new file on subsequent
SSH connections.
