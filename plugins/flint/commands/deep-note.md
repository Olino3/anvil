---
name: deep-note
description: Expand a section of a prior git-analysis or memory-analysis report into full notes
---

# deep-note

## Inputs

User invokes `/flint:deep-note <path-to-report> <section-heading>`. Both required.

## Steps

1. Invoke `vault-paths` to resolve `notes` folder.
2. Read the report file and locate the section by heading (H2 or H3 match, case-insensitive).
3. If the section is not found, list all available headings and stop.
4. Invoke `note-style` for voice/depth rules. Force `depth: detailed` for this command even if the user's default is `summary` — deep notes are always detailed.
5. Expand the section into one or more notes:
   - One note per subsection (H3) inside the target section
   - Each note gets canonical frontmatter with `source: flint/deep-note` and `related: ["[[<report-title>]]"]`
   - Filename: `<notes>/<YYYY-MM-DD>-deep-<slug>.md`
6. Invoke `hybrid-linking`: propose related links to existing notes in the vault. Present for review. Add only accepted proposals to `related` as quoted YAML list entries.
7. Print the list of created paths.
