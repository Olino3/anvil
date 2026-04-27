---
name: anvil-develop
description: Plan a single sprint ticket — locate it, verify dependencies, create a worktree, ask dev-discipline for a plan, halt for approval
user-invocable: true
---

# Anvil Develop — Plan Only

**Goal:** produce an approved RED/GREEN/REFACTOR plan for one ticket and
stop. This skill never writes code or tests, and never dispatches `@red` or
`@green`.

## Invocation

- Slash command: `/anvil-develop <ticket-id>`
- APM runtime: `apm run anvil-develop --param ticket=<ticket-id>`

## Arguments

- `ticket-id` (required, string) — sprint ticket identifier (matches a
  filename prefix under `docs/anvil/sprints/`).

## Procedure

### 1. Locate ticket

Use **Glob** with pattern `docs/anvil/sprints/**/{ticket-id}*.md`.

- 0 matches → output verbatim: `Could not find ticket {ticket-id} under docs/anvil/sprints/.` Halt.
- 1 match → continue with that file.
- 2+ matches → list matches and ask the user to disambiguate. Restart at
  Step 1 with the clarified ID.

### 2. Verify config

Use **Read** on `docs/anvil/config.yml`. If absent, halt and tell the user
to run `/anvil-init`.

### 3. Read sprint context

Use **Read** on the sprint's `README.md` (sibling of the ticket file) to
extract:

- The sprint's expected git branch.
- Each ticket's status (used in Step 6 by dev-discipline).

### 4. Verify branch

Use **Bash** `git rev-parse --abbrev-ref HEAD`. Compare against the sprint's
expected branch.

- Match → continue.
- Mismatch → output verbatim: `On branch {current}, sprint expects {expected}. Switch first.` Halt.

### 5. Create worktree

Follow the `worktree-discipline` instructions (from
`anvil-common-stable/.apm/instructions/`). Branch and path scheme:

- Sprint branch: strip a leading `feature/` if present.
- Worktree branch: `feature/{sprint-slug}-{ticket-id}`.
- Worktree path: `.worktrees/{ticket-id}`.

Example: sprint branch `feature/mvp`, ticket `MVP-001` → worktree branch
`feature/mvp-MVP-001` at path `.worktrees/MVP-001`.

Ensure `.worktrees/` is in `.gitignore`. Change working directory into the
worktree before Step 6. Verify postconditions: the worktree path exists and
the worktree branch is checked out.

Reuse rules:

- Worktree exists with the correct branch → reuse it.
- Worktree exists with a different branch → halt with a conflict message;
  do not move it.

### 6. Invoke dev-discipline

Invoke the `dev-discipline` agent. Pass these inputs (so the agent does not
re-read them):

- `ticket_path` — path to the ticket file from Step 1.
- `config_path` — `docs/anvil/config.yml`.
- `sprint_readme_path` — path to the sprint README from Step 3.

Postcondition: the agent returns a structured RED/GREEN/REFACTOR plan and
halts pending user approval. No code or tests are written. No sub-agents
are dispatched.

### 7. Approval gate

Halt for the user's response to the agent's `Proceed with this plan?` prompt.

- Accept only `yes`, `y`, `proceed`, or `approve` (case-insensitive) as
  approval.
- Anything else → reply `I need explicit approval (yes / proceed). Plan
  unchanged.` and halt.

### 8. Completion contract

After approval, emit as the final assistant message, exactly:

```
Plan approved for {ticket-id} on {worktree-branch}. Next, in order:
1. /anvil-red {ticket-id}
2. /anvil-green {ticket-id}
3. /anvil-refactor {ticket-id}   (optional)
```

Then stop. Do not invoke `/anvil-red`, `/anvil-green`, or any other skill.

## Constraints

- **Plan only.** No code, no tests, no sub-agent dispatch beyond
  `dev-discipline`.
- **Stop at the contract.** Integration choices are presented by
  `/anvil-refactor` (or `/anvil-green` if no refactor is warranted),
  per `worktree-discipline` — not here.

## Failure modes

Halt and report — do not silently retry:

- Ticket not found (Step 1).
- Config missing (Step 2).
- Sprint README missing or unreadable (Step 3).
- Branch mismatch the user does not resolve (Step 4).
- Worktree conflict (Step 5).
- `dev-discipline` agent unavailable or returned without a plan (Step 6).
- User did not give explicit approval (Step 7).
