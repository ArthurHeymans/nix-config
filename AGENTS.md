# Repository Guidelines

## Project Structure & Module Organization
Core NixOS system definitions live under `hosts/<hostname>/`, with reusable modules in `modules/`. User-facing home-manager profiles belong in `users/<username>/`, while package customizations live in `packages/`. Keep shared secrets and templates isolated in `secrets/`, and prefer referencing them through modules rather than importing directly inside host files.

## Build, Test, and Development Commands
Use `nix flake check` before opening a PR to validate flakes, modules, and formatting. Build a specific host with `nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel` to confirm the closure resolves. For configuration previews, run `nixos-rebuild dry-run --flake .#<hostname>` on the target machine. Apply home-manager updates locally with `home-manager switch --flake .#<username>` to verify user profiles. Quick routines live in the `justfile`: `just rebuild` mirrors `nixos-rebuild switch`, `just update` refreshes all flakes, and `just gc` trims store artefacts older than a day.

## Coding Style & Naming Conventions
Nix files use 2-space indentation, alphabetized package lists, and snake_case for variable names. Define module options with `lib.mkOption`, supplying defaults via `lib.mkDefault` when appropriate. Limit `with lib;` usage—prefer explicit imports to make dependencies obvious. Keep attribute names descriptive (`services.<service>.<option>`) and resist nesting when a module boundary is clearer.

## Testing Guidelines
Favor building and dry-running changes on a staging or non-critical host before touching production machines. When possible, add lightweight assertions or `assert` clauses inside modules to surface regressions early. Document expected outcomes in commit messages if a module lacks automated coverage.

## Commit & Pull Request Guidelines
Follow the existing short subject style: imperative verb, lowercase, ~50 characters (e.g., `update sway inputs`). Group related configuration edits per commit so reverts remain surgical. PRs should explain the motivation, affected hosts, test commands executed (include any `just` recipes), and follow-up actions for deployers. Link tracking issues where available, and attach screenshots only when UI changes are involved.

## Security & Secrets Handling
Never commit raw secrets; place encrypted material in `secrets/` and reference it via the appropriate module. Audit permissions whenever adding new users or services, and confirm secrets stay scoped to the minimal set of hosts that require them.
