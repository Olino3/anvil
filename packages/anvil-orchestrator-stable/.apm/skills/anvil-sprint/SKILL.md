---
name: anvil-sprint
description: Use when generating a sprint for one ROADMAP phase. Dispatches @pm, then optionally inlines the develop workflow for the first unblocked ticket. All sub-agent dispatch from the main session.
user-invocable: true
---

# Anvil Sprint — Flattened (Main-Session Driven)

## Invocation

- Slash command: `/anvil-sprint <phase>`
- APM runtime: `apm run anvil-sprint --param phase=<phase>`

## Arguments

- `phase` (required, string) — ROADMAP phase identifier. Matched
  case-insensitively with precedence: exact name > phase number >
  prefix (e.g., `MVP`, `2`, `Phase 2`, `Auth System`). If ambiguous,
  the workflow halts and asks the user to disambiguate.

## Authoritative source

The executable workflow is `anvil-sprint.prompt.md` (orchestrator
override, this package). Read that file for the full step-by-step
procedure. This skill summarizes role and boundaries only.

## Stages

The main session runs the workflow flat from itself.

| # | Stage | Owner | Notes |
|---|---|---|---|
| 1 | Prep | main session | Verify `docs/anvil/config.yml`; **Read** `ROADMAP.md` and resolve `<phase>` per the precedence rules; check for an existing sprint at `docs/anvil/sprints/{slug}/`; create the sprint feature branch. |
| 2 | Generate sprint | `@pm` (Task) | Creates the sprint directory, ticket files, and sprint `README.md`. Returns directory path, ticket counts, and the sorted unblocked-ticket list. |
| 3 | Commit | main session | Stage `docs/anvil/sprints/{slug}/` and commit `chore(sprint): generate {slug} sprint tickets`. Halt without committing if `@pm` produced an empty directory or missing README. |
| 4 | Report | main session | Output sprint path, ticket count by type (main + SPIKE), unblocked ticket IDs in sort order. |
| 5 | Handoff offer | main session | If the unblocked list is empty, emit `No unblocked tickets in this sprint. Resolve dependencies before developing.` and stop. Otherwise prompt the user with the literal string: `Develop <first-unblocked-ticket-id> now? (yes/no)` Accept only `yes` / `y` (case-insensitive). |
| 6a | If yes | main session (inline) | Inline-execute `anvil-develop.prompt.md` (orchestrator version, this package) with `${input:ticket} = <first-unblocked-ticket-id>`. |
| 6b | If no | main session | Stop. Output the recommended next command: `/anvil-develop <first-unblocked-ticket-id>`. |

## Sub-agent dispatch shape

```
Task(subagent_type="pm", prompt="<pm template from prompt file>")
```

The exact prompt template lives in `anvil-sprint.prompt.md`; pass it
verbatim.

## Error handling

| Condition | Action |
|---|---|
| `ROADMAP.md` missing | Halt. Emit `No ROADMAP.md found. Run /anvil-roadmap first.` |
| Phase not found | Halt. Emit `No ROADMAP phase matches '<phase>'.` |
| Phase ambiguous | Halt. List candidates and ask. |
| Sprint directory exists | Ask `Regenerate sprint? This will overwrite tickets in docs/anvil/sprints/{slug}/. (yes/no)` Reuse on anything but `yes`. |
| `@pm` dispatch failed or empty output | Halt. Surface `@pm` error; do not invent tickets. |

## Constraints

- **Flat sub-agent dispatches only.** The `@pm` dispatch in Stage 2,
  and any sub-agents from the inlined `anvil-develop.prompt.md`
  workflow (`dev-plan`, `red`, `green`), all originate from this same
  main session — never via a nested orchestrator sub-agent.
- **One ticket only.** No multi-ticket loop. If the user asks for
  auto-develop-every-ticket, emit: `Multi-ticket auto-develop is
  reserved for anvil-autonomous-stable (future package).`
- **Handoff is inline workflow execution**, not a sub-agent call.
- **Skill loading is not a substitute for sub-agent dispatch.** Do NOT
  load `anvil-develop` skill in place of inline-executing the
  orchestrator develop prompt.

## On completion

Output:

```
### Sprint
- Path: docs/anvil/sprints/{slug}/
- Tickets: main=N, SPIKE=M
- First unblocked: <ticket-id, or "none">

### Handoff
- {ran (with outcome) | declined | not offered (no unblocked tickets)}

### Next
- {next-step command}
```
