---
description: Automated one-ticket TDD loop (flattened). Main session drives plan → RED → GREEN → optional REFACTOR → verification → integration-choice. Sub-agents dispatched flat, one at a time.
input:
  - ticket: "Ticket ID (e.g., MVP-001)"
---

# Anvil Develop — Orchestrated (Flattened)

You are the main session. Drive the full one-ticket TDD inner loop for
ticket `${input:ticket}`. Sub-agents (`dev-plan`, `red`, `green`) are
dispatched **flat** — one at a time, from this main session only. Never
chain sub-agent dispatches through another sub-agent (Claude Code does
not support nested dispatch). The main session owns the single approval
gate (after the plan) and continues automatically through every later
phase until the integration-choice matrix.

## Procedure

### Phase 0 — Prep

1. **Locate the ticket.** Search `docs/anvil/sprints/**/${input:ticket}*.md`.
   - 0 matches → halt with: `Ticket ${input:ticket} not found under docs/anvil/sprints/.`
   - 2+ matches → list candidates and ask the user to disambiguate.
2. **Verify configuration.** Read `docs/anvil/config.yml`. If missing,
   halt with: `Config missing. Run /anvil-init first.`
3. **Read sprint context.** Read the sprint `README.md` containing the
   ticket.
4. **Verify branch.** If the current git branch does not match the
   sprint's Branch field, output:
   `Current branch is {current}. This ticket requires {required}. Switch and re-run.`
   then halt.
5. **Auto-create worktree.** Follow `worktree-discipline` instructions
   (load the `worktree-discipline` skill from
   `anvil-common-stable/.apm/instructions/worktree-discipline.instructions.md`).
   - Worktree path: `.worktrees/${input:ticket}`.
   - Worktree branch: `feature/{sprint-slug}-${input:ticket}`, where
     `sprint-slug` is the sprint branch with any leading `feature/`
     stripped.
   - Add `.worktrees/` to `.gitignore` if needed.
   - `cd` into the worktree.
   - Reuse rules: matching branch → reuse; mismatched branch → halt
     with conflict message.

### Phase 1 — Plan (flat sub-agent dispatch)

6. **Dispatch the `dev-plan` sub-agent.** Use the Task tool with
   `subagent_type: "dev-plan"` using exactly this prompt template:

   ```text
   Produce a RED/GREEN/REFACTOR plan for ticket ${input:ticket}.
   Read the ticket file, verify dependencies are Done, and return the
   plan as structured markdown using the Standard Plan Template (or the
   Blocked Plan Template if any dependency is not Done). Do not ask the
   user anything and do not suggest next commands — the orchestrator
   main session owns the approval gate and flow control.
   ```

   Flat dispatch from this main session.

   **Important:** Do NOT dispatch `dev-discipline` — that is core's
   plan-and-stop agent and it closes the interaction. `dev-plan` is the
   leaf plan-return agent that hands the plan back without taking flow
   control.

7. **Present the plan and own the approval gate.** Take the plan
   returned by `dev-plan` and present it to the user. Ask: *"Proceed
   with this plan?"*

   Handle the user's response:

   - **`yes` / `y` / `proceed` / `approve` (case-insensitive)** →
     continue to Phase 2 (RED).
   - **`needs changes: {guidance}`** → re-dispatch `dev-plan` using this
     prompt template:

     ```text
     Produce a revised plan for ticket ${input:ticket}. Previous plan
     summary: {summary}. User-requested changes: {guidance}. Re-plan
     accordingly using the Standard Plan Template.
     ```

     Present the revised plan and re-ask for approval. **Loop guard:**
     after 3 revision cycles without approval, surface the impasse and
     ask the user whether to stop or keep iterating. Do not loop
     silently.
   - **`stop` / `cancel` / anything else** → halt the workflow without
     reporting next steps. Wait for the next user instruction.

   `dev-plan` returning is **not** the end of the workflow. Only
   explicit user approval advances to Phase 2; only the
   integration-choice at Phase 7 ends the workflow.

### Phase 2 — RED (flat sub-agent dispatch)

8. **Dispatch the `red` sub-agent.** Use the Task tool with
   `subagent_type: "red"` using exactly this prompt template:

   ```text
   Run the red.agent workflow for ticket ${input:ticket}. Read the
   ticket file, write the complete failing test suite covering all
   acceptance criteria (happy + edge per criterion), confirm tests fail
   for the right reason, and commit once.
   ```

9. **Inspect the RED commit.** First confirm `pwd` ends with
   `.worktrees/${input:ticket}`. Then run `git log -1 --format=%s`. The
   subject MUST start with `test(`. If not, halt with:

   ```
   HALT: Phase 2 (RED). Expected commit subject prefix: test(.
   Actual: {actual subject}. Evidence: git log -1 --format=%s.
   Workflow halted; do not proceed to GREEN.
   ```

### Phase 3 — GREEN (flat sub-agent dispatch)

10. **Dispatch the `green` sub-agent.** Use the Task tool with
    `subagent_type: "green"` using exactly this prompt template:

    ```text
    Run the green.agent workflow for ticket ${input:ticket}. Read the
    failing tests from the most recent test(...) commit, write minimum
    production code to pass the full suite, confirm tests pass, and
    commit once.
    ```

11. **Inspect the GREEN commit.** Confirm `pwd` ends with
    `.worktrees/${input:ticket}`, then run `git log -1 --format=%s`.
    The subject MUST start with `feat(` or `fix(`. If not, halt with:

    ```
    HALT: Phase 3 (GREEN). Expected commit subject prefix: feat( or fix(.
    Actual: {actual subject}. Workflow halted.
    ```

### Phase 4 — REFACTOR (inline, no sub-agent)

12. Read the GREEN commit's diff. Refactor only when the diff
    introduces at least one of:
    - duplicated logic spanning 3+ lines,
    - a function exceeding ~20 lines that has more than one
      responsibility,
    - an unclear name that a reader would not understand without
      context, or
    - a leaky abstraction (concretes leaking through an interface).

    If any apply: make changes inline (no sub-agent), run the
    component's `test_command` after each change, and revert
    immediately if any test fails. Commit:
    `refactor({scope}): {description}`.

    If none apply, emit `No refactor needed. Proceeding to Phase 5.`
    and skip to Phase 5 without committing.

### Phase 5 — Verify (inline)

13. Run every command in the ticket's `Verification Steps` section. If
    any command exits non-zero, halt with:

    ```
    HALT: Phase 5 (Verify). Failed step: {name}. Last output:
    {tail of stderr/stdout}. Workflow halted; integration choice not applied.
    ```

    If the ticket has no `Verification Steps` section, emit
    `No verification steps defined; skipping Phase 5.` and continue.

### Phase 6 — Close ticket (inline)

14. Update the ticket file: `Status` → `Done`; check satisfied
    acceptance criteria.
15. Update the sprint README's tickets table and status summary.

### Phase 7 — Integration choice (inline)

16. Present the five-option integration-choice matrix from
    `worktree-discipline`:
    1. Squash merge
    2. Merge
    3. Create PR
    4. Keep worktree
    5. Discard (requires explicit `yes` confirmation)

17. Execute the chosen option's git operations and cleanup per
    `worktree-discipline`. The integration-choice gate is the only
    workflow exit besides explicit halt.

## Constraints

- **No nested sub-agent dispatch.** All Task tool invocations originate
  from this main session. `dev-plan`, `red`, and `green` are flat leaf
  sub-agents.
- **The main session owns flow control.** A leaf sub-agent returning is
  not a workflow end — only explicit halt or Phase 7 ends the workflow.
- **Never use `dev-discipline` here.** That is core's plan-and-stop
  agent. The orchestrator's plan phase uses `dev-plan`, which returns
  without stopping.
- **REFACTOR and Verify are inline.** No sub-agents.
- **One required approval gate** — Phase 1. Phase 7 is the second
  user-interaction point.
- **Skill loading is not a substitute for sub-agent dispatch.** Do NOT
  load `anvil-red` / `anvil-green` / `anvil-develop` skills in place of
  the Task-tool dispatch — sub-agents have isolated context and their
  agent prompts must execute faithfully.
- **Create SPIKEs for out-of-scope discoveries** per `ticket-template`.
  Do not expand the current ticket's scope.

## Completion report

Emit at workflow end (after Phase 7) using this template:

```
## Develop complete — ${input:ticket}
- Commits: {test, feat|fix, optional refactor — list with subjects}
- Files modified: {count} ({comma-separated paths})
- Integration choice executed: {squash | merge | PR | keep | discard}
- SPIKE tickets created: {none | comma-separated IDs}
```
