# Pi configuration

`../pi.nix` installs the portable parts of Arthur's Pi configuration through
Home Manager. `../llm.nix` imports it and installs Pi and `jj-hunk` on PATH;
the old `~/.pi/agent/bin/jj-hunk` symlink to a Cargo installation is not needed.

Managed resources:

- `AGENTS.md`: global instructions.
- `extensions/`: DeepSeek, Kimi subscription OAuth, and GPT-6 Sol guidance.
- `extensions-disabled/`: archived extensions, kept disabled.
- `skills/`: personal skills, without the original checkout's `.git` directory.
- `agents/` and `pi-extensible-workflows/roles/`: custom agent definitions.
- `settings.json`, `models.json`, and `web-search.json`: public configuration.

The three JSON files stay writable. Each activation merges declared values over
existing values, preserving undeclared preferences, extension settings, and
runtime metadata. Changes made in Pi to declared values last until the next
activation; edit the files here to propagate those changes to other machines.
Slop Statistics is appended to the package list from the locked flake input.
Pi manages downloaded npm packages itself; their installation directories are
not copied from the original machine. Shells and user services explicitly set
`PI_CODING_AGENT_DIR` to `~/.pi/agent`, so web-search configuration does not fall
back to a legacy or XDG directory. `web-search.json` includes the preferences
from the old `~/.pi/web-search.json` as well as the agent-directory configuration.

Existing resources with different contents are protected by Home Manager's
normal collision checks. Back them up before the first switch, or use NixOS's
`home-manager.backupFileExtension` option. No forced replacement is configured.

## Private and runtime state

Do not add `auth.json`, `trust.json`, `models-store.json`, sessions, run history,
subagent runs/ownership, missions, workflow state, caches, or npm installations
to this directory. The collector configuration and SQLite outbox outside `.pi`
are also machine-specific and remain unmanaged.

Use Pi's login flow on each machine for OAuth credentials. The DeepSeek
extension reads `DEEPSEEK_API_KEY` from the runtime environment; no API key is
embedded here. SSH/GitHub access and other tool credentials are provisioned
separately. Initialize Slop Statistics with a separate upload token and machine
identity on the VM.
