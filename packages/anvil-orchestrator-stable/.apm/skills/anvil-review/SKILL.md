---
name: anvil-review
description: Sprint health + verification via flat @ba dispatch, then apply recommended cleanup with one all-or-nothing approval, then flat @sprint-syncer dispatch. Main session drives; no nested sub-agent dispatch.
user-invocable: true
---

# Anvil Review — Orchestrated (Flattened)

## Invocation

- Slash command: `/anvil-review <phase>`
- APM runtime: `apm run anvil-review --param phase=<phase>`

Run sprint health analysis, present recommendations with an all-or-nothing
approval gate, apply approved actions inline, then rebuild the sprint
README. The **main session** drives the flow; there is no orchestrator
sub-agent. Claude Code does not support nested sub-agent dispatch, so
this flattened design is required.

## Arguments

- `phase` (required) — the target sprint by phase name, version, or
  prefix

## Procedure

The main session executes the workflow documented in
`anvil-review.prompt.md` (orchestrator override, from this package).
Summary:

1. **Locate sprint (inline).**
2. **BA analysis (flat sub-agent):** Task tool with `subagent_type: "ba"`
   writes `BA-REPORT.md` with a "Recommended actions" section.
3. **Read and present recommendations (inline):** main session groups
   recommendations by action type (splits, archival, dependency healing,
   status corrections).
4. **Single approval gate (inline):** ask `"Apply all recommended
   actions? (y/N)"`.
5. **Apply (inline, on approval only):** main session edits ticket files
   directly using `ticket-template` and `sprint-readme-format` as
   structural references.
6. **Sync README (flat sub-agent, only if Phase 5 ran):** Task tool with
   `subagent_type: "sprint-syncer"` rebuilds the sprint README from the
   updated ticket files.
7. **If user declined at step 4:** print
   `BA-REPORT.md written; no actions applied.` and stop.

## Constraints

- **No orchestrator sub-agent.** The orchestration lives in the main
  session. This package formerly shipped a `review-orchestrator.agent.md`;
  that was removed because of Claude Code's no-nested-dispatch limit.
- **Flat sub-agent dispatches only.** Both `ba` and `sprint-syncer`
  dispatches originate from this main session, one after the other.
- **All-or-nothing approval.** No partial application in v2.0.0.
- **Never auto-downgrade a Done ticket.** If BA reports a Done ticket's
  verification failed, flag it loudly but do not change Status.
- **Apply phase is inline.** Main session edits files directly.
- **Skill loading is not a substitute for sub-agent dispatch.** Do NOT
  load `anvil-review` / `anvil-sync` in place of the Task-tool
  dispatches.

## On completion

Report:
- Path to the generated `BA-REPORT.md`
- Whether recommendations were applied (with a summary of what changed)
- Any verification failures that still need human attention
