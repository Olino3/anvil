---
name: anvil-develop
description: Plan implementation of a single sprint ticket. Locates ticket, verifies dependencies, auto-creates a worktree, invokes dev-discipline for a plan, asks for approval, stops.
user-invocable: true
---

# Anvil Develop — Plan Only

## Invocation

- Slash command: `/anvil:develop <ticket-id>`
- APM runtime: `apm run anvil:develop --param ticket=<ticket-id>`

Plan implementation of a single sprint ticket. This skill stops after the plan is approved — it does not execute RED, GREEN, or REFACTOR. Those are separate user actions.

## Arguments

- `ticket-id` (required) — the ticket to plan (e.g., `MVP-001`, `AUTH-003`, `SPIKE-002`)

## Procedure

### 1. Locate Ticket

Search `docs/anvil/sprints/` for a file matching `{ticket-id}*.md`. If not found:
> "Could not find ticket `{ticket-id}` in any sprint directory under `docs/anvil/sprints/`."

If found in multiple sprints (unlikely but possible), ask the user which one.

### 2. Verify Config

Read `docs/anvil/config.yml`. The `dev-discipline` agent needs this for component context.

### 3. Read Sprint Context

Read the sprint's `README.md` to understand:
- Which branch to work on
- Dependency state of all tickets
- Current sprint progress

### 4. Verify Branch

Check that the current git branch matches the sprint's Branch field. If not:
> "You're on branch `{current}` but this sprint expects `{expected}`. Switch branches first?"

### 5. Create Worktree

Follow the `worktree-discipline` instructions (from `anvil-common-stable`) to create an isolated worktree. The branch scheme is:

```
feature/{sprint-slug}-{ticket-id}
```

where `{sprint-slug}` is the sprint branch with any leading `feature/` prefix stripped. Example: sprint branch `feature/mvp`, ticket `MVP-001` → worktree branch `feature/mvp-MVP-001`, worktree path `.worktrees/MVP-001`.

Ensure `.worktrees/` is in `.gitignore`. Change working directory into the worktree before Step 6.

### 6. Invoke dev-discipline agent

Invoke the `dev-discipline` agent to produce a plan. The agent:

1. Reads the ticket
2. Verifies all dependencies are Done; refuses to proceed otherwise
3. Produces a RED/GREEN/REFACTOR plan with any ticket-internal ambiguities surfaced
4. Asks the user: *"Proceed with this plan?"*
5. Stops after the user responds

No code or tests are written. No sub-agents are dispatched.

### 7. Report Next Steps

After the plan is approved, tell the user to run, in order:

1. `/anvil:red {ticket-id}` — whole-ticket failing test suite
2. `/anvil:green {ticket-id}` — whole-ticket minimum implementation
3. Optionally, `/anvil:refactor {ticket-id}` — clean up + integration-choice prompt

`/anvil:refactor` (or `/anvil:green` if the user decides no refactor is warranted) presents the integration-choice matrix from `worktree-discipline` at completion.

## Constraints

- **Do not dispatch `@red` or `@green` from this skill.** That is the orchestrator package's job. Core stops at a plan.
- **Do not modify code or tests.** Planning only.
