# Flint Plugin — Design Spec

**Date:** 2026-04-09
**Status:** Draft — approved via brainstorming
**Location:** `plugins/flint/` (sibling to `plugins/anvil/`)

## Purpose

Flint is a Claude Code plugin that helps manage, organize, and take notes in an Obsidian vault. It is an Obsidian knowledge builder: it analyzes a code project (git history, Claude project memory, prompts) and produces structured, linked markdown notes in a user-configured vault.

Flint writes plain markdown directly to the vault folder. It does not use any Obsidian API or URI scheme — the vault is treated as a directory of files.

## Architecture Overview

```
plugins/flint/
  plugin.json
  commands/          # 10 slash commands under /flint: namespace
  agents/            # subagents for heavy analytical work
  skills/            # shared skill files
  templates/         # preset vault layouts + note templates
  hooks/             # UserPromptSubmit hook for prompt capture
  test/fixtures/     # fixture vault + fixture repo for tests
```

### Vault side

Created by `/flint:obsidian-setup`:

```
<vault>/
  .flint/
    config.json      # personalization + vault layout mapping
    prompts.log      # append-only prompt capture from hook
  <user-defined folders per preset/override>
```

All flint state and config lives inside `<vault>/.flint/` so it travels with the vault. No project-side state. No cursors — all commands are full rescans with idempotent output.

## Commands

| Command | Dispatches to | Purpose |
|---|---|---|
| `/flint:obsidian-setup` | inline | Interactive setup: choose preset layout, override paths, write `config.json`, scaffold folders, install hook |
| `/flint:personalize` | inline | Q&A for note style/voice/depth. If config exists, asks what to adjust |
| `/flint:git-analysis` | `git-analyzer` agent | Deterministic git stats + LLM narrative report |
| `/flint:memory-analysis` | `memory-analyzer` agent | Analyze `~/.claude/projects/<proj>/memory/` + repo `CLAUDE.md` files; report gaps and suggested note areas |
| `/flint:gather-prompts` | `prompt-gatherer` agent | Read session JSONL history + `<vault>/.flint/prompts.log`; write prompt inbox |
| `/flint:organize-prompts` | `prompt-organizer` agent | Hybrid linking: frontmatter tags backbone + LLM-proposed `[[wikilinks]]` reviewed by user; flag frequently-used prompts |
| `/flint:content-mapping` | `content-mapper` agent | Targeted section → build/update a Map-of-Content with hybrid links |
| `/flint:quick-note` | inline | Create/append a note from user input using configured style |
| `/flint:session-note` | inline | Summarize current session, extract prompts into prompt notes |
| `/flint:deep-note` | inline (uses skill) | Given a section of a prior report, expand it into full notes |

### Agents (subagents)

- **git-analyzer** — receives deterministic JSON stats, writes narrative report
- **memory-analyzer** — reads memory + CLAUDE.md files, identifies gaps
- **prompt-gatherer** — reads + dedupes prompt sources, writes inbox
- **prompt-organizer** — proposes hybrid links, presents for review
- **content-mapper** — builds/updates MOC pages

### Shared skills

- **note-style** — reads personalization and enforces voice/depth/link style
- **hybrid-linking** — frontmatter tags as backbone; rules for when the LLM may propose new `[[wikilinks]]` (always reviewed before write)
- **vault-paths** — resolves preset + per-folder overrides from `config.json`

### Hook

`UserPromptSubmit` hook appends each prompt (with timestamp and cwd) to `<vault>/.flint/prompts.log` as JSONL. Installed by `/flint:obsidian-setup`. Best-effort: never blocks prompt submission, swallows errors.

## Vault Layout Presets

Flint ships preset layouts. During `/flint:obsidian-setup` the user picks one; `/flint:personalize` can override any path (fully user-defined).

Presets (initial set):
- **zettelkasten** — flat `Notes/`, `Maps/`, `Prompts/`
- **projects-prompts** — `Projects/<name>/`, `Prompts/`, `Sessions/`, `Reports/`
- **research** — `Topics/`, `Sources/`, `Maps/`, `Reports/`

## Data Contracts

### `<vault>/.flint/config.json`

```json
{
  "version": 1,
  "preset": "zettelkasten | projects-prompts | research",
  "paths": {
    "reports": "Reports",
    "prompts": "Prompts",
    "sessions": "Sessions",
    "maps": "Maps",
    "notes": "Notes",
    "projects": "Projects"
  },
  "personalization": {
    "voice": "terse | narrative | bulleted",
    "depth": "summary | detailed",
    "link_style": "wikilink | markdown",
    "tag_prefix": "",
    "frontmatter_fields": ["tags", "related", "source", "project"]
  }
}
```

`paths` defaults come from the chosen preset; any entry may be overridden.

### Note frontmatter contract

Every flint-written note includes:

```yaml
---
title: <string>
created: <iso8601>
project: <repo-name>
source: flint/<command>
tags: [<string>, ...]
related: [[<wikilink>], ...]
---
```

`related` is the backbone the `hybrid-linking` skill reads. LLM link proposals are added to `related` only after the user reviews them.

## Data Flows

### Git analysis

1. Command shells out deterministic git queries:
   - `git log --numstat` for most-edited files + velocity
   - Fix-commit regex (`fix|bug|hotfix`) + issue/PR reference extraction for bug hotspots
   - Top-level directories grouped as candidate areas (LLM can re-cluster)
2. Structured JSON passed to `git-analyzer` agent
3. Agent writes narrative report to `<vault>/<paths.reports>/git-analysis-<project>.md` (idempotent overwrite)

### Prompt capture

1. Hook appends JSONL line to `<vault>/.flint/prompts.log` on every `UserPromptSubmit`
2. `/flint:gather-prompts` reads the log + session JSONL history under `~/.claude/projects/<proj>/`, dedupes, writes `<paths.prompts>/inbox.md`
3. `/flint:organize-prompts` reads `inbox.md` + existing prompt notes, proposes tags/links for review, writes individual prompt notes with the frontmatter contract

### Memory analysis

1. Read `~/.claude/projects/<proj>/memory/MEMORY.md` + entry files
2. Read all `CLAUDE.md` files in the repo
3. `memory-analyzer` agent identifies gaps and suggests note areas
4. Report written to `<vault>/<paths.reports>/memory-analysis-<project>.md` (idempotent)

### Idempotency

Every command fully rescans its inputs and overwrites its outputs. No cursors. No state drift. A re-run always produces a correct current report.

## Error Handling

- Every command first resolves the vault path from `<vault>/.flint/config.json`. If not found → instruct user to run `/flint:obsidian-setup`. No silent fallbacks.
- Vault path must exist and be writable; fail fast with clear error otherwise.
- Hook writes are best-effort; a malformed `prompts.log` line is skipped by the gatherer with a warning in the report.
- `/flint:git-analysis` errors cleanly if cwd is not a git repo.
- LLM link proposals in `organize-prompts` and `content-mapping` are always presented for user confirmation before being written — never auto-applied.

## Testing

- **Fixture vault** at `plugins/flint/test/fixtures/vault/` with seeded `config.json`
- **Fixture repo** with small synthetic git history (fix commits, issue refs, multiple dirs)
- **Snapshot tests** for deterministic outputs: git stats JSON, prompt dedup, config scaffolding, hook log parsing
- **Manual smoke-test checklist** for LLM-narrative commands (git-analysis narrative, memory-analysis report, link proposals)
- No assertions on LLM narrative content itself — only that commands run, write to correct paths, and produce valid frontmatter

## Out of Scope (v1)

- Obsidian plugin API / URI scheme integration
- Incremental runs with cursors
- Auto-applying LLM-proposed links without review
- Cross-vault sync or multi-vault support
