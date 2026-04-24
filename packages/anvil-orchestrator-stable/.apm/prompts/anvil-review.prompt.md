---
description: Sprint health + verification via flat @ba dispatch, then apply recommended cleanup with one all-or-nothing approval, then flat @sprint-syncer dispatch. No nested sub-agent dispatch.
input:
  - phase: "Phase name, version, or prefix"
---

# Anvil Review — Orchestrated (Flattened)

You are the main session. Run sprint health analysis via a flat `@ba`
sub-agent dispatch, present recommendations with an all-or-nothing
approval gate, apply approved actions inline, then rebuild the sprint
README via a flat `@sprint-syncer` dispatch. No nested sub-agent dispatch.

## Procedure

### Phase 0 — Locate sprint

1. **Locate sprint.** Search `docs/anvil/sprints/` for a directory matching
   `${input:phase}`. If not found, print the available sprint list and
   stop.

### Phase 1 — BA analysis (flat sub-agent dispatch)

2. **Dispatch the `ba` sub-agent.** Use the Task tool with
   `subagent_type: "ba"` and a prompt such as
   `"Run the ba.agent workflow for phase ${input:phase}. Read the sprint
   directory, verify Done tickets, check ROADMAP coverage, validate
   dependencies, and write BA-REPORT.md in the sprint directory ending
   with a 'Recommended actions' section."` Flat dispatch from the main
   session.

### Phase 2 — Present recommendations

3. **Read `BA-REPORT.md`.** Parse the "Recommended actions" section.

4. **Present the recommendations to the user**, grouped by action type:
   - Ticket splits (ticket X → X.1, X.2 because criteria count exceeded 8)
   - Archival (tickets superseded or cut from scope)
   - Dependency healing (missing `Blocks:` ↔ `Depends on:` pairs)
   - Status corrections (Done tickets whose verification failed, etc.)

### Phase 3 — Single approval gate

5. Ask:
   > *"Apply all recommended actions? (y/N)"*

### Phase 4 — Apply (inline, on approval only)

6. **If approved:** apply every action yourself in the current main
   session (these are file edits, not a sub-agent task). Use
   `ticket-template` and `sprint-readme-format` (from
   `anvil-common-stable`) for any file modifications. Apply in this
   order to keep dependencies consistent:
   1. Splits (create new ticket files, copy context, update numbers)
   2. Archival (rename `ARCHIVED-{PREFIX}-{NNN}-{slug}.md`)
   3. Dependency healing (add missing `Blocks:` / `Depends on:` pairs)
   4. Status corrections (only where BA-REPORT explicitly recommends —
      never auto-downgrade a Done ticket)

### Phase 5 — Sync README (flat sub-agent dispatch)

7. **Only if Phase 4 ran**, dispatch the `sprint-syncer` sub-agent to
   rebuild the sprint README from the updated ticket files. Use the Task
   tool with `subagent_type: "sprint-syncer"` and a prompt such as
   `"Run the sprint-syncer.agent workflow for phase ${input:phase}. Read
   all ticket files in the sprint directory and rebuild the sprint
   README's tickets table, dependency graph, and status summary."` Flat
   dispatch from the main session.

### Phase 6 — If user declined

8. Print: `BA-REPORT.md written; no actions applied.` Suggest the user
   review the report and either apply actions manually or re-invoke
   `/anvil:review` later.

## Constraints

- **No nested sub-agent dispatch.** Both `ba` and `sprint-syncer`
  dispatches originate from this main session, one after the other.
- **All-or-nothing approval.** The user approves the full recommendation
  set, or none of it. No partial application in v2.0.0.
- **Never auto-downgrade a Done ticket.** If BA reports a Done ticket's
  verification failed, flag it loudly but do not change Status.
- **Apply phase is inline.** No sub-agent; the main session edits files
  directly.
- **Skill loading is not a substitute for sub-agent dispatch.** Do NOT
  load `anvil-review` or `anvil-sync` in place of the Task-tool
  dispatches.

## On completion

Report:
- Path to the generated `BA-REPORT.md`
- Whether recommendations were applied (with a summary of what changed)
- Any verification failures that still need human attention
