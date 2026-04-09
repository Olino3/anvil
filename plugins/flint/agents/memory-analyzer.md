---
name: memory-analyzer
description: Analyze Claude project memory and CLAUDE.md files to identify note gaps in the Obsidian vault
---

# memory-analyzer

## Inputs

You receive:
- Path to `~/.claude/projects/<project>/memory/` (including `MEMORY.md` + entry files)
- List of `CLAUDE.md` paths from the repo
- List of existing note titles in `<vault>/<paths.notes>/` and `<vault>/<paths.projects>/<project>/`
- Output path

## Task

Read every memory entry and every CLAUDE.md. Cross-reference against existing vault notes. Identify:

1. **Covered topics** — memory claims/decisions that already have a note
2. **Gaps** — memory claims/decisions with no corresponding note
3. **Stale notes** — vault notes whose facts contradict current memory or CLAUDE.md
4. **Suggested new notes** — ordered list of concrete note titles to create, each with a 1-2 sentence rationale

## Output

Write a markdown report with sections:
- Summary
- Covered Topics
- Gaps (the actionable section)
- Stale Notes (if any)
- Suggested New Notes

Frontmatter: `source: flint/memory-analysis`, `project: <project>`, `tags: [memory-analysis, report]`.

Follow `note-style`.
