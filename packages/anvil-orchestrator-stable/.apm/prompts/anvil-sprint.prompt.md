---
description: Generate a sprint via flat @pm dispatch, then optionally run the flattened develop workflow for the first unblocked ticket. No multi-ticket loop.
input:
  - phase: "Phase name, number, or prefix"
---

# Anvil Sprint — Orchestrated

You are the main session. Generate a sprint for `${input:phase}` via a
flat `@pm` sub-agent dispatch, then offer one handoff: run the
flattened develop workflow for the first unblocked ticket, or stop.

## Definitions

- **Slug:** lowercase, hyphen-separated form of the phase name with
  non-alphanumeric characters collapsed to single hyphens and leading /
  trailing hyphens stripped (e.g. `Phase 2: Auth` → `phase-2-auth`).
- **Phase resolution precedence (case-insensitive):** exact name >
  phase number > prefix match. On a tie at the same precedence level,
  ask the user to disambiguate; do not guess.
- **Unblocked ticket:** a ticket whose `Depends on:` field is empty or
  whose listed dependencies are all `Status: Done`. When more than one
  is unblocked, sort by ticket-ID ascending and pick the first.
- **Inline workflow execution:** Read the named prompt file using the
  `Read` tool, then execute its numbered steps sequentially in this
  same main session context. Do NOT load it as a skill, do NOT
  dispatch it as a sub-agent.

## Execution Rules

- All sub-agent dispatches originate from this main session. No nested
  delegation.
- Skill loading is not a substitute for Task-tool dispatch. Do NOT load
  `anvil-sprint` in place of the `@pm` dispatch.
- One ticket only — no multi-ticket loop. Auto-develop-every-ticket is
  reserved for `anvil-autonomous-stable` (future package).

## Procedure

### Phase 0 — Prep

1. **Verify config.** Read `docs/anvil/config.yml`. If missing, halt
   with: `Config missing. Run /anvil-init first.`
2. **Find target phase.** Read `ROADMAP.md`. Match `${input:phase}`
   per the resolution precedence above. If no match, halt with:
   `No ROADMAP phase matches '${input:phase}'.` If ambiguous, list
   candidates and ask.
3. **Check for existing sprint.** Look in `docs/anvil/sprints/{slug}/`.
   If it exists, halt and ask:
   `Regenerate sprint? This will overwrite tickets in docs/anvil/sprints/{slug}/. (yes/no)`
   - `yes` → proceed (the `@pm` dispatch in Phase 1 overwrites).
   - anything else → stop and output:
     `Reusing existing sprint at docs/anvil/sprints/{slug}/. To create a new phase, use a different phase name.`
4. **Create sprint branch.** Read `git.branch_prefix` from config
   (default `feature/`). Run:

   ```bash
   git checkout -b {branch_prefix}phase-{slug}
   ```

### Phase 1 — Generate sprint (flat sub-agent dispatch)

5. **Dispatch the `pm` sub-agent.** Use the Task tool with
   `subagent_type: "pm"` using exactly this prompt template:

   ```text
   Run the pm.agent workflow for phase ${input:phase}. Read the target
   ROADMAP phase, explore the codebase, and create granular tickets in
   docs/anvil/sprints/{slug}/ following the sprint-readme-format and
   ticket-template skills (from anvil-common-stable).

   Return:
   1. The sprint directory path.
   2. Count of tickets by type (main vs SPIKE).
   3. List of unblocked ticket IDs in ascending sort order.
   ```

   Flat dispatch from this main session.

   **Success criterion:** the directory `docs/anvil/sprints/{slug}/`
   exists and contains at least one ticket file plus a `README.md`
   written per `sprint-readme-format`.

6. **Commit the sprint artifacts.** If the `@pm` dispatch failed, the
   directory is empty, or the `README.md` is missing, halt with:
   `Sprint generation failed. Sprint directory empty or README missing at docs/anvil/sprints/{slug}/.`
   Do not commit. Otherwise:

   ```bash
   git add docs/anvil/sprints/{slug}/
   git commit -m "chore(sprint): generate {slug} sprint tickets"
   ```

### Phase 2 — Report + handoff offer

7. **Report the result.** Output the sprint directory path, ticket
   count by type (main + SPIKE), and the unblocked ticket IDs in sort
   order.
8. **Offer the one-ticket handoff.**
   - If the unblocked list is empty, output:
     `No unblocked tickets in this sprint. Resolve dependencies before developing.`
     and stop.
   - Otherwise prompt:
     `Develop <first-unblocked-ticket-id> now? (yes/no)`

### Phase 3 — Optional develop handoff (inline)

9. **If yes:** Inline-execute
   `packages/anvil-orchestrator-stable/.apm/prompts/anvil-develop.prompt.md`
   with `${input:ticket} = <first-unblocked-ticket-id>`. Specifically:

   - Read that prompt file with the `Read` tool.
   - Execute every numbered step in this main session, sequentially.
   - All sub-agent dispatches inside (`dev-plan`, `red`, `green`)
     originate from this same main session as flat dispatches.
   - Stop after the integration-choice matrix is presented; do not
     auto-select any option, do not loop.

10. **If no:** Stop. Output:

    ```
    Recommended next command: /anvil-develop <first-unblocked-ticket-id>
    ```

## Completion report

Emit at workflow end using this template:

```
## Sprint complete — {slug}
- Sprint directory: docs/anvil/sprints/{slug}/
- Tickets created: {N main, M SPIKE}
- Unblocked: {comma-separated IDs, or "none"}
- One-ticket handoff: {ran (outcome) | declined | not offered}
- Next: {next-step guidance}
```
