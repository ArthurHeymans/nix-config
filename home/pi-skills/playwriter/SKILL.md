---
name: playwriter
description: Inspect and debug the user's existing Brave tabs using Playwriter. Use for browser console errors, failed network requests, DOM inspection, screenshots, and browser automation in the user's logged-in session.
---

# Playwriter

Use the `playwriter` CLI provided by the Nix configuration. It pins Playwriter
0.9.0 and disables anonymous usage telemetry. npm caches dependencies on first use.

Before browser interaction, run `playwriter skill` and read its complete output.
That is the installed version's authoritative API and workflow reference.

- Use the existing Brave browser through the Playwriter extension, not a fresh
  browser/profile. Do not enable cloud browsers, remote sharing, or public tunnels
  unless explicitly requested.
- Create your own session with `playwriter session new --tab-group <task>` and
  pass its ID with `-s <id>` on subsequent calls.
- Only use tabs enabled by the user. Select an existing tab by its exact URL;
  do not assume the first tab belongs to this task.
- Start debugging with read-only observations. Do not clear site data, log the
  user out, change browser settings, or submit messages without authorization.
- Never dump cookies, authorization headers, tokens, or unrelated private content.
- Close tabs you create when finished, but never close the user's existing tabs.
- If no browser is connected, ask the user to install the extension or click its
  icon on the target tab: https://chromewebstore.google.com/detail/playwriter/jfeammnjpkecdekppnclgkkffahnhfhe
