# Global Agent Instructions

## Model Routing
- When explicitly selecting an OpenAI model, use the `openai-codex/` provider prefix instead of `openai/` whenever that model is available (for example, prefer `openai-codex/gpt-5.3-codex-spark` over an `openai/...` route).
- Do not use openrouter for subagents unless explicitly requested

## Version Control
- Before running any `git` command, check whether the current directory is in a Jujutsu (`jj`) repository (for example with `jj root` or by detecting a `.jj` directory).
- If it is a `jj` repository, prefer `jj` commands for status, diffs, history, commits, rebases, and other repository mutations.
- Only use `git` in a `jj` repository when explicitly required for read-only interoperability or remote operations that have no suitable `jj` equivalent, and avoid `git` mutations unless the user explicitly asks.
- When in a jj repo it's important to start a new commit before doing new work to avoid overriding an existing commit

## Commit message
- Look at the prevailing style in there repo
- Respect line length max that is imposed in a repo (i.e. 72 in coreboot)

## Missing tools
- This is a nixos system. Use nix-shell if you need a tool that is not available.

## github CI
- find the latest major version of actions before using

## rust
- In new projects use edition 2024 and resolver 3 in workspace projects
- There are a lot of crates out there that could be useful. Search for those before tackling a problem with your own solutions.
- Use zerocopy when serializing or deserializing data formats

## rust embedded
- Use tock-registers for accessing MMIO register and their bitfields, avoid plain read/write_volatile. If a project has it's own nice way of dealing with this, use that.

## Coding preferences in general
- Keep things simple "yagni"
- Don't be scared to propose bold ideas if they can meaningfully impact our work. Short term solutions is not always what I want.
- tests are good! Endless "regression tests" for feature deletion, etc much less good. Tests should be focussed, not slop
- Prefer functional style programming as much as possible. In rust this means using reducing mutable state, use iterators methods like map, collect, fold, etc.
- Comments need to be update to date when code is changed

## questions are read-only
- A question is a request for an answer, not for changes. Things like "how hard would it be", "should we", ... are just me trying to grasp things without expecting changes.
- Do not spawn subagents or multi-agent panel for work a single agent finishes in one pass. Delegation is for breadth or adverserial, not for ordinary tasks.
- When agents work in parallel state file ownership to avoid conflicts.

## Pull requests
- Make sure titles follow conventions from the repo.
- Rebase on main/master which you fetch before making the PR.
- PR descriptions should aim for simplicity. Start with a minimal clear description of the problem. Follow up with how it's solved. Unless asked avoid "how it's tested" section.
- NEVER comment on a PR, unless user explicitly requests it.

## Screenshots
- Screenshots are in ~/Pictures/Screenshots/

## Emacs code
- My doom emacs configuration is in ~/src/doomconfig
- When updating emacs code that we develop on the main/master branch and pushing that directly to github I want this updated in my doomconfig
