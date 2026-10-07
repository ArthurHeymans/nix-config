---
name: jj-core
description: "Manage version control with Jujutsu (jj): committing, amending, absorbing, squashing, splitting, rebasing, abandoning, undoing, resolving conflicts, and pushing. Load before ANY jj mutation, history surgery, or commit-message work, and whenever a jj command aborts unexpectedly."
token_cost: 260
related: [jj-hunk, conventional-commits, sem]
keywords: ["jujutsu", "jj", "rebase", "squash", "split", "push", "commit", "amend", "absorb", "undo", "abandon", "history", "editor", "conflict"]
requires_tools: [bash]
---

# Jujutsu

Git-compatible VCS with a different data model — no staging area, changes are immediate. Every file is tracked in the working copy as "changes" (like commits without parents).

> ⚠️ **Never use `git` for mutations in a jj repo** — it corrupts history. Allowed: `git log`, `git diff`, `git show`, `git blame`, `git grep`.

## Forbidden / interactive-trap commands for agents

These forms open an editor or prompt, which hangs or aborts in non-interactive
agent shells. Always use the listed safe form:

| Forbidden (interactive) | Safe form |
|---|---|
| `jj describe -m "..."` (multiline) | `jj describe --stdin < msgfile` |
| `jj commit` (no message arg) | `jj describe --stdin` + `jj new` |
| `jj split -r REV <files>` (no message) | `jj split -r REV <files> "message"` — pass a message or it opens the editor |
| `jj squash --from A --into B` (both described) | `jj squash --from A --into B -u` or with `-m "msg"` — without `-u`/`-m` it prompts for a combined description whenever source and destination both have one |
| `jj squash -r REV` where REV and parent are both described | same: add `-u` or `-m` |
| `jj commit -m "..."` (multiline) | write message to a file, use `describe --stdin` + `jj new` |
| `git commit` / `git rebase` / any git mutation | use the jj equivalent |

Rule of thumb: **every jj command that can set a description must get it
explicitly** (`--stdin`, `-m`, `-u`, or a positional message). If a command
aborts with no error output, assume it tried to open an editor.

## Surgery notes (read before rewriting history)

- `jj edit REV` auto-amends on snapshot and auto-rebases descendants.
  Commit hashes churn after every mutation: re-derive revs fresh each step
  and verify via explicit revs, never cached hashes.
- Prefer `jj absorb` for folding working-copy hunks into ancestors (it
  places hunks by blame); use `squash --from/--into` only for whole commits.
- After any bad op: `jj undo` immediately, then confirm with `jj op log`.
- Behavior-preserving rewrites (adjacent squashes): record the tip tree
  (`git rev-parse <tip>^{tree}` on git-backed repos) before and after —
  it must be identical.

.local dir can be used for all changes that shouldn't be tracked like plans, workflows, subagent status etc
