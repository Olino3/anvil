---
name: anvil-develop
description: Automated one-ticket TDD loop. Locates ticket, auto-worktree, plan, approval, RED → GREEN → optional REFACTOR → verification → integration choice via develop-orchestrator.
user-invocable: true
---

# Anvil Develop — Orchestrated

## Invocation

- Slash command: `/anvil:develop <ticket-id>`
- APM runtime: `apm run anvil:develop --param ticket=<ticket-id>`
- Agent mention: `@develop-orchestrator <ticket-id>`

Run the full one-ticket TDD inner loop for a sprint ticket. This skill
overrides the core `anvil-develop` plan-and-stop behavior; with
`anvil-orchestrator-stable` installed, the single approval gate is the plan,
after which RED → GREEN → optional REFACTOR → verification → integration
choice all run automatically.

## Arguments

- `ticket-id` (required) — the ticket to develop (e.g., `MVP-001`, `AUTH-003`, `SPIKE-002`)

## Procedure

### 1. Invoke develop-orchestrator

Invoke the `@develop-orchestrator` agent for the ticket. The agent follows
its own documented workflow (see `develop-orchestrator.agent.md`):

- Phase 0: locate ticket, verify config, read sprint context, verify branch, auto-create worktree per `worktree-discipline`
- Phase 1: produce a plan and ask the user *"Proceed with this plan?"*
- Phase 2: on approval, dispatch `@red` (from `anvil-core-stable`), then `@green`, optionally inline `/anvil:refactor`
- Phase 3: run the ticket's Verification Steps
- Phase 4: update ticket Status → Done; update sprint README
- Phase 5: present the five-option integration-choice matrix and execute the choice

### 2. Constraints

- **Do not invoke `dev-discipline` directly from this skill.** That is core's plan-and-stop behavior. Orchestrator runs the full loop through `@develop-orchestrator`.
- **Do not inline RED/GREEN logic here.** `@develop-orchestrator` dispatches `@red` and `@green` as sub-agents and handles fallback (inline) automatically on hosts that cannot dispatch.

### 3. On completion

Report:
- Commits created (test, feat/fix, optional refactor)
- Files modified
- Integration choice executed (squash / merge / PR / keep / discard)
- Whether any SPIKE tickets were created
