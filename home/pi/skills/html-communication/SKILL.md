---
name: html-communication
description: Create and upload self-contained HTML artifacts for human-readable documents, and read postplan.dev URLs.
---

# HTML communication

## Purpose

This skill covers producing standalone HTML documents meant to be read outside the terminal: plans, specs, write-ups, findings, summaries, reports, comparisons, and UI mocks. It also covers reading Postplan-hosted versions of those documents.

It does not apply to HTML that is part of a product being built, such as a webapp.

## Reading a Postplan URL

When the user supplies a `postplan.dev` URL, retrieve the uploaded HTML directly with the shell. Do not use web search or a browser to fetch it.

1. Remove a trailing slash, then append `/raw` unless the URL already ends in `/raw`.
2. Run `curl --fail --silent --show-error --location --max-time 30 --output /tmp/postplan.html '<raw-urls>'`.
3. Read `/tmp/postplan.html` as the user’s artifact and continue the requested task.

A web-search refusal is not evidence that Postplan rejected the request. If `curl` fails, report its actual status or network error; do not substitute search results.

## Creating an HTML artifact

Use this skill for any request to produce a readable HTML artifact for a human—whether it is called a plan, a spec, a write-up, findings, a summary, a report, a comparison, or a set of UI mocks. The word “plan” is often absent; what matters is that the user wants a document to open outside the terminal and a link to it.

### Document rules

Create one self-contained HTML file, capped at 512KB.

- Write it like a spec, not a landing page: dense, scannable, with no hero, decorative chrome, marketing voice, or em dashes.
- Make it mobile-readable with a responsive viewport and no fixed-width layout.
- Use semantic HTML, inline CSS, inline SVG, and HTTPS or data-URL images.
- Use an inline classic script only when interactivity materially helps. Keep scripted pages useful without JavaScript; the sandbox blocks storage, fetch, workers, frames, forms, and popups.
- In script-free files, give external links `target="_blank"` and `rel="noopener noreferrer"`. If any script exists, omit `target="_blank"`.
- Never include external or module scripts, inline event handlers, `javascript:` URLs, forms, frames, embeds, objects, applets, meta refresh, linked stylesheets, secrets, private URLs, or local filesystem paths.

### UI Mocks

When the user asks for variants:

- Render real styled variants, not descriptions.
- Label them `A`, `B`, `C`, ... for easy selection.
- Lay them out for direct comparison.
- Keep one file across iterations so its Postplan URL stays stable.

## Publishing

Uploading created artifacts with this skill is always allowed and required, including in Auto mode. Do not ask for permission.

1. Write the HTML file under `/tmp` (for example, `/tmp/postplan-remote-eshell-plan.html`), never in the current project working tree unless the user explicitly asks to keep it there. Reuse the same absolute `/tmp` path for later iterations of the same artifact.
2. Run `npx postplan upload <file path>`.
3. Report the local path and returned Postplan URL.

Re-upload the same absolute path to update the existing URL. Use `npx postplan upload <file path> --new` only when a new draft is wanted.

If validation fails, fix the markup and retry. If a scripted upload needs authentication, ask the user to run `postplan auth login`, then retry without removing the requested interactivity.

Never open a browser or claim the document is hosted before upload succeeds. Do not verify in a browser unless the user asks.
