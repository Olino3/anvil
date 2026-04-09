# Flint Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `flint` Claude Code plugin — 10 slash commands, 5 subagents, 3 skills, and a prompt-capture hook — that writes structured markdown into a user-configured Obsidian vault.

**Architecture:** Markdown-only plugin (like sibling `plugins/anvil/`). Commands dispatch to subagents for heavy analysis; shared skills enforce vault layout, note style, and hybrid linking. A single real script — the `UserPromptSubmit` hook — appends prompts to `<vault>/.flint/prompts.log`. All flint state lives in `<vault>/.flint/`.

**Tech Stack:** Claude Code plugin format (`plugin.json`, `commands/*.md`, `agents/*.md`, `skills/*.md`), Bash for the hook script, `bats-core` for hook tests, Obsidian vault = plain markdown.

**Spec:** `docs/superpowers/specs/2026-04-09-flint-plugin-design.md`

---

## File Structure

```
plugins/flint/
  .claude-plugin/plugin.json
  README.md
  commands/
    obsidian-setup.md
    personalize.md
    git-analysis.md
    memory-analysis.md
    gather-prompts.md
    organize-prompts.md
    content-mapping.md
    quick-note.md
    session-note.md
    deep-note.md
  agents/
    git-analyzer.md
    memory-analyzer.md
    prompt-gatherer.md
    prompt-organizer.md
    content-mapper.md
  skills/
    vault-paths.md
    note-style.md
    hybrid-linking.md
  hooks/
    user-prompt-submit.sh
    hooks.json
  templates/
    config.default.json
    presets/
      zettelkasten.json
      projects-prompts.json
      research.json
    note.frontmatter.md
  test/
    fixtures/
      vault/.flint/config.json
      repo/                 # synthetic git history fixture
    hook.bats
    smoke-checklist.md
```

Each command file is a thin shim that invokes the matching skill or agent. Agents hold the analytical logic. Skills are shared reference material the agents/commands read.

---

## Task 1: Plugin scaffolding

**Files:**
- Create: `plugins/flint/.claude-plugin/plugin.json`
- Create: `plugins/flint/README.md`

- [ ] **Step 1: Create `plugin.json`**

```json
{
  "name": "flint",
  "version": "0.1.0",
  "description": "Obsidian knowledge builder — git/memory/prompt analysis and structured note-taking into a configured vault"
}
```

- [ ] **Step 2: Create `README.md`**

```markdown
# Flint

A Claude Code plugin that manages, organizes, and takes notes in an Obsidian vault.

Flint writes plain markdown directly to a user-configured vault folder. No Obsidian API — just files.

## Quick Start

```
/flint:obsidian-setup
/flint:personalize
/flint:git-analysis
```

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
```

- [ ] **Step 3: Commit**

```bash
git add plugins/flint/.claude-plugin/plugin.json plugins/flint/README.md
git commit -m "feat(flint): scaffold plugin"
```

---

## Task 2: Presets and default config template

**Files:**
- Create: `plugins/flint/templates/config.default.json`
- Create: `plugins/flint/templates/presets/zettelkasten.json`
- Create: `plugins/flint/templates/presets/projects-prompts.json`
- Create: `plugins/flint/templates/presets/research.json`
- Create: `plugins/flint/templates/note.frontmatter.md`

- [ ] **Step 1: Create `config.default.json`**

```json
{
  "version": 1,
  "preset": "projects-prompts",
  "paths": {
    "reports": "Reports",
    "prompts": "Prompts",
    "sessions": "Sessions",
    "maps": "Maps",
    "notes": "Notes",
    "projects": "Projects"
  },
  "personalization": {
    "voice": "bulleted",
    "depth": "summary",
    "link_style": "wikilink",
    "tag_prefix": "",
    "frontmatter_fields": ["tags", "related", "source", "project"]
  }
}
```

- [ ] **Step 2: Create `presets/zettelkasten.json`**

```json
{
  "preset": "zettelkasten",
  "paths": {
    "notes": "Notes",
    "maps": "Maps",
    "prompts": "Prompts",
    "sessions": "Sessions",
    "reports": "Reports",
    "projects": "Projects"
  }
}
```

- [ ] **Step 3: Create `presets/projects-prompts.json`**

```json
{
  "preset": "projects-prompts",
  "paths": {
    "projects": "Projects",
    "prompts": "Prompts",
    "sessions": "Sessions",
    "reports": "Reports",
    "maps": "Maps",
    "notes": "Notes"
  }
}
```

- [ ] **Step 4: Create `presets/research.json`**

```json
{
  "preset": "research",
  "paths": {
    "notes": "Topics",
    "sources": "Sources",
    "maps": "Maps",
    "reports": "Reports",
    "prompts": "Prompts",
    "sessions": "Sessions",
    "projects": "Projects"
  }
}
```

- [ ] **Step 5: Create `note.frontmatter.md`** (canonical frontmatter template used by every write)

```markdown
---
title: {{title}}
created: {{iso8601}}
project: {{project}}
source: flint/{{command}}
tags: [{{tags}}]
related: [{{related}}]
---
```

- [ ] **Step 6: Commit**

```bash
git add plugins/flint/templates
git commit -m "feat(flint): add preset layouts and default config template"
```

---

## Task 3: `vault-paths` skill

**Files:**
- Create: `plugins/flint/skills/vault-paths.md`

- [ ] **Step 1: Create the skill file**

````markdown
---
name: vault-paths
description: Resolve the Obsidian vault path and folder mappings from <vault>/.flint/config.json. Use whenever a flint command or agent needs to read or write notes.
---

# vault-paths

## Purpose

Every flint command writes into a user-configured Obsidian vault. This skill is the single source of truth for resolving:

1. The vault root path
2. The current `config.json`
3. The folder for each content type (`reports`, `prompts`, `sessions`, `maps`, `notes`, `projects`)

## Resolving the vault root

1. Look for `FLINT_VAULT` environment variable. If set and the directory exists, use it.
2. Otherwise, read `~/.config/flint/vault-path` if present.
3. Otherwise, error with: `Flint is not configured. Run /flint:obsidian-setup to initialize a vault.`

Never guess. Never fall back to cwd. Never create a vault directory without user confirmation.

## Reading config

Read `<vault>/.flint/config.json`. If missing, error with the same message as above.

Validate:
- `version == 1` (otherwise: "Unsupported flint config version. Update the plugin or migrate config.")
- `paths` object exists
- Each referenced path exists under `<vault>/`; create on demand only with explicit user confirmation

## Resolving a content path

Given a content type (e.g., `reports`), return `<vault>/<config.paths.reports>`. If the key is missing, fall back to the preset default for the configured preset. If the preset itself lacks the key, error — never silently invent a folder.

## Writing rule

Every write goes through a resolved path from this skill. No hard-coded vault paths anywhere else.
````

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/skills/vault-paths.md
git commit -m "feat(flint): add vault-paths skill"
```

---

## Task 4: `note-style` skill

**Files:**
- Create: `plugins/flint/skills/note-style.md`

- [ ] **Step 1: Create the skill file**

````markdown
---
name: note-style
description: Enforce the user's configured note voice, depth, and link style when writing notes into the vault. Use whenever a flint command writes markdown to the vault.
---

# note-style

## Inputs

Read `personalization` from `<vault>/.flint/config.json` (via the `vault-paths` skill).

Fields:
- `voice`: `terse` | `narrative` | `bulleted`
- `depth`: `summary` | `detailed`
- `link_style`: `wikilink` | `markdown`
- `tag_prefix`: string prepended to every tag (may be empty)
- `frontmatter_fields`: list of fields required in every written note

## Rules

**Voice**
- `terse`: short sentences, minimal connective tissue, no filler
- `narrative`: flowing prose, transitions, context framing
- `bulleted`: bullet lists as the primary structure, prose only when a bullet cannot carry the meaning

**Depth**
- `summary`: one paragraph or a few bullets per section
- `detailed`: multiple paragraphs, examples, cross-references

**Link style**
- `wikilink`: `[[Note Title]]`
- `markdown`: `[Note Title](Note%20Title.md)`

**Tags**
- Prepend `tag_prefix` to every tag written in frontmatter
- Tags are lowercase, hyphenated

**Frontmatter**
- Every written note includes at minimum the fields in `frontmatter_fields`
- Use the template at `plugins/flint/templates/note.frontmatter.md`
- Always set `source: flint/<command-name>`

## Writing rule

Before writing any note, read this skill + the live config. If the config is missing, defer to `vault-paths`' error.
````

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/skills/note-style.md
git commit -m "feat(flint): add note-style skill"
```

---

## Task 5: `hybrid-linking` skill

**Files:**
- Create: `plugins/flint/skills/hybrid-linking.md`

- [ ] **Step 1: Create the skill file**

````markdown
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
````

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/skills/hybrid-linking.md
git commit -m "feat(flint): add hybrid-linking skill"
```

---

## Task 6: `/flint:obsidian-setup` command

**Files:**
- Create: `plugins/flint/commands/obsidian-setup.md`

- [ ] **Step 1: Create the command file**

````markdown
---
name: obsidian-setup
description: Initialize flint for an Obsidian vault — pick a preset layout, override paths, write config.json, scaffold folders, install prompt-capture hook
---

# obsidian-setup

Guide the user through setting up flint for their Obsidian vault.

## Step 1: Locate the vault

Ask the user for the absolute path to their Obsidian vault. Validate it exists and is a directory. If the user does not have one yet, tell them to create the directory first and re-run.

Save the path to `~/.config/flint/vault-path` (create the directory if needed).

## Step 2: Choose a preset

Show the three preset layouts with a one-line summary each:

1. **zettelkasten** — flat `Notes/`, `Maps/`, `Prompts/`
2. **projects-prompts** — `Projects/<name>/`, `Prompts/`, `Sessions/`, `Reports/`
3. **research** — `Topics/`, `Sources/`, `Maps/`, `Reports/`

Read the chosen preset from `plugins/flint/templates/presets/<preset>.json`.

## Step 3: Per-folder override

Ask: "Do you want to override any folder names?" For each path in the preset, offer the default and accept an override. This makes the layout fully user-defined while still starting from a preset.

## Step 4: Personalization (basic)

Ask four short questions (defer deeper personalization to `/flint:personalize`):
- Voice: terse | narrative | bulleted
- Depth: summary | detailed
- Link style: wikilink | markdown
- Tag prefix (may be empty)

## Step 5: Write config + scaffold

Load `plugins/flint/templates/config.default.json`, overlay the chosen preset paths, overlay the user overrides, and write to `<vault>/.flint/config.json`.

Create every folder referenced in `paths` under `<vault>/` if missing.

## Step 6: Install the hook

Copy `plugins/flint/hooks/user-prompt-submit.sh` to `<vault>/.flint/user-prompt-submit.sh` and `chmod +x` it. Print the user the exact `settings.json` snippet they need to add to enable the hook (the plugin does not silently edit user settings):

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "command": "<vault>/.flint/user-prompt-submit.sh" }
    ]
  }
}
```

## Step 7: Confirm

Print the final config and the list of created folders. Tell the user to run `/flint:personalize` for deeper customization.

## Errors

- Vault path does not exist: ask again, do not create.
- `<vault>/.flint/config.json` already exists: ask whether to overwrite, back up to `config.json.bak` first if confirmed.
````

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/commands/obsidian-setup.md
git commit -m "feat(flint): add obsidian-setup command"
```

---

## Task 7: `/flint:personalize` command

**Files:**
- Create: `plugins/flint/commands/personalize.md`

- [ ] **Step 1: Create the command file**

````markdown
---
name: personalize
description: Configure note voice, depth, link style, tag prefix, and per-folder overrides. On re-run, asks which fields to adjust.
---

# personalize

## If config does not exist

Tell the user to run `/flint:obsidian-setup` first. Stop.

## If config exists

Read `<vault>/.flint/config.json`. Print the current `personalization` values and `paths` values.

Ask: "Which would you like to adjust?" Offer a numbered list:

1. Voice (`terse` / `narrative` / `bulleted`)
2. Depth (`summary` / `detailed`)
3. Link style (`wikilink` / `markdown`)
4. Tag prefix
5. Frontmatter fields (comma-separated list)
6. Folder paths (walk through each key in `paths`)
7. None — exit

For each selected item, ask one question at a time, validate the answer, and update the in-memory config.

## Write back

After the user is done, write the updated config back to `<vault>/.flint/config.json` atomically (write to `.tmp`, then rename). Back up the previous version to `config.json.bak`.

Print a diff of what changed.
````

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/commands/personalize.md
git commit -m "feat(flint): add personalize command"
```

---

## Task 8: `UserPromptSubmit` hook script (TDD)

**Files:**
- Create: `plugins/flint/hooks/user-prompt-submit.sh`
- Create: `plugins/flint/test/hook.bats`

The hook is the only real code in flint. TDD applies.

- [ ] **Step 1: Write the failing test**

Create `plugins/flint/test/hook.bats`:

```bash
#!/usr/bin/env bats

setup() {
  export TEST_TMP="$(mktemp -d)"
  export FLINT_VAULT="$TEST_TMP/vault"
  mkdir -p "$FLINT_VAULT/.flint"
  HOOK="$BATS_TEST_DIRNAME/../hooks/user-prompt-submit.sh"
}

teardown() {
  rm -rf "$TEST_TMP"
}

@test "appends JSONL line with prompt, timestamp, cwd" {
  echo '{"prompt":"hello world"}' | "$HOOK"
  run cat "$FLINT_VAULT/.flint/prompts.log"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"prompt":"hello world"'* ]]
  [[ "$output" == *'"ts":'* ]]
  [[ "$output" == *'"cwd":'* ]]
}

@test "exits 0 when FLINT_VAULT is unset (best-effort)" {
  unset FLINT_VAULT
  run bash -c 'echo "{}" | "$0"' "$HOOK"
  [ "$status" -eq 0 ]
}

@test "exits 0 when vault dir does not exist (best-effort)" {
  export FLINT_VAULT="$TEST_TMP/does-not-exist"
  run bash -c 'echo "{}" | "$0"' "$HOOK"
  [ "$status" -eq 0 ]
}

@test "creates .flint dir if vault exists but .flint does not" {
  rm -rf "$FLINT_VAULT/.flint"
  echo '{"prompt":"x"}' | "$HOOK"
  [ -f "$FLINT_VAULT/.flint/prompts.log" ]
}

@test "skips malformed JSON input silently" {
  run bash -c 'echo "not json" | "$0"' "$HOOK"
  [ "$status" -eq 0 ]
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd plugins/flint && bats test/hook.bats`
Expected: all tests fail — hook script does not exist yet.

- [ ] **Step 3: Implement the hook**

Create `plugins/flint/hooks/user-prompt-submit.sh`:

```bash
#!/usr/bin/env bash
# UserPromptSubmit hook for flint.
# Appends a JSONL line to <vault>/.flint/prompts.log. Best-effort: never fails.

set -u
input="$(cat || true)"

# Best-effort: bail silently if vault unset or missing.
if [ -z "${FLINT_VAULT:-}" ]; then exit 0; fi
if [ ! -d "$FLINT_VAULT" ]; then exit 0; fi

mkdir -p "$FLINT_VAULT/.flint" 2>/dev/null || exit 0
log="$FLINT_VAULT/.flint/prompts.log"

# Extract .prompt from input JSON if possible; otherwise empty.
prompt=""
if command -v jq >/dev/null 2>&1; then
  prompt="$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null || true)"
fi

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cwd="$(pwd)"

# Emit a single JSONL line. Escape quotes and backslashes in prompt/cwd.
esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
printf '{"ts":"%s","cwd":"%s","prompt":"%s"}\n' \
  "$ts" "$(esc "$cwd")" "$(esc "$prompt")" >> "$log" 2>/dev/null || true

exit 0
```

Then: `chmod +x plugins/flint/hooks/user-prompt-submit.sh`

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd plugins/flint && bats test/hook.bats`
Expected: all 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add plugins/flint/hooks/user-prompt-submit.sh plugins/flint/test/hook.bats
git commit -m "feat(flint): add UserPromptSubmit hook with tests"
```

---

## Task 9: `hooks.json` stub

**Files:**
- Create: `plugins/flint/hooks/hooks.json`

- [ ] **Step 1: Create reference hook config**

Claude Code plugins do not auto-install user hooks — this file is a reference the setup command prints for the user to copy into their settings.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "command": "$FLINT_VAULT/.flint/user-prompt-submit.sh" }
    ]
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/hooks/hooks.json
git commit -m "feat(flint): add reference hook config"
```

---

## Task 10: `/flint:quick-note` command

**Files:**
- Create: `plugins/flint/commands/quick-note.md`

- [ ] **Step 1: Create the command file**

````markdown
---
name: quick-note
description: Drop a quick note into the vault. Accepts an optional title; infers folder from preset.
---

# quick-note

## Inputs

User invokes `/flint:quick-note <optional text>`. If no text is given, prompt for the note body.

## Steps

1. Invoke the `vault-paths` skill to resolve the vault root and the `notes` folder.
2. Invoke the `note-style` skill for voice/depth/link/tag rules.
3. Generate a title from the first non-empty line of the body (max 60 chars, title-cased).
4. Build the filename: `<notes>/<YYYY-MM-DD>-<slug>.md`. If it already exists, append `-2`, `-3`, etc.
5. Render frontmatter from `templates/note.frontmatter.md` with:
   - `title` = generated title
   - `created` = current ISO8601 timestamp
   - `project` = basename of current git repo (or `unknown`)
   - `source` = `flint/quick-note`
   - `tags` = [] (user can add later)
   - `related` = []
6. Write the file. Print the path.

No linking. No LLM proposals. Minimum ceremony.
````

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/commands/quick-note.md
git commit -m "feat(flint): add quick-note command"
```

---

## Task 11: `/flint:session-note` command

**Files:**
- Create: `plugins/flint/commands/session-note.md`

- [ ] **Step 1: Create the command file**

````markdown
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
````

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/commands/session-note.md
git commit -m "feat(flint): add session-note command"
```

---

## Task 12: `/flint:deep-note` command

**Files:**
- Create: `plugins/flint/commands/deep-note.md`

- [ ] **Step 1: Create the command file**

````markdown
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
   - Each note gets canonical frontmatter with `source: flint/deep-note` and `related: [[<report-title>]]`
   - Filename: `<notes>/<YYYY-MM-DD>-deep-<slug>.md`
6. Invoke `hybrid-linking`: propose related links to existing notes in the vault. Present for review. Write only accepted proposals into `related`.
7. Print the list of created paths.
````

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/commands/deep-note.md
git commit -m "feat(flint): add deep-note command"
```

---

## Task 13: `git-analyzer` agent

**Files:**
- Create: `plugins/flint/agents/git-analyzer.md`

- [ ] **Step 1: Create the agent file**

````markdown
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
````

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/agents/git-analyzer.md
git commit -m "feat(flint): add git-analyzer agent"
```

---

## Task 14: `/flint:git-analysis` command

**Files:**
- Create: `plugins/flint/commands/git-analysis.md`

- [ ] **Step 1: Create the command file**

````markdown
---
name: git-analysis
description: Generate a git history report (areas, most-edited files, velocity, bug hotspots) for the current repo
---

# git-analysis

## Preconditions

- Cwd is a git repo (`git rev-parse --is-inside-work-tree`); if not, error and stop
- `vault-paths` resolves `reports` folder

## Step 1: Gather deterministic stats

Run these git commands and parse their output into a JSON payload matching the `git-analyzer` input contract:

```bash
git log --numstat --pretty=format:'%H%x09%s'                 # for most_edited + fix_commits
git log --pretty=format:'%H%x09%ad%x09%s' --date=iso          # for velocity by ISO week
git ls-files | awk -F/ '{print $1}' | sort -u                 # top-level dirs → areas
git log --pretty=format:'%s' --grep='fix\|bug\|hotfix' -i     # fix commits
```

Extract:
- `most_edited`: top 20 paths by total change count
- `velocity`: aggregate commits + loc by ISO week
- `areas`: top-level dirs + commit count + file count
- `fix_commits`: subject, files touched, issue refs (regex `#\d+`)
- `hotspots`: files that appear in ≥2 fix commits, sorted by `fix_count` desc

Always full rescan. No cursors.

## Step 2: Dispatch to git-analyzer

Pass the JSON payload and the output path `<reports>/git-analysis-<project>.md` to the `git-analyzer` subagent. It writes the narrative report.

## Step 3: Print the report path

Idempotent: re-running overwrites the previous report.
````

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/commands/git-analysis.md
git commit -m "feat(flint): add git-analysis command"
```

---

## Task 15: `memory-analyzer` agent

**Files:**
- Create: `plugins/flint/agents/memory-analyzer.md`

- [ ] **Step 1: Create the agent file**

````markdown
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
````

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/agents/memory-analyzer.md
git commit -m "feat(flint): add memory-analyzer agent"
```

---

## Task 16: `/flint:memory-analysis` command

**Files:**
- Create: `plugins/flint/commands/memory-analysis.md`

- [ ] **Step 1: Create the command file**

````markdown
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
````

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/commands/memory-analysis.md
git commit -m "feat(flint): add memory-analysis command"
```

---

## Task 17: `prompt-gatherer` agent

**Files:**
- Create: `plugins/flint/agents/prompt-gatherer.md`

- [ ] **Step 1: Create the agent file**

````markdown
---
name: prompt-gatherer
description: Read Claude session JSONL history and the flint hook log; dedupe and write a prompt inbox
---

# prompt-gatherer

## Inputs

- Path to `~/.claude/projects/<project>/` (directory of session JSONL files)
- Path to `<vault>/.flint/prompts.log` (hook log — may not exist)
- Output path: `<prompts>/inbox.md`

## Task

1. Read every session JSONL under the projects directory. Extract user-role messages.
2. If the hook log exists, read it (JSONL with `{ts, cwd, prompt}`).
3. Merge both sources. Dedupe on `(prompt, ts-to-the-minute)`.
4. Sort by timestamp descending (newest first).
5. Drop prompts shorter than 10 chars and prompts that start with `/` (slash commands are already tracked elsewhere).

## Output

Write `<prompts>/inbox.md` with canonical frontmatter (`source: flint/gather-prompts`, `tags: [prompts, inbox]`).

Body: a bulleted list, each item:

```markdown
- `<iso-ts>` — <first 200 chars of prompt> `[source: session|hook]`
```

Idempotent: overwrite on every run.
````

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/agents/prompt-gatherer.md
git commit -m "feat(flint): add prompt-gatherer agent"
```

---

## Task 18: `/flint:gather-prompts` command

**Files:**
- Create: `plugins/flint/commands/gather-prompts.md`

- [ ] **Step 1: Create the command file**

````markdown
---
name: gather-prompts
description: Read recent prompts from Claude session history and the flint hook log; write a prompt inbox note
---

# gather-prompts

## Steps

1. Invoke `vault-paths` to resolve `prompts` folder.
2. Resolve the Claude projects directory for the current repo (`~/.claude/projects/<encoded-path>/`).
3. Dispatch to `prompt-gatherer` with:
   - projects dir path
   - `<vault>/.flint/prompts.log` (even if missing — the agent handles absence)
   - output: `<prompts>/inbox.md`
4. Print the output path and total prompt count.
````

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/commands/gather-prompts.md
git commit -m "feat(flint): add gather-prompts command"
```

---

## Task 19: `prompt-organizer` agent

**Files:**
- Create: `plugins/flint/agents/prompt-organizer.md`

- [ ] **Step 1: Create the agent file**

````markdown
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
````

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/agents/prompt-organizer.md
git commit -m "feat(flint): add prompt-organizer agent"
```

---

## Task 20: `/flint:organize-prompts` command

**Files:**
- Create: `plugins/flint/commands/organize-prompts.md`

- [ ] **Step 1: Create the command file**

````markdown
---
name: organize-prompts
description: Split the prompt inbox into linked, tagged prompt notes with frequent-use flags
---

# organize-prompts

## Preconditions

`<prompts>/inbox.md` must exist. If missing, tell the user to run `/flint:gather-prompts` first.

## Steps

1. Invoke `vault-paths` to resolve `prompts` folder.
2. Ensure `<prompts>/notes/` exists (create if missing).
3. Dispatch to `prompt-organizer` agent with inbox path, notes dir, and existing vault notes for link proposals.
4. Present any LLM link proposals for user approval before any file is written.
5. Print summary.
````

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/commands/organize-prompts.md
git commit -m "feat(flint): add organize-prompts command"
```

---

## Task 21: `content-mapper` agent

**Files:**
- Create: `plugins/flint/agents/content-mapper.md`

- [ ] **Step 1: Create the agent file**

````markdown
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
````

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/agents/content-mapper.md
git commit -m "feat(flint): add content-mapper agent"
```

---

## Task 22: `/flint:content-mapping` command

**Files:**
- Create: `plugins/flint/commands/content-mapping.md`

- [ ] **Step 1: Create the command file**

````markdown
---
name: content-mapping
description: Build or update a Map of Content for a targeted section of the vault
---

# content-mapping

## Inputs

User invokes `/flint:content-mapping <section>`. `<section>` is a relative path inside the vault (e.g., `Notes/authentication` or `Projects/anvil`).

## Steps

1. Invoke `vault-paths` to resolve `maps` folder + validate the target section exists.
2. Enumerate notes under `<vault>/<section>/**/*.md`, parsing their frontmatter.
3. MOC path: `<maps>/<section-slug>-MOC.md` (slashes in section → hyphens).
4. Dispatch to `content-mapper` agent with section path, existing MOC path, and note list.
5. Present link proposals for review.
6. Write the MOC. Idempotent: overwrite on every run.
7. Print the MOC path.
````

- [ ] **Step 2: Commit**

```bash
git add plugins/flint/commands/content-mapping.md
git commit -m "feat(flint): add content-mapping command"
```

---

## Task 23: Test fixtures + smoke-test checklist

**Files:**
- Create: `plugins/flint/test/fixtures/vault/.flint/config.json`
- Create: `plugins/flint/test/fixtures/repo/.gitkeep`
- Create: `plugins/flint/test/smoke-checklist.md`

- [ ] **Step 1: Create fixture vault config**

```json
{
  "version": 1,
  "preset": "projects-prompts",
  "paths": {
    "reports": "Reports",
    "prompts": "Prompts",
    "sessions": "Sessions",
    "maps": "Maps",
    "notes": "Notes",
    "projects": "Projects"
  },
  "personalization": {
    "voice": "bulleted",
    "depth": "summary",
    "link_style": "wikilink",
    "tag_prefix": "",
    "frontmatter_fields": ["tags", "related", "source", "project"]
  }
}
```

- [ ] **Step 2: Create the synthetic git repo fixture script**

The fixture repo is generated on demand rather than committed as a live repo. Add a setup script `plugins/flint/test/fixtures/repo/setup.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
dir="$(dirname "$0")"
rm -rf "$dir/src" "$dir/.git"
cd "$dir"
git init -q
mkdir -p src/api src/ui
echo "a" > src/api/auth.py && git add . && git commit -qm "feat: initial auth"
echo "b" >> src/api/auth.py && git commit -qam "fix: auth bug #1"
echo "c" >> src/api/auth.py && git commit -qam "fix: auth hotfix #2"
echo "d" > src/ui/button.tsx && git add . && git commit -qm "feat: button"
echo "e" >> src/ui/button.tsx && git commit -qam "fix: button hover #3"
```

`chmod +x plugins/flint/test/fixtures/repo/setup.sh`

Keep a `.gitkeep` in the fixture repo dir so it exists even before `setup.sh` runs.

- [ ] **Step 3: Create smoke-test checklist**

Create `plugins/flint/test/smoke-checklist.md`:

```markdown
# Flint Smoke-Test Checklist

Run in order against a scratch vault:

1. [ ] `/flint:obsidian-setup` — creates `<vault>/.flint/config.json` + folders
2. [ ] `/flint:personalize` — round-trip config update, backup created
3. [ ] UserPromptSubmit hook — send a prompt, verify `prompts.log` has a new line
4. [ ] `/flint:quick-note hello` — creates a note with valid frontmatter
5. [ ] `/flint:session-note` — writes session note + updates `Prompts/inbox.md`
6. [ ] `/flint:git-analysis` — run against fixture repo, verify report has all 6 H2 sections and no invented numbers
7. [ ] `/flint:memory-analysis` — verify report lists covered + gaps
8. [ ] `/flint:gather-prompts` — verify inbox dedupes hook + session sources
9. [ ] `/flint:organize-prompts` — verify link proposals are presented for review
10. [ ] `/flint:content-mapping Notes` — MOC page written with H2 groups
11. [ ] `/flint:deep-note <report> "Bug Hotspots"` — detailed expansion written
12. [ ] Re-run every command → confirms idempotent overwrite
```

- [ ] **Step 4: Commit**

```bash
git add plugins/flint/test/fixtures plugins/flint/test/smoke-checklist.md
git commit -m "test(flint): add fixtures and smoke-test checklist"
```

---

## Task 24: Final verification

- [ ] **Step 1: Run the hook test suite**

Run: `cd plugins/flint && bats test/hook.bats`
Expected: 5 passing.

- [ ] **Step 2: Generate the fixture repo and run git-analysis manually**

Run: `bash plugins/flint/test/fixtures/repo/setup.sh && cd plugins/flint/test/fixtures/repo && /flint:git-analysis`
Expected: a report is written to the fixture vault's `Reports/` folder; `hotspots` lists `src/api/auth.py` and `src/ui/button.tsx`.

- [ ] **Step 3: Walk the smoke-test checklist**

Go through `plugins/flint/test/smoke-checklist.md` end-to-end against a scratch vault. Check every box. Any failures → fix and re-run.

- [ ] **Step 4: Bump plugin version + final commit**

Edit `plugins/flint/.claude-plugin/plugin.json`: bump `version` to `0.1.0` (already set) and confirm the description is accurate.

```bash
git add plugins/flint/.claude-plugin/plugin.json
git commit --allow-empty -m "feat(flint): v0.1.0 — initial release"
```

---

## Spec Coverage Check

| Spec section | Implemented by |
|---|---|
| Plugin location `plugins/flint/` | Task 1 |
| Vault `.flint/config.json` + `prompts.log` | Tasks 2, 6, 8 |
| Presets + overrides | Tasks 2, 6, 7 |
| `obsidian-setup` | Task 6 |
| `personalize` | Task 7 |
| `git-analysis` + `git-analyzer` | Tasks 13, 14 |
| `memory-analysis` + `memory-analyzer` | Tasks 15, 16 |
| `gather-prompts` + `prompt-gatherer` | Tasks 17, 18 |
| `organize-prompts` + `prompt-organizer` | Tasks 19, 20 |
| `content-mapping` + `content-mapper` | Tasks 21, 22 |
| `quick-note`, `session-note`, `deep-note` | Tasks 10, 11, 12 |
| `vault-paths`, `note-style`, `hybrid-linking` skills | Tasks 3, 4, 5 |
| UserPromptSubmit hook | Tasks 8, 9 |
| Idempotent, no cursors | Tasks 13–22 |
| Error handling (vault missing, non-repo, malformed log) | Tasks 3, 8, 14 |
| Fixture vault + repo + snapshot tests + smoke checklist | Tasks 8, 23, 24 |
| LLM link proposals always reviewed | Tasks 5, 19, 21 |
