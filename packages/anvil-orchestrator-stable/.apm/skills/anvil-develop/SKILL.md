---
name: anvil-develop
description: Use when developing one sprint ticket end-to-end. Drives plan → RED → GREEN → optional REFACTOR → verify → integration choice from the main session. Sub-agents (`dev-plan`, `red`, `green`) dispatched flat, one approval gate after the plan.
user-invocable: true
---

# Anvil Develop — Orchestrated (Flattened)

## Invocation

- Slash command: `/anvil-develop <ticket-id>`
- APM runtime: `apm run anvil-develop --param ticket=<ticket-id>`

## Arguments

- `ticket-id` (required) — the ticket to develop (e.g., `MVP-001`,
  `AUTH-003`, `SPIKE-002`).

## Authoritative source

The executable workflow is `anvil-develop.prompt.md` (orchestrator
override, this package). This skill summarizes role and boundaries
only — read the prompt for full step-by-step procedure.

## Phases

The main session runs the workflow flat from itself. Each row names
who owns the step.

| # | Phase | Owner | Notes |
|---|---|---|---|
| 1 | Prep | main session | Locate ticket, verify config, read sprint context, verify branch, auto-create worktree per `worktree-discipline`. |
| 2 | Plan | `dev-plan` (Task) | Returns RED/GREEN/REFACTOR plan to the main session. |
| 2a | Approval gate | main session | Relays plan; accepts `yes` / `y` / `proceed` / `approve`. On `needs changes: ...`, re-dispatches `dev-plan` with the redirection. Loop guard: 3 cycles. |
| 3 | RED | `red` (Task) | Writes failing test suite, commits with `test(...)` subject. |
| 4 | GREEN | `green` (Task) | Writes minimum production code, commits with `feat(...)` or `fix(...)` subject. |
| 5 | REFACTOR | main session (inline) | Triggered ONLY when GREEN introduces duplication ≥3 lines, an oversized function, an unclear name, or a leaky abstraction. Otherwise emit `No refactor needed.` and skip. |
| 6 | Verify | main session (inline) | Runs the ticket's `Verification Steps` section. If absent, emit `No verification steps defined; skipping.` |
| 7 | Close | main session (inline) | Sets ticket `Status: Done`, ticks satisfied acceptance criteria, updates sprint README. |
| 8 | Integration choice | main session (inline) | Presents the matrix: **squash merge / merge / open PR / keep worktree / discard**. Executes the chosen option per `worktree-discipline`. |

## Sub-agent dispatch shape

All Task-tool calls originate from the main session:

```
Task(subagent_type="dev-plan", prompt="<dev-plan template from prompt file>")
Task(subagent_type="red",      prompt="<red template from prompt file>")
Task(subagent_type="green",    prompt="<green template from prompt file>")
```

The exact prompt templates live in `anvil-develop.prompt.md`; pass them
verbatim to prevent prompt drift.

## Failure contract

If a sub-agent returns without its expected artifact, halt and report
to the user. Do not retry, do not invent the artifact.

| Sub-agent | Expected artifact |
|---|---|
| `dev-plan` | Structured plan markdown, OR Blocked Plan template |
| `red` | New commit whose subject begins with `test(` |
| `green` | New commit whose subject begins with `feat(` or `fix(` |

## Constraints

- **CRITICAL: use `dev-plan`, NOT `dev-discipline`.** `dev-discipline`
  is core's plan-and-stop agent — it ends the interaction on return.
  `dev-plan` is the orchestrator's plan-and-return leaf agent that
  hands flow control back to the main session.
- **No orchestrator sub-agent.** Orchestration lives in the main
  session — sub-agents cannot themselves dispatch further sub-agents
  on Claude Code.
- **Flat sub-agent dispatches only.** `dev-plan`, `red`, and `green`
  are leaf agents.
- **The main session owns flow control.** Sub-agent return is not
  workflow end. Continue through every phase until Phase 8.
- **One required approval gate** — Phase 2a. Phase 8 is the second
  user-interaction point.
- **Skill loading is not a substitute for sub-agent dispatch.** Do NOT
  load `anvil-red` / `anvil-green` skills in place of the Task-tool
  dispatch — sub-agents have isolated context and their agent prompts
  must execute faithfully.

## On completion

Report: commit subjects (test, feat/fix, optional refactor), files
modified, integration choice executed, and any SPIKE tickets created.
