---
name: anvil-sprint
description: Generate a sprint via flat @pm dispatch, then optionally run the flattened develop workflow for the first unblocked ticket. Main session drives; no nested sub-agent dispatch.
user-invocable: true
---

# Anvil Sprint — Orchestrated (Flattened)

## Invocation

- Slash command: `/anvil-sprint <phase>`
- APM runtime: `apm run anvil-sprint --param phase=<phase>`

Generate a sprint from a ROADMAP phase, then optionally inline the
flattened develop workflow for the first unblocked ticket. The **main
session** drives the flow; there is no orchestrator sub-agent. Claude
Code does not support nested sub-agent dispatch, so this flattened design
is required.

## Arguments

- `phase` (required) — the target phase by name, number, or prefix
  (e.g., `MVP`, `2`, `Phase 2`, `Auth System`)

## Procedure

The main session executes the workflow documented in
`anvil-sprint.prompt.md` (orchestrator override, from this package).
Summary:

1. **Prep (inline):** verify config, find target phase in `ROADMAP.md`,
   check for existing sprint, create sprint feature branch.
2. **Generate sprint (flat sub-agent):** Task tool with
   `subagent_type: "pm"` creates the sprint directory, ticket files, and
   sprint README.
3. **Commit sprint artifacts (inline).**
4. **Report (inline):** main session prints sprint path, ticket counts,
   first unblocked ticket.
5. **Handoff offer (inline):** ask `"Develop <first-unblocked-ticket>
   now?"`
6. **If yes:** inline the `anvil-develop.prompt.md` workflow (orchestrator
   version) in the current main session, with `ticket =
   <first-unblocked-ticket>`. All sub-agent dispatches from that inlined
   workflow — `dev-plan`, `red`, `green` — originate from this same
   main session as flat dispatches.
7. **If no:** stop and print the next-step command.

## Constraints

- **No orchestrator sub-agent.** The orchestration lives in the main
  session. This package formerly shipped a `sprint-orchestrator.agent.md`;
  that was removed because of Claude Code's no-nested-dispatch limit.
- **Flat sub-agent dispatches only.** `pm` dispatch in step 2, and any
  dispatches from the inlined develop workflow, all originate from this
  main session.
- **One ticket only.** No multi-ticket loop. If the user asks for
  auto-develop-every-ticket, report that the feature is reserved for
  `anvil-autonomous-stable` (future package).
- **Handoff is inline workflow execution**, not a sub-agent call.

## On completion

Report:
- Sprint directory path and ticket count by type
- Whether the one-ticket handoff ran (and its outcome if so)
- Next-step guidance
