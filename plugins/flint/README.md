# Flint

A Claude Code plugin that manages, organizes, and takes notes in an Obsidian vault.

Flint writes plain markdown directly to a user-configured vault folder. No Obsidian API — just files.

## Quick Start

````
/flint:obsidian-setup
/flint:personalize
/flint:git-analysis
````

## Commands

| Command | Purpose |
|---|---|
| `/flint:obsidian-setup` | Initialize vault config, layout, and hook |
| `/flint:personalize` | Configure note voice/depth/link style |
| `/flint:git-analysis` | Git history report (most-edited, velocity, bug hotspots) |
| `/flint:memory-analysis` | Analyze Claude project memory + CLAUDE.md for note gaps |
| `/flint:gather-prompts` | Extract recent prompts into an inbox note |
| `/flint:organize-prompts` | Link/tag prompt notes with hybrid rules |
| `/flint:content-mapping` | Build Maps of Content for a section |
| `/flint:quick-note` | Drop a quick note into the vault |
| `/flint:session-note` | Summarize current session into a note |
| `/flint:deep-note` | Expand a report section into full notes |

See `docs/superpowers/specs/2026-04-09-flint-plugin-design.md` for design.
