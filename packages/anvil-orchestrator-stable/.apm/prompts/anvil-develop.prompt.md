---
description: Automated one-ticket TDD loop (flattened). Main session drives plan → RED → GREEN → optional REFACTOR → verification → integration-choice. Sub-agents dispatched flat, one at a time.
input:
  - ticket: "Ticket ID (e.g., MVP-001)"
---

# Anvil Develop — Orchestrated (Flattened)

You are the main session. You drive the full one-ticket TDD inner loop for
ticket `${input:ticket}`. Sub-agents (`dev-plan`, `red`, `green`) are
dispatched **flat** — one at a time, from this main session only. Never
chain sub-agent dispatches through another sub-agent — Claude Code does
not support nested dispatch.

The main session owns the approval gate. Leaf sub-agents produce
artifacts and return; they do not stop the workflow on their own. It is
the main session's responsibility to continue from sub-agent to sub-agent
until the workflow reaches the integration choice.

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

6. **Dispatch the `dev-plan` sub-agent.** Use the Task tool with
   `subagent_type: "dev-plan"` and a prompt such as
   `"Produce a RED/GREEN/REFACTOR plan for ticket ${input:ticket}. Read
   the ticket file, verify dependencies are Done, and return the plan as
   structured markdown. Do not ask the user anything and do not suggest
   next commands — the orchestrator main session owns the approval gate
   and flow control."` This is a flat dispatch from the main session.

   **Important:** Do NOT dispatch `dev-discipline` — that is core's
   plan-and-stop agent and it closes the interaction. `dev-plan` is a
   plan-return leaf agent that hands the plan back without taking flow
   control.

7. **Present the plan and own the approval gate.** You (the main
   session) take the plan returned by `dev-plan` and present it to the
   user. Ask: *"Proceed with this plan?"*

   Handle the user's response:
   - **"Proceed" / "yes" / approval**: continue to Phase 2 (RED).
   - **"Needs changes: {guidance}"**: re-dispatch `dev-plan` with the
     user's redirection as additional context in the prompt (e.g.
     `"Produce a revised plan for ticket ${input:ticket}. Previous plan
     returned {summary}; user requested these changes: {guidance}. Re-plan
     accordingly."`). Present the revised plan and re-ask for approval.
     Loop until the user approves or stops.
   - **"Stop" / "cancel"**: stop the workflow. Do not proceed.

   Do NOT stop the workflow just because `dev-plan` returned. `dev-plan`
   is a leaf agent that produces a plan and exits; the main session must
   explicitly continue to Phase 2 on approval.

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
  this main session. `dev-plan`, `red`, and `green` are flat leaf
  sub-agents; they do not themselves dispatch further sub-agents.
- **The main session owns flow control.** When a leaf sub-agent returns,
  the main session decides what to do next. Do not interpret a
  sub-agent's "done" signal as the end of the workflow — only the
  integration-choice at Phase 7 ends the workflow.
- **Never use `dev-discipline` in this workflow.** That is core's
  plan-and-stop agent (package: `anvil-core-stable`). With
  `anvil-orchestrator-stable` installed, the plan phase uses `dev-plan`,
  which returns the plan without stopping the workflow.
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
