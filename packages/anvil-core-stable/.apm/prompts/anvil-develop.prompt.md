---
description: Plan implementation of a single sprint ticket. Locates ticket, verifies deps, auto-creates worktree, invokes dev-discipline for a plan, asks for approval, stops.
input:
  - ticket: "Ticket ID (e.g., MVP-001)"
---

# Anvil Develop — Plan Only

Plan the implementation of ticket `${input:ticket}`.

## Procedure

1. **Locate the ticket.** Search `docs/anvil/sprints/**/<ticket>*.md`. If not found, report the searched path and stop.
2. **Verify configuration.** Read `docs/anvil/config.yml`. If missing, report and stop.
3. **Read sprint context.** Read the sprint `README.md` containing the ticket.
4. **Verify branch.** Run `git rev-parse --abbrev-ref HEAD`. If the current branch does not match the sprint's `Branch:` field, stop with: "Current branch does not match the sprint branch. Switch to `<sprint-branch>` and re-run." Do not switch branches automatically.
5. **Auto-create worktree.** Follow `worktree-discipline` instructions (from `anvil-common-stable/.apm/instructions/worktree-discipline.instructions.md`):
   - **Sprint slug:** the sprint branch with any leading `feature/` stripped. Example: sprint branch `feature/sprint-42` → slug `sprint-42`.
   - **Worktree path:** `.worktrees/${input:ticket}`.
   - **Worktree branch:** `feature/<sprint-slug>-${input:ticket}`. Example: `feature/sprint-42-MVP-001`.
   - **`.gitignore`:** if `.worktrees/` is not already listed (`grep -q '^/\?\.worktrees/\?$' .gitignore`), append it.
   - `cd` into the worktree before step 6.
6. **Plan and approve.** Invoke the `dev-discipline.agent` to produce a RED/GREEN/REFACTOR plan for `${input:ticket}`. The agent ends with "Proceed with this plan?" — wait for the user's reply.
7. **On approval, report next steps and stop.** If the user does not approve (any reply other than `yes`/`proceed`/`approved`/`go`), stop without reporting next steps. On approval, emit:
   ```
   Plan approved. Run, in order:
     1. /anvil-red ${input:ticket}
     2. /anvil-green ${input:ticket}
     3. /anvil-refactor ${input:ticket}   (optional; skip if no refactor warranted)
   The final step (/anvil-refactor, or /anvil-green if refactor is skipped) will present the integration-choice matrix.
   ```

## Constraints

- Plan-and-approve only. Do not execute red/green/refactor in this prompt.
- Do not dispatch `@red` or `@green`. That is the orchestrator's job.
- Do not modify files outside step 5's `.gitignore` append and the worktree creation itself.
