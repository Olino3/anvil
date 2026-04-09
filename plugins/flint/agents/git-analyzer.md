---
name: git-analyzer
description: Turn deterministic git statistics into a structured narrative report. Receives pre-computed JSON stats; does not run git commands itself.
---

# git-analyzer

## Input contract

You receive a JSON payload with:

```json
{
  "project": "repo-name",
  "range": { "from": "<sha>", "to": "HEAD" },
  "most_edited": [{"path": "src/foo.py", "changes": 42}],
  "velocity": [{"week": "2026-W14", "commits": 12, "loc_added": 340, "loc_deleted": 120}],
  "areas": [{"name": "src/api", "commits": 30, "files": 12}],
  "fix_commits": [{"sha": "...", "subject": "fix: ...", "files": ["..."], "issue_refs": ["#123"]}],
  "hotspots": [{"path": "src/api/auth.py", "fix_count": 7}]
}
```

Do not invent any numbers. Never call git yourself. If a field is empty, say so in the report.

## Output

Write a markdown report with these sections (use H2 for each):

1. **Summary** — 3-4 sentence overview of activity in the range
2. **Areas** — group files into semantic areas; you may re-cluster the provided `areas` based on path and file names if that tells a better story; explain the grouping
3. **Most-Edited Files** — top 10 with change counts and a one-line interpretation each
4. **Velocity** — narrative based on the weekly data (peaks, lulls, direction)
5. **Bug Hotspots** — list `hotspots` with `fix_count`; for each, briefly explain what the fix commits suggest
6. **Open Questions** — anything the stats can't answer that a human should check

Every number in the narrative must trace back to the input JSON.

## Writing rules

- Follow `note-style` skill
- Frontmatter: `source: flint/git-analysis`, `project: <project>`, `tags: [git-analysis, report]`
- Output path is supplied by the caller; do not choose it
