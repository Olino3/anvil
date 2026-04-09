---
name: vault-paths
description: Resolve the Obsidian vault path and folder mappings from <vault>/.flint/config.json. Use whenever a flint command or agent needs to read or write notes.
---

# vault-paths

## Purpose

Every flint command writes into a user-configured Obsidian vault. This skill is the single source of truth for resolving:

1. The vault root path
2. The current `config.json`
3. The folder for each content type (`reports`, `prompts`, `sessions`, `maps`, `notes`, `projects`)

## Resolving the vault root

1. Look for `FLINT_VAULT` environment variable. If set and the directory exists, use it.
2. Otherwise, read `~/.config/flint/vault-path` if present.
3. Otherwise, error with: `Flint is not configured. Run /flint:obsidian-setup to initialize a vault.`

Never guess. Never fall back to cwd. Never create a vault directory without user confirmation.

## Reading config

Read `<vault>/.flint/config.json`. If missing, error with the same message as above.

Validate:
- `version == 1` (otherwise: "Unsupported flint config version. Update the plugin or migrate config.")
- `paths` object exists
- Each referenced path exists under `<vault>/`; create on demand only with explicit user confirmation

## Resolving a content path

Given a content type (e.g., `reports`), return `<vault>/<config.paths.reports>`. If the key is missing, fall back to the preset default for the configured preset. If the preset itself lacks the key, error — never silently invent a folder.

## Writing rule

Every write goes through a resolved path from this skill. No hard-coded vault paths anywhere else.
