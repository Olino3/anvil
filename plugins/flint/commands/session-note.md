---
name: session-note
description: Summarize the current Claude session and extract prompts into the prompt inbox
---

# session-note

## Steps

1. Invoke `vault-paths` to resolve `sessions` and `prompts` folders.
2. Invoke `note-style` for formatting rules.
3. Summarize the current session:
   - What was the user trying to do
   - What was done (high-level, not a blow-by-blow diff)
   - Decisions made and why
   - Open threads / next steps
4. Write the summary to `<sessions>/<YYYY-MM-DD-HHMM>-<slug>.md` using the canonical frontmatter.
5. Extract every user prompt from the current session. For each, append a line to `<prompts>/inbox.md` with:
   - ISO timestamp
   - project name
   - prompt text (first 200 chars)
   - link back to the session note (`[[<session-note-title>]]`)
6. If `<prompts>/inbox.md` does not exist, create it with canonical frontmatter (`source: flint/session-note`).
7. Print both written paths.

## Linking

Use hybrid-linking rules: this command only writes to `related` via the automatic back-link from prompt entries to the session note. It does not propose LLM links.
