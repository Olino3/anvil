---
name: anvil-roadmap
description: Create or update ROADMAP.md via flat @pd dispatch, then optionally inline the sprint workflow for the current phase. Main session drives; no nested sub-agent dispatch.
user-invocable: true
---

# Anvil Roadmap — Orchestrated (Flattened)

## Invocation

- Slash command: `/anvil:roadmap`
- APM runtime: `apm run anvil:roadmap`

Create or update `ROADMAP.md`, then optionally inline the flattened sprint
workflow for the current phase. The **main session** drives the flow;
there is no orchestrator sub-agent. Claude Code does not support nested
sub-agent dispatch, so this flattened design is required.

## Arguments

- None required. The `@pd` sub-agent conducts the conversation.

## Procedure

The main session executes the workflow documented in
`anvil-roadmap.prompt.md` (orchestrator override, from this package).
Summary:

1. **Verify config (inline):** read `docs/anvil/config.yml`; if missing,
   prompt user to run `/anvil:init` first.
2. **Roadmap conversation (flat sub-agent):** Task tool with
   `subagent_type: "pd"` conducts the conversation and writes / updates
   `ROADMAP.md`.
3. **Commit roadmap (inline).**
4. **Identify current phase (inline):** the first phase not marked
   `Complete`.
5. **Handoff offer (inline):** ask `"Kick off a sprint for <current-phase>
   now?"`
6. **If yes:** inline the `anvil-sprint.prompt.md` workflow (orchestrator
   version) in the current main session, with `phase = <current-phase>`.
   Transitively, that workflow may inline the develop workflow too if the
   user accepts sprint's one-ticket handoff — all sub-agent dispatches
   originate from this same main session as flat dispatches.
7. **If no:** stop and print the next-step command.

## Constraints

- **No orchestrator sub-agent.** The orchestration lives in the main
  session. This package formerly shipped a `roadmap-orchestrator.agent.md`;
  that was removed because of Claude Code's no-nested-dispatch limit.
- **Flat sub-agent dispatches only.** `pd` dispatch in step 2, and any
  dispatches from inlined sprint / develop workflows, all originate from
  this main session.
- **Single handoff only.** One roadmap conversation, one optional sprint
  kickoff. Do not chain further initiations.
- **Handoff is inline workflow execution**, not a sub-agent call.

## On completion

Report:
- What changed in `ROADMAP.md` (new phases, status updates, scope
  adjustments)
- Whether the sprint handoff ran (and its outcome if so)
- Next-step guidance
