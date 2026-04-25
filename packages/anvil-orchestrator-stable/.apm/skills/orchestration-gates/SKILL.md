---
name: orchestration-gates
description: Use when an anvil orchestrator workflow pauses at an approval gate, stops on an error, or requires resumption after intervention. Reference document — not invoked directly. Applies to all four `anvil-*` orchestrator workflows.
user-invocable: false
---

# Orchestration Gates

The four orchestrator workflows in `anvil-orchestrator-stable` each
pause at well-defined gates. Workflows run in the **main session**;
sub-agents are dispatched flat and never nest.

## What this skill is NOT

- Not a checkpoint or resumable-state system. Workflows are
  session-scoped; there is no persistence across process restarts.
- Not a multi-ticket loop. `/anvil-sprint` handoff is one ticket only.
  Auto-develop-every-ticket is reserved for `anvil-autonomous-stable`
  (future package).
- Not executable on its own. Other workflows reference this skill to
  decide when to pause and how to resume.

## Dispatch model

Each workflow runs in the main session and dispatches leaf sub-agents
flat, one at a time. Sub-agent names referenced in the gate tables
below resolve to these dispatches:

- `/anvil-develop` — dispatches `@dev-plan`, `@red`, then `@green`.
- `/anvil-sprint` — dispatches `@pm`.
- `/anvil-roadmap` — dispatches `@pd`.
- `/anvil-review` — dispatches `@ba`, then (on approval) `@sprint-syncer`.

Handoffs between workflows (sprint → develop, roadmap → sprint) inline
the target workflow into the main session. The main session is always
the one calling Task — sub-agents never dispatch further sub-agents.

## Approval gates

Each gate fires once per workflow phase (plan review, sprint
generation, etc.) — exactly one approval decision is needed before
the phase advances.

| Workflow | Gate location | Question |
|---|---|---|
| `/anvil-develop` | After plan is produced | "Proceed with this plan?" |
| `/anvil-develop` | After all work complete | Integration choice: squash / merge / PR / keep / discard |
| `/anvil-sprint` | After sprint generated | "Develop `<ticket>` now?" |
| `/anvil-roadmap` | After roadmap saved | "Kick off a sprint for `<phase>` now?" |
| `/anvil-review` | After BA-REPORT written | "Apply all recommended actions?" |

Approving advances the workflow through its next phase. Declining
stops the workflow cleanly.

## Error gates (workflow stops and reports)

- **`/anvil-develop`**: RED commit missing, or tests fail for the
  wrong reason after the `@red` sub-agent returns.
- **`/anvil-develop`**: GREEN commit missing, or tests still fail
  after the `@green` sub-agent returns.
- **`/anvil-develop`**: verification step in ticket fails after
  REFACTOR.
- **All workflows**: ticket / sprint / config file missing or
  malformed.

On an error gate, the workflow stops, reports the problem, and does
**not** proceed. It does not auto-retry. The user investigates and
decides the next step.

## Resuming from a pause

Approval gates: respond with approval or rejection in the current main
session. No resume mechanism exists; the main session blocks
synchronously on user input.

Error gates: after the user fixes the problem (edits the ticket, fixes
the test, corrects config), invoke the workflow again by name (e.g.
`/anvil-develop` with the original ticket ID).

### Per-workflow idempotency

| Workflow | Re-invocation behavior |
|---|---|
| `/anvil-develop` | Reuses an existing worktree at `.worktrees/{ticket-id}` if the branch matches. Halts with a conflict message if the branch differs. |
| `/anvil-sprint` | Restarts from state zero. Halts and asks before overwriting an existing sprint directory. |
| `/anvil-roadmap` | Restarts from state zero. Skips the commit step if `git diff --name-only` shows no changes. |
| `/anvil-review` | Restarts from state zero. Overwrites any existing `BA-REPORT.md`. |
