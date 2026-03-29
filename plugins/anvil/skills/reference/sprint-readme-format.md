# Sprint README Format

Reference file for pm-agent, ba-agent, sprint-syncer-agent, and dev-agent. Defines the canonical format for sprint README.md files.

## Location

`docs/anvil/sprints/{directory}/README.md`

Sprint directory naming:
- With version: `{version}-{phase-slug}/` (e.g., `v1.0.0-mvp/`)
- Without version: `{phase-slug}/` (e.g., `mvp/`)

Phase slug is the phase name in lowercase kebab-case.

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
| [{PREFIX}-001]({PREFIX}-001-slug.md) | {Title} | {component} | Open | -- |
| [{PREFIX}-002]({PREFIX}-002-slug.md) | {Title} | {component} | Open | {PREFIX}-001 |
| [SPIKE-001](SPIKE-001-slug.md) | {Title} | {component} | Open | -- |

## Dependency Graph

{PREFIX}-001 ({short label})
  ├── {PREFIX}-002 ({short label})
  │   └── {PREFIX}-003 ({short label})
  └── {PREFIX}-004 ({short label})

## Status Summary

| Status | Count | Tickets |
|---|---|---|
| Done | 0 | — |
| In Progress | 0 | — |
| Open | {N} | {ticket list} |
| Blocked | 0 | — |

## Definition of Done

- [ ] {High-level criterion from ROADMAP deliverables}
- [ ] All tickets Done and verified
- [ ] All tests pass
- [ ] BA report clean
```

## Section Responsibilities

| Section | Created By | Updated By |
|---|---|---|
| Header (Goal, Phase, Branch) | pm-agent | — (static) |
| Tickets table | pm-agent | dev-agent (status), ba-agent (status), sprint-syncer (sync) |
| Dependency Graph | pm-agent | pm-agent (if tickets added), sprint-syncer (sync) |
| Status Summary | pm-agent | ba-agent, sprint-syncer |
| Definition of Done | pm-agent (from ROADMAP) | ba-agent (checks boxes) |

## Update Rules

- When dev-agent marks a ticket In Progress or Done, it updates the Status column in the Tickets table and recalculates the Status Summary
- When dev-agent creates a SPIKE ticket, it adds a row to the Tickets table and updates the Dependency Graph
- ba-agent rebuilds all sections during review
- sprint-syncer-agent rebuilds Tickets table and Status Summary from ticket file metadata (source of truth is the ticket files, not the README)
