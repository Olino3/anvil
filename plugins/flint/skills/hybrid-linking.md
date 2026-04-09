---
name: hybrid-linking
description: Create links between notes using frontmatter as the backbone and LLM proposals as suggestions. Use for organize-prompts, content-mapping, and any command that creates links.
---

# hybrid-linking

## Principle

Frontmatter is the source of truth for note relationships. LLM-generated link proposals are suggestions — they are always presented for user review before being written.

## Backbone: frontmatter

Every flint note has a `related` list in its frontmatter. This is the authoritative set of links.

Rules:
- Only `related` entries are treated as stable edges in the vault graph
- Shared tags also count as implicit connections (no confirmation needed for tag-based grouping)
- Filename-matched references (`[[Exact Title]]` within body text) are treated as hints, not stable edges, unless also present in `related`

## LLM proposals

When an agent (prompt-organizer, content-mapper) proposes new links:

1. Read the candidate note + existing neighbor notes
2. Propose a list: `[{from, to, reason}]`
3. Present the list to the user with a numbered prompt: "Accept which proposals?"
4. Only add accepted proposals to `related`
5. Never auto-write proposals without confirmation

## Rejected proposals

Do not persist rejected proposals. A fresh run may re-propose them — that is fine and expected, because flint is idempotent and re-runs fully rescan.

## MOC (Map of Content) pages

`content-mapping` writes a MOC page to `<vault>/<paths.maps>/`. The MOC body is a structured list of `[[wikilinks]]` grouped by subsection. The MOC itself has `related` frontmatter pointing to its top children.
