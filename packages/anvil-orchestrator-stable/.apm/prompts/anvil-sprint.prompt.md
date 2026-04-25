---
description: Generate a sprint via flat @pm dispatch, then optionally run the flattened develop workflow for the first unblocked ticket. No multi-ticket loop.
input:
  - phase: "Phase name, number, or prefix"
---

# Anvil Sprint — Orchestrated (Flattened)

You are the main session. Generate a sprint for phase `${input:phase}` via
a flat `@pm` sub-agent dispatch, then offer a single handoff: run the
flattened develop workflow for the first unblocked ticket, or stop. No
nested sub-agent dispatch.

## Procedure

### Phase 0 — Prep

1. **Verify config.** Read `docs/anvil/config.yml`. If missing, instruct
   the user to run `/anvil-init` first and stop.
2. **Find target phase.** Read `ROADMAP.md`. Match `${input:phase}` against
   phase names, numbers, and prefixes. If ambiguous, ask.
3. **Check for existing sprint.** Look in `docs/anvil/sprints/` for a
   directory matching this phase. If one exists, ask whether to
   regenerate (which would overwrite tickets).
4. **Create sprint branch.** Read `git.branch_prefix` from config (default
   `feature/`). Run `git checkout -b {branch_prefix}phase-{slug}`.

### Phase 1 — Generate sprint (flat sub-agent dispatch)

5. **Dispatch the `pm` sub-agent.** Use the Task tool with
   `subagent_type: "pm"` and a prompt such as
   `"Run the pm.agent workflow for phase ${input:phase}. Read the target
   ROADMAP phase, explore the codebase, create granular tickets in
   docs/anvil/sprints/{slug}/, and write the sprint README following
   sprint-readme-format."` Flat dispatch from the main session.

6. **Commit the sprint artifacts.**
   ```
   git add docs/anvil/sprints/{directory}/
   git commit -m "chore(sprint): generate {phase-name} sprint tickets"
   ```

### Phase 2 — Report + handoff offer

7. **Report the result.** Print the sprint directory path, the count of
   tickets by type (main + SPIKE), and which tickets are immediately
   unblocked (no pending dependencies).

8. **Offer the one-ticket handoff.** Ask:
   > *"Develop `<first-unblocked-ticket-id>` now?"*

### Phase 3 — Optional develop handoff (inline, flattened)

9. **If yes:** inline the full workflow from
   `anvil-develop.prompt.md` (orchestrator version, from this package) in
   your current context, with `ticket = <first-unblocked-ticket-id>`. All
   sub-agent dispatches in that workflow — `dev-plan`, `red`,
   `green` — happen from this same main session as flat dispatches.

   Stop after the develop workflow completes (the integration-choice
   matrix is the last gate).

10. **If no:** stop. Print the recommended next command:
    `/anvil-develop <first-unblocked-ticket-id>`.

## Constraints

- **No nested sub-agent dispatch.** The `pm` dispatch in Phase 1 and any
  dispatches from the inlined develop workflow all originate from this
  main session.
- **One ticket only.** No multi-ticket loop. If the user asks for
  auto-develop-every-ticket, report that the feature is reserved for
  `anvil-autonomous-stable` (future package).
- **Handoff is inline workflow execution**, not a sub-agent call.
- **Skill loading is not a substitute for sub-agent dispatch.** Do NOT
  load `anvil-sprint` in place of the Task-tool `pm` dispatch.

## On completion

Report:
- Sprint directory path and ticket count by type
- Whether the one-ticket handoff ran (and its outcome if so)
- Next-step guidance
