---
description: Automated one-ticket TDD loop (flattened). Main session drives plan → RED → GREEN → optional REFACTOR → verification → integration-choice. Sub-agents dispatched flat, one at a time.
input:
  - ticket: "Ticket ID (e.g., MVP-001)"
---

# Anvil Develop — Orchestrated (Flattened)

You are the main session. You drive the full one-ticket TDD inner loop for
ticket `${input:ticket}`. Sub-agents (`dev-discipline`, `red`, `green`,
`sprint-syncer`) are dispatched **flat** — one at a time, from this main
session only. Never chain sub-agent dispatches through another sub-agent —
Claude Code does not support nested dispatch.

## Procedure

### Phase 0 — Prep

1. **Locate the ticket.** Search `docs/anvil/sprints/**/${input:ticket}*.md`.
   If not found, report and stop.
2. **Verify configuration.** Read `docs/anvil/config.yml`. Fail if missing.
3. **Read sprint context.** Read the sprint `README.md` containing the
   ticket.
4. **Verify branch.** If the current git branch does not match the sprint's
   Branch field, ask the user to switch first.
5. **Auto-create worktree.** Follow `worktree-discipline` instructions
   (from `anvil-common-stable`): create `.worktrees/${input:ticket}` on
   branch `feature/{sprint-slug}-${input:ticket}` (sprint-slug is the
   sprint branch with any leading `feature/` stripped). Add `.worktrees/`
   to `.gitignore` if needed. `cd` into the worktree.

### Phase 1 — Plan (flat sub-agent dispatch)

6. **Dispatch the `dev-discipline` sub-agent.** Use the Task tool with
   `subagent_type: "dev-discipline"` and a prompt such as
   `"Run the dev-discipline.agent workflow for ticket ${input:ticket}.
   Read the ticket, verify dependencies are Done, produce a RED/GREEN/
   REFACTOR plan surfacing any ambiguities, and stop after presenting
   the plan."` This is a flat dispatch from the main session.

7. **Relay the plan to the user for approval.** Present the sub-agent's
   plan output. Ask: *"Proceed with this plan?"* Wait for the user's
   response. If the user redirects, either re-dispatch `dev-discipline`
   with the clarification or stop.

### Phase 2 — RED (flat sub-agent dispatch)

8. **On approval, dispatch the `red` sub-agent.** Use the Task tool with
   `subagent_type: "red"` and a prompt such as
   `"Run the red.agent workflow for ticket ${input:ticket}. Read the
   ticket file, write the complete failing test suite covering all
   acceptance criteria (happy + edge per criterion), confirm tests fail
   for the right reason, and commit once."`

9. **Inspect the RED commit.** `git log -1 --format=%s` must start with
   `test(`. If the commit is missing or tests do not fail for the right
   reason, stop and report — do not proceed to GREEN.

### Phase 3 — GREEN (flat sub-agent dispatch)

10. **Dispatch the `green` sub-agent.** Use the Task tool with
    `subagent_type: "green"` and a prompt such as
    `"Run the green.agent workflow for ticket ${input:ticket}. Read the
    failing tests from the most recent test(...) commit, write minimum
    production code to pass the full suite, confirm tests pass, and
    commit once."`

11. **Inspect the GREEN commit.** `git log -1 --format=%s` must start with
    `feat(` or `fix(`. If the commit is missing or tests still fail, stop
    and report.

### Phase 4 — REFACTOR (inline, no sub-agent)

12. Read the GREEN commit's diff. Identify any code smells, duplication,
    or unclear names. If a refactor is warranted:
    - Make the changes inline in the current session (no sub-agent).
    - Run the component's `test_command` after each change to confirm all
      tests still pass.
    - Commit: `refactor({scope}): {description}`.
    If no refactor is warranted, skip to Phase 5 without committing.

### Phase 5 — Verify (inline)

13. Run every command in the ticket's Verification Steps section. If any
    fails, stop and report — do not apply the integration choice.

### Phase 6 — Close ticket (inline)

14. Update the ticket file: Status → Done, check satisfied acceptance
    criteria.
15. Update the sprint README's tickets table and status summary.

### Phase 7 — Integration choice (inline)

16. Present the five-option integration-choice matrix from
    `worktree-discipline`:
    - 1. Squash merge
    - 2. Merge
    - 3. Create PR
    - 4. Keep worktree
    - 5. Discard (requires explicit "yes" confirmation)

17. Execute the chosen option's git operations and cleanup per
    `worktree-discipline`.

## Constraints

- **No nested sub-agent dispatch.** All Task tool invocations happen from
  this main session. `dev-discipline`, `red`, and `green` are flat
  sub-agents; they do not themselves dispatch further sub-agents.
- **REFACTOR is inline.** There is no dedicated refactor sub-agent.
- **Verification is inline.** No sub-agent; just run the commands.
- **One approval gate.** The plan-approval at Phase 1 is the only
  required user interaction until the integration-choice at Phase 7.
- **Skill loading is not a substitute for sub-agent dispatch.** Do NOT
  load `anvil-red` / `anvil-green` / `anvil-develop` skills in place of
  the Task-tool dispatch — the sub-agents have their own isolated
  context and their agent prompts must execute faithfully.
- **Create SPIKEs for out-of-scope discoveries** per the `ticket-template`
  skill. Do not expand the current ticket's scope.

## On completion

Report:
- Commits created (test, feat/fix, optional refactor)
- Files modified
- Integration choice executed (squash / merge / PR / keep / discard)
- Whether any SPIKE tickets were created
