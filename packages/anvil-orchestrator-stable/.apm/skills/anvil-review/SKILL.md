---
name: anvil-review
description: Sprint health + verification via ba, then apply recommended cleanup with a single all-or-nothing approval via review-orchestrator.
user-invocable: true
---

# Anvil Review — Orchestrated

## Invocation

- Slash command: `/anvil:review <phase>`
- APM runtime: `apm run anvil:review --param phase=<phase>`
- Agent mention: `@review-orchestrator <phase>`

Run sprint health analysis and verification, then optionally apply the
recommended cleanup with a single all-or-nothing approval. This skill
overrides the core `anvil-review` report-only behavior; with
`anvil-orchestrator-stable` installed, cleanup application is added as a
second, gated phase.

## Arguments

- `phase` (required) — the target sprint by phase name, version, or prefix

## Procedure

### 1. Invoke review-orchestrator

Invoke the `@review-orchestrator` agent for the phase. The agent follows
its own documented workflow (see `review-orchestrator.agent.md`):

1. Invoke the `@ba` agent (from `anvil-core-stable`) to produce `BA-REPORT.md` with a **Recommended actions** section following `ba-report-format` (from `anvil-common-stable`)
2. Present the recommendations to the user, grouped by action type (splits, archival, dependency healing, status corrections)
3. Ask the user: *"Apply all recommended actions? (y/N)"*
4. If approved: apply every action, then invoke `@sprint-syncer <phase>` to rebuild the sprint README
5. If declined: stop; print `BA-REPORT.md written; no actions applied.`

### 2. Constraints

- **Do not invoke `@ba` directly from this skill.** `@review-orchestrator` owns the report + apply flow.
- **All-or-nothing approval.** The user approves the full recommendation set, or none of it. No partial application in v2.0.0.
- **Never auto-downgrade a Done ticket.** If `@ba` reports a Done ticket's verification failed, the orchestrator flags it loudly but does not change Status — the user decides whether to reopen.

### 3. On completion

Report:
- Path to the generated `BA-REPORT.md`
- Whether recommendations were applied (with a summary of what changed)
- Any verification failures that still need human attention
