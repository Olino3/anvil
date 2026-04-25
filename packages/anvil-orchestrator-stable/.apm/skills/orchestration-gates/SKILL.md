---
name: orchestration-gates
description: When the flattened orchestration pauses for user approval or reports an error, and how to resume from the pause point. Applies to all four anvil-* orchestrator workflows.
user-invocable: false
---

# Orchestration Gates

The four orchestrator workflows in `anvil-orchestrator-stable` each pause
at well-defined gates. In v2.0.0, orchestration runs in the **main
session** (no orchestrator sub-agent) — Claude Code does not support
nested sub-agent dispatch, so the prior agent-based design was flattened.
This skill documents when a gate fires and how to resume from it.

## Approval gates (single-approval-per-stage)

| Workflow | Gate location | Question |
|---|---|---|
| `/anvil-develop` | After plan is produced | "Proceed with this plan?" |
| `/anvil-develop` | After all work complete | Integration choice: squash / merge / PR / keep / discard |
| `/anvil-sprint` | After sprint generated | "Develop `<ticket>` now?" |
| `/anvil-roadmap` | After roadmap saved | "Kick off a sprint for `<phase>` now?" |
| `/anvil-review` | After BA-REPORT written | "Apply all recommended actions?" |

Approving advances the workflow through its next phase. Declining stops
the workflow cleanly.

## Error gates (workflow stops and reports)

- **`/anvil-develop`**: RED commit missing, or tests fail for the wrong
  reason after the `@red` sub-agent returns.
- **`/anvil-develop`**: GREEN commit missing, or tests still fail after
  the `@green` sub-agent returns.
- **`/anvil-develop`**: verification step in ticket fails after REFACTOR.
- **All workflows**: ticket / sprint / config file missing or malformed.

On an error gate, the workflow stops, reports the problem, and does
**not** proceed. It does not auto-retry. The user investigates and
decides the next step.

## Resuming from a pause

Approval gates: simply respond with approval or rejection in the current
main session. There is no "resume" — the main session is waiting
synchronously.

Error gates: after the user fixes the problem (edits the ticket, fixes
the test, corrects config), they re-invoke the workflow from the top —
workflows are idempotent where possible. For `/anvil-develop`
specifically: if a worktree already exists for the ticket, it is reused.

## Dispatch model

Each workflow runs in the **main session** and dispatches leaf sub-agents
flat, one at a time:

- `/anvil-develop` — dispatches `@dev-plan`, `@red`, then `@green`
- `/anvil-sprint` — dispatches `@pm`
- `/anvil-roadmap` — dispatches `@pd`
- `/anvil-review` — dispatches `@ba`, then (on approval) `@sprint-syncer`

Handoffs between workflows (sprint → develop, roadmap → sprint) inline
the target workflow into the main session. The main session is always
the one calling Task — sub-agents never dispatch further sub-agents.

## What this skill is NOT

- Not a checkpoint or resumable-state system. v2.0.0 workflows are
  session-scoped; there is no persistence across process restarts.
- Not a multi-ticket loop. `/anvil-sprint` handoff is one ticket only.
  Auto-develop-every-ticket is reserved for `anvil-autonomous-stable`
  (future package).
