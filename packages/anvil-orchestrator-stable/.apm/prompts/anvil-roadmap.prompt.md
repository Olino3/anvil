---
description: Create or update ROADMAP.md via flat @pd dispatch, then optionally inline the sprint workflow for the current roadmap phase. No nested sub-agent dispatch.
input: []
---

# Anvil Roadmap — Orchestrated

You are the main session. Run the roadmap conversation via a flat `@pd`
sub-agent dispatch, then offer one handoff: inline the orchestrator
sprint workflow for the current phase, or stop.

> **Naming convention.** "Stage" refers to a step of THIS workflow
> (Stage 0–3). "Phase" refers to a roadmap phase inside `ROADMAP.md`
> (Phase 1, Phase 2, …). Do not conflate them.

## Execution Rules

- All sub-agent dispatches originate from this main session. No nested
  delegation.
- Skill loading is not a substitute for Task-tool dispatch. Do NOT load
  `anvil-roadmap` in place of the `@pd` dispatch.
- The inlined sprint workflow runs synchronously in this session;
  suppress any further roadmap or handoff offers it contains.
- One roadmap conversation, one optional sprint kickoff per run.

## Procedure

### Stage 0 — Check config

1. **Verify config.** Read `docs/anvil/config.yml`. If missing, halt
   with: `Config missing. Run /anvil-init first.`

### Stage 1 — Roadmap conversation (flat sub-agent dispatch)

2. **Determine operation.** If `ROADMAP.md` exists at the project root,
   set `operation = update` and capture its contents. Otherwise set
   `operation = create`.

3. **Dispatch the `pd` sub-agent.** Use the platform Task tool with
   `subagent_type: "pd"` using exactly this prompt template:

   ```text
   Run the pd.agent workflow. Operation: {operation}. Use roadmap-format
   (from anvil-common-stable) as the target structure for ROADMAP.md at
   the project root. If operation is update, the existing ROADMAP.md
   contents follow this prompt; preserve unchecked deliverables unless
   the user explicitly requests removal.
   ```

   Expected return: confirmation that `ROADMAP.md` was written, or an
   explicit error.

   **Failure paths:**
   - If `@pd` returns an error or no output → halt. Report the failure
     to the user and do not write `ROADMAP.md` directly. Do not
     re-invoke `@pd`.
   - If `ROADMAP.md` exists but `git diff --name-only` shows no changes
     after `@pd` returns → skip the commit, output `No changes
     detected.` and continue to Stage 2.

4. **Commit the roadmap.**
   - On `create`: `git commit -m "docs(roadmap): create project roadmap"`
   - On `update`: `git commit -m "docs(roadmap): update roadmap phases"`

### Stage 2 — Report + handoff offer

5. **Identify the current roadmap phase.** Scan `ROADMAP.md` for the
   first `## Phase N` heading whose body does not contain a `Status:
   Complete` line.

   - If all phases are `Status: Complete`, output `All roadmap phases
     are Complete.` and stop. Do not offer the sprint handoff.
   - Otherwise capture `<current-phase>` (the matching phase name and
     prefix) and continue.

6. **Prompt the user with this exact question:**

   ```
   Kick off a sprint for phase <current-phase> now? (yes/no)
   ```

### Stage 3 — Optional sprint handoff (inline)

7. **If yes:** Inline the full workflow from
   `packages/anvil-orchestrator-stable/.apm/prompts/anvil-sprint.prompt.md`
   in this session, with `${input:phase} = <current-phase>`. All
   sub-agent dispatches inside that workflow run flat from this same
   main session:

   - The `pm` dispatch originates here.
   - If the user accepts the sprint's one-ticket handoff, the
     `dev-plan`, `red`, and `green` dispatches also originate here.

   When inlining the sprint workflow, suppress any further handoff
   offers it contains. Stop after the inlined workflow completes.

8. **If no:** Stop. Output:

   ```
   Recommended next command: /anvil-sprint <current-phase>
   ```

## Completion report

Emit at workflow end using this template:

```
## Roadmap complete
- ROADMAP.md: {created | updated | unchanged}
- Phases changed: {comma-separated names, or "none"}
- Sprint handoff: {ran (with outcome summary) | declined | not offered}
- Next: {next-step guidance}
```
