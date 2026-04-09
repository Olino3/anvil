---
name: obsidian-setup
description: Initialize flint for an Obsidian vault — pick a preset layout, override paths, write config.json, scaffold folders, install prompt-capture hook
---

# obsidian-setup

Guide the user through setting up flint for their Obsidian vault.

## Step 1: Locate the vault

Ask the user for the absolute path to their Obsidian vault. Validate it exists and is a directory. If the user does not have one yet, tell them to create the directory first and re-run.

Save the path to `~/.config/flint/vault-path` (create the directory if needed).

## Step 2: Choose a preset

Show the three preset layouts with a one-line summary each:

1. **zettelkasten** — flat `Notes/`, `Maps/`, `Prompts/`
2. **projects-prompts** — `Projects/<name>/`, `Prompts/`, `Sessions/`, `Reports/`
3. **research** — `Topics/`, `Sources/`, `Maps/`, `Reports/`

Read the chosen preset from `plugins/flint/templates/presets/<preset>.json`.

## Step 3: Per-folder override

Ask: "Do you want to override any folder names?" For each path in the preset, offer the default and accept an override. This makes the layout fully user-defined while still starting from a preset.

## Step 4: Personalization (basic)

Ask four short questions (defer deeper personalization to `/flint:personalize`):
- Voice: terse | narrative | bulleted
- Depth: summary | detailed
- Link style: wikilink | markdown
- Tag prefix (may be empty)

## Step 5: Write config + scaffold

Load `plugins/flint/templates/config.default.json`, overlay the chosen preset paths, overlay the user overrides, and write to `<vault>/.flint/config.json`.

Create every folder referenced in `paths` under `<vault>/` if missing.

## Step 6: Install the hook

Copy `plugins/flint/hooks/user-prompt-submit.sh` to `<vault>/.flint/user-prompt-submit.sh` and `chmod +x` it. Print the user the exact `settings.json` snippet they need to add to enable the hook (the plugin does not silently edit user settings):

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "command": "<vault>/.flint/user-prompt-submit.sh" }
    ]
  }
}
```

## Step 7: Confirm

Print the final config and the list of created folders. Tell the user to run `/flint:personalize` for deeper customization.

## Errors

- Vault path does not exist: ask again, do not create.
- `<vault>/.flint/config.json` already exists: ask whether to overwrite, back up to `config.json.bak` first if confirmed.
