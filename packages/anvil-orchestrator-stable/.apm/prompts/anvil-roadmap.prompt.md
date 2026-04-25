---
description: Create or update ROADMAP.md via flat @pd dispatch, then optionally inline the sprint workflow for the current phase. No nested sub-agent dispatch.
input: []
---

# Anvil Roadmap — Orchestrated (Flattened)

You are the main session. Run the roadmap conversation via a flat `@pd`
sub-agent dispatch, then offer a single handoff: inline the sprint
workflow for the current phase, or stop. No nested sub-agent dispatch.

## Procedure

### Phase 0 — Check config

1. **Verify config.** Read `docs/anvil/config.yml`. If it doesn't exist,
   instruct the user to run `/anvil-init` first and stop.

### Phase 1 — Roadmap conversation (flat sub-agent dispatch)

2. **Check for existing ROADMAP.md.** Note whether this is a create or
   update.

3. **Dispatch the `pd` sub-agent.** Use the Task tool with
   `subagent_type: "pd"` and a prompt such as
   `"Run the pd.agent workflow. {Create | Update} ROADMAP.md at the
   project root through conversation with the user, using roadmap-format
   as the target structure. Pass existing ROADMAP.md contents if any."`
   Flat dispatch from the main session.

4. **Commit the roadmap.**
   - If new: `git commit -m "docs(roadmap): create project roadmap"`
   - If updated: `git commit -m "docs(roadmap): update roadmap phases"`

### Phase 2 — Report + handoff offer

5. **Identify the current phase.** The first phase in `ROADMAP.md` not
   marked `Complete`. Print its name and prefix.

6. **Offer the sprint handoff.** Ask:
   > *"Kick off a sprint for phase `<current-phase>` now?"*

### Phase 3 — Optional sprint handoff (inline, flattened)

7. **If yes:** inline the full workflow from
   `anvil-sprint.prompt.md` (orchestrator version, from this package) in
   your current context, with `phase = <current-phase>`. Any sub-agent
   dispatches in that workflow — `pm`, and transitively the develop
   workflow's `dev-plan` / `red` / `green` if the user also accepts
   sprint's one-ticket handoff — all happen from this same main session
   as flat dispatches.

   Stop after the inlined workflow completes.

8. **If no:** stop. Print the recommended next command:
   `/anvil-sprint <current-phase>`.

## Constraints

- **No nested sub-agent dispatch.** The `pd` dispatch in Phase 1 and any
  dispatches from the inlined sprint workflow all originate from this
  main session.
- **Single handoff only.** One roadmap conversation, one optional sprint
  kickoff. Do not chain further initiations.
- **Handoff is inline workflow execution**, not a sub-agent call.
- **Skill loading is not a substitute for sub-agent dispatch.** Do NOT
  load `anvil-roadmap` in place of the Task-tool `pd` dispatch.

## On completion

Report:
- What changed in `ROADMAP.md` (new phases, status updates, scope
  adjustments)
- Whether the sprint handoff ran (and its outcome if so)
- Next-step guidance
