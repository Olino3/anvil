---
name: anvil-review
description: Use when reviewing sprint health and applying recommended cleanup. Dispatches @ba, presents recommendations under one all-or-nothing approval gate, applies edits inline, then dispatches @sprint-syncer. All sub-agent dispatch from the main session.
user-invocable: true
---

# Anvil Review — Flattened (Main-Session Driven)

## Invocation

- Slash command: `/anvil-review <phase>`
- APM runtime: `apm run anvil-review --param phase=<phase>`

## Arguments

- `phase` (required, string) — sprint identifier matched against
  directory names under `docs/anvil/sprints/`. Resolution precedence
  (case-insensitive): exact name > version prefix > slug prefix. On a
  tie, halt and list candidates.

## Authoritative source

The executable workflow is `anvil-review.prompt.md` (orchestrator
override, this package). Read that file for the full step-by-step
procedure. This skill summarizes role and boundaries only.

## Steps

The main session runs the workflow flat from itself. Steps are
numbered to avoid collision with the `phase` argument.

| # | Step | Owner | Notes |
|---|---|---|---|
| 1 | Locate sprint | main session | Resolve `<phase>` per the precedence rules; halt with the available sprint list on no match. |
| 2 | BA analysis | `@ba` (Task) | Writes `BA-REPORT.md` in the sprint directory ending with the literal heading `## Recommended actions`. Overwrites any existing report. |
| 3 | Read recommendations | main session | **Read** `BA-REPORT.md`; halt if the report is missing or the heading is absent/empty. |
| 4 | Present | main session | Group recommendations under literal headings: **Ticket splits**, **Archival**, **Dependency healing**, **Status corrections**. Empty groups print `None.` |
| 5 | Approval gate | main session | Present approval gate with the literal string: `Apply all recommended actions? (y/N)` Accept only `y` / `yes` (case-insensitive). |
| 6 | Apply (on approval) | main session (inline) | Edit ticket files directly using `ticket-template` and `sprint-readme-format` (from `anvil-common-stable`). Apply order: splits → archival → dependency healing → status corrections. Halt the Apply step on the first action that fails or conflicts. |
| 6b | Sync README | `@sprint-syncer` (Task) | Dispatched only if step 6 modified at least one file (verify with `git status --porcelain`). Rebuilds the sprint `README.md` tickets table, dependency graph, and status summary. |
| 7 | If user declined | main session | Output `BA-REPORT.md written; no actions applied.` and stop. |

## Sub-agent dispatch shape

```
Task(subagent_type="ba",            prompt="<ba template from prompt file>")
Task(subagent_type="sprint-syncer", prompt="<sprint-syncer template from prompt file>")
```

The exact prompt templates live in `anvil-review.prompt.md`; pass them
verbatim.

| Sub-agent | Inputs | Expected artifact |
|---|---|---|
| `@ba` | sprint directory path, phase identifier | `{sprint_dir}/BA-REPORT.md` ending with `## Recommended actions` |
| `@sprint-syncer` | sprint directory path | Updated `{sprint_dir}/README.md`; status derived from ticket files only |

## Constraints

- **No orchestrator sub-agent.** Orchestration lives in the main
  session.
- **Flat sub-agent dispatches only.** Both `@ba` and
  `@sprint-syncer` dispatches originate from this main session.
- **All-or-nothing approval.** No partial application in v2.0.0.
- **Never auto-downgrade a Done ticket.** If `@ba` reports a Done
  ticket whose verification failed, emit a `VERIFICATION-FAILED`
  warning, list the ticket ID under "Verification failures requiring
  human attention" in the completion report, and do not modify Status.
- **Apply step is inline.** The main session edits files directly; no
  sub-agent.
- **Skill loading is not a substitute for sub-agent dispatch.** Do NOT
  load `anvil-review` or `anvil-sync` skills in place of the
  Task-tool dispatches.

## On completion

Output:

```
### Review
- BA report: {path to BA-REPORT.md}
- Approval: {applied | declined}
- Actions applied: {none | comma-separated by category, e.g. "2 splits, 1 archival"}
- Files modified: {count} ({comma-separated paths, or "none"})
- Sprint README rebuilt: {yes | no | not applicable}

### Verification failures requiring human attention
- {none | comma-separated ticket IDs with one-line reasons}
```
