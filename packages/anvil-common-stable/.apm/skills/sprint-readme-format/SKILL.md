---
name: sprint-readme-format
description: Use when creating or updating `docs/anvil/sprints/*/README.md`.
user-invocable: false
---

# Sprint README Format

Reference file for pm-agent, ba-agent, sprint-syncer-agent, and dev-agent. Defines the canonical format for sprint README.md files.

**Source of truth:** ticket files, not this README. The README is regenerated from ticket metadata. See `../ticket-template/SKILL.md` for ticket frontmatter schema.

**Precedence on conflict:** ticket files > sprint-syncer regeneration > in-place agent edits. Discard README state on full sync when it disagrees with ticket metadata.

## Location

`docs/anvil/sprints/{directory}/README.md`

Sprint directory naming:
- With version: `{version}-{phase-slug}/` (e.g., `v1.0.0-mvp/`)
- Without version: `{phase-slug}/` (e.g., `mvp/`)

Phase slug is the phase name in lowercase kebab-case. For example, "Auth System" → `auth-system`; "MVP" → `mvp`.

## Template

```markdown
# Sprint — {Phase Name} ({vX.Y.Z})

**Goal:** {One-sentence sprint goal derived from the ROADMAP phase theme.}
**ROADMAP Phase:** Phase {N} — {Theme}
**Branch:** {branch_prefix from config}phase-{slug}

---

## Tickets

| ID | Title | Component | Status | Depends On |
|---|---|---|---|---|
| [{PREFIX}-001]({PREFIX}-001-slug.md) | User login | auth | Done | — |
| [{PREFIX}-002]({PREFIX}-002-slug.md) | Session management | auth | In Progress | {PREFIX}-001 |
| [{PREFIX}-003]({PREFIX}-003-slug.md) | Logout flow | auth | Open | {PREFIX}-002 |
| [SPIKE-001](SPIKE-001-slug.md) | Evaluate JWT libraries | auth | Open | — |

## Dependency Graph

{PREFIX}-001 (User login)
├── {PREFIX}-002 (Session management)
│   └── {PREFIX}-003 (Logout flow)
└── SPIKE-001 (JWT evaluation)

## Status Summary

| Status | Count | Tickets |
|---|---|---|
| Done | 1 | {PREFIX}-001 |
| In Progress | 1 | {PREFIX}-002 |
| Open | 2 | {PREFIX}-003, SPIKE-001 |
| Blocked | 0 | — |

## Definition of Done

- [ ] All ROADMAP deliverables implemented and tested
- [ ] All tickets Done and verified
- [ ] All tests pass
- [ ] BA report clean (no gaps, no blockers)
```

**Placeholder legend:**
- `{var}` = substitute literal value
- `{branch_prefix from config}` = look up `git.branch_prefix` in `docs/anvil/config.yml`
- `—` (em-dash, U+2014) is canonical for empty/none cells; do not substitute `--` or `-`
- Dependency Graph box-drawing glyphs (`├──`, `│`, `└──`) are required UTF-8; no ASCII fallback
- When a sprint has no version (directory is `{phase-slug}/`), omit the ` ({vX.Y.Z})` suffix from the H1; the `**ROADMAP Phase:**` line is unchanged

## Section Responsibilities

| Section | Created By | Updated By |
|---|---|---|
| Header (Goal, Phase, Branch) | pm-agent | static — do not update |
| Tickets table | pm-agent | dev-agent (status), ba-agent (status), sprint-syncer (sync) |
| Dependency Graph | pm-agent | pm-agent (if tickets added), sprint-syncer (sync) |
| Status Summary | pm-agent | ba-agent, sprint-syncer |
| Definition of Done | pm-agent (from ROADMAP) | ba-agent (checks boxes) |

## Update Triggers & Procedures

| Trigger | Action | Actor | Notes |
|---|---|---|---|
| Ticket status changes (Open → In Progress → Done) | Edit Tickets table status cell + recompute Status Summary counts | dev-agent, ba-agent | Do not modify other sections |
| New ticket added to sprint | Append row to Tickets table + update Dependency Graph + recompute Status Summary | pm-agent or sprint-syncer | Update graph when ticket has `Depends On` |
| New SPIKE created | Append SPIKE row to Tickets table + update Dependency Graph with SPIKE node | dev-agent | SPIKE does not block; normal tickets depend on it if needed |
| Full sprint sync | Read all ticket files in sprint directory; regenerate Tickets table and Status Summary from scratch; preserve Header and Definition of Done sections | sprint-syncer-agent | Regenerate means overwrite, not merge; source of truth is ticket files |

## Output Contract

Agents must Read the existing README (if present), compute the new content, and Write the full file. Do not return content as a string for review; do not stage partial edits.

## Validation

Before writing README.md:

- [ ] Table row count == ticket file count in the sprint directory
- [ ] Every `Depends On` entry resolves to a row in the Tickets table (or is `—`)
- [ ] Status Summary counts sum to total tickets: Done + In Progress + Open + Blocked = Total
- [ ] Status Summary contains all four rows (Done, In Progress, Open, Blocked) even when count is 0; use `—` in the Tickets column
- [ ] Dependency Graph nodes exist in the Tickets table
- [ ] Status enum values (`Done`, `In Progress`, `Open`, `Blocked`) are exact and capitalized

## Status Enum

Valid status values (exact, case-sensitive):
- `Open` — new ticket, not started
- `In Progress` — active work
- `Done` — implementation complete and verified
- `Blocked` — waiting on a dependency
