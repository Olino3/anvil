---
name: memory-analysis
description: Analyze project memory + CLAUDE.md files and report note gaps
---

# memory-analysis

## Steps

1. Invoke `vault-paths` to resolve `reports` and `notes` folders.
2. Resolve `~/.claude/projects/<project>/memory/` — use the current repo's Claude project directory (look up by repo path).
3. If the memory directory does not exist, tell the user and stop — there is nothing to analyze.
4. Find every `CLAUDE.md` in the repo (`git ls-files '**/CLAUDE.md' 'CLAUDE.md'`).
5. List existing vault notes under `<notes>/` and `<projects>/<project>/`.
6. Dispatch to `memory-analyzer` with the three input lists and output path `<reports>/memory-analysis-<project>.md`.
7. Print the report path.

Idempotent: re-running overwrites.
