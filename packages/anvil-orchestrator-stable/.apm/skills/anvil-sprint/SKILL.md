---
name: anvil-sprint
description: Generate a sprint via sprint-orchestrator, then offer a one-ticket handoff to develop-orchestrator for the first unblocked ticket. No multi-ticket loop.
user-invocable: true
---

# Anvil Sprint — Orchestrated

## Invocation

- Slash command: `/anvil:sprint <phase>`
- APM runtime: `apm run anvil:sprint --param phase=<phase>`
- Agent mention: `@sprint-orchestrator <phase>`

Generate a sprint from a ROADMAP phase, then optionally hand off to
`@develop-orchestrator` for the first unblocked ticket. This skill overrides
the core `anvil-sprint` direct-`@pm` invocation; with
`anvil-orchestrator-stable` installed, the one-ticket handoff gate is added
at the end.

## Arguments

- `phase` (required) — the target phase by name, number, or prefix (e.g., `MVP`, `2`, `Phase 2`, `Auth System`)

## Procedure

### 1. Invoke sprint-orchestrator

Invoke the `@sprint-orchestrator` agent for the phase. The agent follows its
own documented workflow (see `sprint-orchestrator.agent.md`):

1. Invoke the `@pm` agent (from `anvil-core-stable`) to generate the sprint — sprint directory, ticket files, sprint README, and the sprint feature branch
2. Report the sprint directory path, ticket counts, and which tickets are immediately unblocked
3. Ask the user: *"Develop `<first-unblocked-ticket-id>` now?"*
4. If yes: inline-invoke the `@develop-orchestrator` workflow for that ticket
5. If no: stop and print `/anvil:develop <first-unblocked-ticket-id>` as the recommended next command

### 2. Constraints

- **Do not invoke `@pm` directly from this skill.** `@sprint-orchestrator` owns the sprint generation + handoff flow.
- **One-ticket handoff only.** No multi-ticket loop. If the user asks for auto-develop-every-ticket, report that the feature is reserved for `anvil-autonomous-stable` (future package).
- **Handoff is inline.** `@develop-orchestrator` is invoked in the current context, not as a nested sub-agent dispatch.

### 3. On completion

Report:
- Sprint directory path and ticket count by type
- Whether the one-ticket handoff ran (and its outcome if so)
- Next-step guidance
