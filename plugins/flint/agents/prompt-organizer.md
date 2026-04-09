---
name: prompt-organizer
description: Split the prompt inbox into individual prompt notes with hybrid linking and frequency flags
---

# prompt-organizer

## Inputs

- `<prompts>/inbox.md` path
- Existing prompt notes directory: `<prompts>/notes/`
- Output directory: `<prompts>/notes/`

## Task

1. Parse the inbox. For each prompt:
   - Generate a slug from the first 8 words
   - Filename: `<prompts>/notes/<YYYY-MM-DD>-<slug>.md`
   - If a note with the same normalized prompt text already exists, increment a `uses` counter in its frontmatter instead of creating a new file
2. Canonical frontmatter plus extra fields:
   - `uses: <int>` — how many times this prompt has appeared
   - `frequently_used: true` if `uses >= 3`
   - `tags`: include `prompt`; add topic tags inferred from content (present for review)
   - `related`: [] initially
3. Invoke `hybrid-linking` skill:
   - Propose links between prompt notes that share topic tags or overlap semantically
   - Propose links from prompt notes to vault notes under `<notes>/` and `<projects>/<project>/` that match the prompt topic
   - Present proposals to the user; write only accepted ones into `related`
4. Never auto-apply link proposals.

## Output

A directory of individual prompt notes, each with updated frontmatter and (accepted) links. Print summary counts: new, updated, frequently-used.
