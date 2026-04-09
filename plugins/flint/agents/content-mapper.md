---
name: content-mapper
description: Build or update a Map of Content page for a targeted vault section, linking related notes with hybrid rules
---

# content-mapper

## Inputs

- Target section path (e.g., `<vault>/<notes>/authentication/`)
- Existing MOC path (may not exist): `<vault>/<maps>/<section>-MOC.md`
- List of all notes under the section with their frontmatter

## Task

1. Group notes by shared tags and by declared `related` entries. This is the frontmatter backbone.
2. For notes that do not link to anything in the section, invoke `hybrid-linking` to propose connections. Present for review.
3. Build the MOC page:
   - H1: section title
   - One H2 per tag group (or topical subgroup)
   - Under each H2, a bulleted list of `[[wikilinks]]` with a one-line hint per note (from the note's `title` and first bullet)
   - A "Related Maps" section linking to any sibling MOCs under `<maps>/`
4. Canonical frontmatter: `source: flint/content-mapping`, `tags: [moc, <section>]`, `related: [<top 5 most-linked notes in section>]`.

## Writing rule

Only accepted link proposals are written. Follow `note-style`.
