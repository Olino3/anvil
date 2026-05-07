---
description: Sprint health + verification via flat @ba dispatch, then apply recommended cleanup with one all-or-nothing approval, then flat @sprint-syncer dispatch. No nested sub-agent dispatch.
input:
  - phase: "Phase name, version, or prefix"
---

# Anvil Review — Orchestrated

You are the main session. Run sprint health analysis via a flat `@ba`
sub-agent dispatch, present the recommendations with an all-or-nothing
approval gate, apply approved actions inline, then rebuild the sprint
README via a flat `@sprint-syncer` dispatch.

## Execution Rules

- All sub-agent dispatches originate from this main session. No nested
  delegation.
- Skill loading is not a substitute for Task-tool dispatch. Do NOT load
  `anvil-review` or `anvil-sync` in place of the dispatches.
- All-or-nothing approval. The user approves the full recommendation
  set, or none of it. No partial application in v2.0.0.
- Never auto-downgrade a `Status: Done` ticket. If `@ba` reports a Done
  ticket whose verification failed, surface it in the completion
  report under "Verification failures requiring human attention" — do
  not change Status.
- The Apply stage is inline. The main session edits files directly; no
  sub-agent.

## Procedure

### Phase 0 — Locate sprint

1. **Locate sprint.** Search `docs/anvil/sprints/` for a directory
   matching `${input:phase}` per the resolution precedence: exact name
   > version prefix > slug prefix (case-insensitive). On a tie, list
   candidates and ask. On zero matches, output the available sprint
   list and halt.

### Phase 1 — BA analysis (flat sub-agent dispatch)

2. **Dispatch the `ba` sub-agent.** Use the Task tool with
   `subagent_type: "ba"` using exactly this prompt template:

   ```text
   Run the ba.agent workflow for phase ${input:phase}. Read the sprint
   directory, verify Done tickets, check ROADMAP coverage, validate
   dependencies, and write BA-REPORT.md in the sprint directory ending
   with a "## Recommended actions" heading.
   ```

   If `BA-REPORT.md` already exists in the sprint directory, the
   dispatch overwrites it.

### Phase 2 — Present recommendations

3. **Read `BA-REPORT.md`.** Locate the literal heading
   `## Recommended actions` and parse its contents.

4. **Failure path.** If `BA-REPORT.md` is missing, has no
   `## Recommended actions` heading, or the section is empty, halt
   with:

   ```
   BA dispatch produced no actionable report. BA-REPORT.md missing
   or "## Recommended actions" section absent/empty. Inspect the BA
   sub-agent output before re-running.
   ```

5. **Present the recommendations to the user**, grouped by action type.
   Pin the literal headings:

   - **Ticket splits** (e.g., `X` → `X.1`, `X.2` because criteria
     count exceeded 8)
   - **Archival** (tickets superseded or cut from scope)
   - **Dependency healing** (missing `Blocks:` ↔ `Depends on:` pairs)
   - **Status corrections** (Done tickets whose verification failed,
     etc.)

   Use this presentation shape:

   ```
   ### Ticket splits
   | Parent | New IDs | Reason |
   | --- | --- | --- |
   | ... | ... | ... |

   ### Archival
   - {ticket-id}: {one-line reason}

   ### Dependency healing
   - {ticket-A} ↔ {ticket-B}: {one-line reason}

   ### Status corrections
   - {ticket-id}: {issue} (BA recommendation only — never inferred)
   ```

   Empty groups: print the heading and the literal `None.` line.

### Phase 3 — Single approval gate

6. **Prompt the user with this exact question:**
   `Apply all recommended actions? (y/N)`

   - `y` / `yes` (case-insensitive) → continue to Phase 4.
   - anything else → continue to Phase 3b.

### Phase 3b — User declined

7. Output: `BA-REPORT.md written; no actions applied.` Suggest the
   user review the report and either apply actions manually or
   re-invoke `/anvil-review` later. Skip Phases 4–5 and go to the
   completion report.

### Phase 4 — Apply (inline, on approval only)

8. Apply every action yourself in this main session (file edits, no
   sub-agent). Use `ticket-template` and `sprint-readme-format` (load
   from `anvil-common-stable`) for any file modifications. Apply in
   this order to keep dependencies consistent:

   - **8a. Splits.** For each split, copy the parent's Objective,
     Acceptance Criteria, and Context into new ticket files; number
     sequentially (`X.1`, `X.2`, …); update the master count.
   - **8b. Archival.** Rename `ARCHIVED-{PREFIX}-{NNN}-{slug}.md`.
   - **8c. Dependency healing.** Add missing `Blocks:` /
     `Depends on:` pairs. If a circular dependency would result,
     skip that pair and record it under "Verification failures
     requiring human attention".
   - **8d. Status corrections.** Apply only where `BA-REPORT.md`
     explicitly recommends. Never auto-downgrade a Done ticket.

   **Abort rule.** If any individual action fails or produces a
   conflict, halt the Apply stage. Do not proceed to subsequent
   actions or Phase 5. Report the failed action and the changes
   already committed.

### Phase 5 — Sync README (flat sub-agent dispatch)

9. Dispatch `@sprint-syncer` if and only if Phase 4 ran AND at least
   one file under `docs/anvil/sprints/{phase-directory}/` was modified
   (verify with `git status --porcelain`). Use the Task tool with
   `subagent_type: "sprint-syncer"` using exactly this prompt
   template:

   ```text
   Run the sprint-syncer.agent workflow for phase ${input:phase}. Read
   all ticket files in the sprint directory and rebuild the sprint
   README's tickets table, dependency graph, and status summary. Derive
   status from the ticket files only — do not infer from prior README
   state.
   ```

   If no files were modified, skip this phase and emit:
   `No files modified in Apply stage; skipping sprint-syncer.`

## Completion report

Emit at workflow end using this template:

```
## Review complete — ${input:phase}
- BA report: {path to BA-REPORT.md}
- Approval: {applied | declined}
- Actions applied: {none | comma-separated by category, e.g. "2 splits, 1 archival"}
- Files modified: {count} ({comma-separated paths, or "none"})
- Sprint README rebuilt: {yes | no | not applicable}
- Verification failures requiring human attention: {none | comma-separated ticket IDs with one-line reasons}
```
