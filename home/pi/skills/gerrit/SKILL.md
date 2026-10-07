---
name: gerrit
description: Query and update Gerrit changes through its SSH CLI. Use for Gerrit reviews, rebases, submissions, and dependent stacks.
---

# Gerrit SSH

Query before a mutation and again afterward. For this setup, use `ssh review.coreboot.org` (the SSH alias includes the user and port).

```bash
ssh review.coreboot.org gerrit query --format=JSON --current-patch-set --dependencies 'change:12345'
ssh review.coreboot.org gerrit review --rebase CHANGE,PATCHSET
ssh review.coreboot.org gerrit review --code-review +2 CHANGE,PATCHSET
ssh review.coreboot.org gerrit review --submit CHANGE,PATCHSET
```

The last JSON query line is a `type: stats` record, not a change. For dependent changes, rebase root to tip, including non-topic changes in the chain; re-query after each rebase to get the new patch-set number and dependencies. A conflicting rebase creates no new patch set.

Check server-specific options with `ssh review.coreboot.org gerrit review --help`. SSH joins local arguments into a remote command: for messages containing spaces, quote the entire remote command and quote the value inside it.

Do not reply to reviewer comments unless the user explicitly asks.
