---
name: orchestration-gates
description: When an orchestrator pauses for user approval or reports an error, and how to resume from the pause point. Applies to all four anvil-orchestrator agents.
user-invocable: false
---

# Orchestration Gates

The four orchestrator agents in anvil-orchestrator-stable each pause at
well-defined gates. This skill documents when a gate fires and how to
resume from it.

## Approval gates (single-approval-per-stage)

| Orchestrator | Gate location | Question |
|---|---|---|
| develop-orchestrator | After plan is produced | "Proceed with this plan?" |
| develop-orchestrator | After all work complete | Integration choice: squash / merge / PR / keep / discard |
| sprint-orchestrator | After sprint generated | "Develop `<ticket>` now?" |
| roadmap-orchestrator | After roadmap saved | "Kick off a sprint for `<phase>` now?" |
| review-orchestrator | After BA-REPORT written | "Apply all recommended actions?" |

Approving advances the orchestrator through the next phase of its workflow.
Declining stops the orchestrator cleanly.

## Error gates (orchestrator stops and reports)

- **develop-orchestrator**: RED commit missing, or tests fail for the wrong
  reason after RED.
- **develop-orchestrator**: GREEN commit missing, or tests still fail after
  GREEN.
- **develop-orchestrator**: verification step in ticket fails after REFACTOR.
- **All orchestrators**: ticket/sprint/config file missing or malformed.

On an error gate, the orchestrator stops, reports the problem, and does
**not** proceed. It does not auto-retry. The user investigates and decides
the next step.

## Resuming from a pause

Approval gates: simply respond with approval or rejection in the current
session. There is no "resume" — the orchestrator is waiting synchronously.

Error gates: after the user fixes the problem (edits the ticket, fixes the
test, corrects config), they re-invoke the orchestrator from the top —
orchestrators are idempotent where possible. For develop-orchestrator
specifically: if a worktree already exists for the ticket, it is reused.

## What this skill is NOT

- Not a sub-agent dispatch manager. Orchestrators dispatch `@red` and
  `@green` directly.
- Not a checkpoint or resumable-state system. v2.0.0 orchestrators are
  session-scoped; there is no persistence across process restarts.
