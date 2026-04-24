---
description: Plan implementation of a single sprint ticket. Locates ticket, verifies deps, auto-creates worktree, invokes dev-discipline for a plan, asks for approval, stops.
input:
  - ticket: "Ticket ID (e.g., MVP-001)"
---

# Anvil Develop — Plan Only

Plan the implementation of ticket `${input:ticket}`.

## Procedure

1. **Locate the ticket.** Search `docs/anvil/sprints/**/<ticket>*.md`. If not found, report and stop.
2. **Verify configuration.** Read `docs/anvil/config.yml`. Fail if missing.
3. **Read sprint context.** Read the sprint `README.md` containing the ticket.
4. **Verify branch.** If the current git branch does not match the sprint's Branch field, ask the user to switch first.
5. **Auto-create worktree.** Follow `worktree-discipline` instructions (from anvil-common-stable): create `.worktrees/${input:ticket}` on branch `feature/{sprint-slug}-${input:ticket}` (where sprint-slug is the sprint branch with any leading `feature/` stripped). Add `.worktrees/` to `.gitignore` if needed. `cd` into the worktree.
6. **Invoke `dev-discipline.agent`** to produce a plan for the ticket and ask for approval. Stop after approval.
7. **Report next steps.** Tell the user to run, in order: `/anvil:red ${input:ticket}`, `/anvil:green ${input:ticket}`, then optionally `/anvil:refactor ${input:ticket}`. `/anvil:refactor` (or `/anvil:green` if no refactor warranted) will present the integration-choice matrix at completion.

## Constraints

- Do not proceed past Step 6. The user runs red/green/refactor separately.
- Do not dispatch `@red` or `@green` here. That is orchestrator's job.
