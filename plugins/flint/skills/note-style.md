---
name: note-style
description: Enforce the user's configured note voice, depth, and link style when writing notes into the vault. Use whenever a flint command writes markdown to the vault.
---

# note-style

## Inputs

Read `personalization` from `<vault>/.flint/config.json` (via the `vault-paths` skill).

Fields:
- `voice`: `terse` | `narrative` | `bulleted`
- `depth`: `summary` | `detailed`
- `link_style`: `wikilink` | `markdown`
- `tag_prefix`: string prepended to every tag (may be empty)
- `frontmatter_fields`: list of fields required in every written note

## Rules

**Voice**
- `terse`: short sentences, minimal connective tissue, no filler
- `narrative`: flowing prose, transitions, context framing
- `bulleted`: bullet lists as the primary structure, prose only when a bullet cannot carry the meaning

**Depth**
- `summary`: one paragraph or a few bullets per section
- `detailed`: multiple paragraphs, examples, cross-references

**Link style**
- `wikilink`: `[[Note Title]]`
- `markdown`: `[Note Title](Note%20Title.md)`

**Tags**
- Prepend `tag_prefix` to every tag written in frontmatter
- Tags are lowercase, hyphenated

**Frontmatter**
- Every written note includes at minimum the fields in `frontmatter_fields`
- Use the template at `plugins/flint/templates/note.frontmatter.md`
- Always set `source: flint/<command-name>`

## Writing rule

Before writing any note, read this skill + the live config. If the config is missing, defer to `vault-paths`' error.
