---
name: quick-note
description: Drop a quick note into the vault. Accepts an optional title; infers folder from preset.
---

# quick-note

## Inputs

User invokes `/flint:quick-note <optional text>`. If no text is given, prompt for the note body.

## Steps

1. Invoke the `vault-paths` skill to resolve the vault root and the `notes` folder.
2. Invoke the `note-style` skill for voice/depth/link/tag rules.
3. Generate a title from the first non-empty line of the body (max 60 chars, title-cased).
4. Build the filename: `<notes>/<YYYY-MM-DD>-<slug>.md`. If it already exists, append `-2`, `-3`, etc.
5. Render frontmatter from `templates/note.frontmatter.md` with:
   - `title` = generated title
   - `created` = current ISO8601 timestamp
   - `project` = basename of current git repo (or `unknown`)
   - `source` = `flint/quick-note`
   - `tags` = [] (user can add later)
   - `related` = []
6. Write the file. Print the path.

No linking. No LLM proposals. Minimum ceremony.
