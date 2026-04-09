---
name: personalize
description: Configure note voice, depth, link style, tag prefix, and per-folder overrides. On re-run, asks which fields to adjust.
---

# personalize

## If config does not exist

Tell the user to run `/flint:obsidian-setup` first. Stop.

## If config exists

Read `<vault>/.flint/config.json`. Print the current `personalization` values and `paths` values.

Ask: "Which would you like to adjust?" Offer a numbered list:

1. Voice (`terse` / `narrative` / `bulleted`)
2. Depth (`summary` / `detailed`)
3. Link style (`wikilink` / `markdown`)
4. Tag prefix
5. Frontmatter fields (comma-separated list)
6. Folder paths (walk through each key in `paths`)
7. None — exit

For each selected item, ask one question at a time, validate the answer, and update the in-memory config.

## Write back

After the user is done, write the updated config back to `<vault>/.flint/config.json` atomically (write to `.tmp`, then rename). Back up the previous version to `config.json.bak`.

Print a diff of what changed.
