---
name: anvil-develop
description: Automated one-ticket TDD loop (flattened). Main session drives plan → RED → GREEN → optional REFACTOR → verification → integration-choice. Sub-agents dispatched flat, one at a time.
user-invocable: true
---

# Anvil Develop — Orchestrated (Flattened)

## Invocation

- Slash command: `/anvil:develop <ticket-id>`
- APM runtime: `apm run anvil:develop --param ticket=<ticket-id>`

Run the full one-ticket TDD inner loop for a sprint ticket. The **main
session** drives the flow; there is no orchestrator sub-agent. Sub-agents
(`dev-discipline`, `red`, `green`, `sprint-syncer`) are dispatched flat —
one at a time, from the main session only. Claude Code does not support
nested sub-agent dispatch, so this flattened design is required.

## Arguments

- `ticket-id` (required) — the ticket to develop (e.g., `MVP-001`,
  `AUTH-003`, `SPIKE-002`)

## Procedure

The main session executes the workflow documented in
`anvil-develop.prompt.md` (orchestrator override, from this package).
Summary:

1. **Prep (inline):** locate ticket, verify config, read sprint context,
   verify branch, auto-create worktree per `worktree-discipline`.
2. **Plan (flat sub-agent):** Task tool with `subagent_type: "dev-discipline"`
   produces the RED/GREEN/REFACTOR plan. The main session relays the plan
   to the user for approval.
3. **RED (flat sub-agent):** on approval, Task tool with
   `subagent_type: "red"` writes the failing test suite and commits.
4. **GREEN (flat sub-agent):** Task tool with `subagent_type: "green"`
   writes minimum production code and commits.
5. **REFACTOR (inline):** main session does the cleanup directly if
   warranted; no sub-agent.
6. **Verify (inline):** main session runs the ticket's Verification
   Steps.
7. **Close (inline):** main session updates ticket Status → Done and
   rebuilds sprint README fields.
8. **Integration choice (inline):** main session presents the
   five-option matrix from `worktree-discipline` and executes the chosen
   option.

## Constraints

- **No orchestrator sub-agent.** The orchestration lives in the main
  session. This package formerly shipped a `develop-orchestrator.agent.md`;
  that was removed because sub-agents cannot themselves dispatch further
  sub-agents on Claude Code.
- **Flat sub-agent dispatches only.** All Task-tool calls originate from
  the main session. `dev-discipline`, `red`, `green`, and `sprint-syncer`
  are leaf agents — they do not dispatch further.
- **One approval gate.** Plan-approval is the only required user
  interaction until the integration-choice at the end.
- **Skill loading is not a substitute for sub-agent dispatch.** Do NOT
  load `anvil-red` / `anvil-green` skills in place of the Task-tool
  dispatch — the sub-agents have their own isolated context and their
  agent prompts must execute faithfully.

## On completion

Report:
- Commits created (test, feat/fix, optional refactor)
- Files modified
- Integration choice executed (squash / merge / PR / keep / discard)
- Whether any SPIKE tickets were created
