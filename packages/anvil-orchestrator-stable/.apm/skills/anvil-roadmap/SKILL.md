---
name: anvil-roadmap
description: Run roadmap-orchestrator to create or update ROADMAP.md, then optionally hand off to sprint-orchestrator for the current phase.
user-invocable: true
---

# Anvil Roadmap — Orchestrated

## Invocation

- Slash command: `/anvil:roadmap`
- APM runtime: `apm run anvil:roadmap`
- Agent mention: `@roadmap-orchestrator`

Create or update `ROADMAP.md`, then optionally hand off to
`@sprint-orchestrator` for the current phase. This skill overrides the core
`anvil-roadmap` direct-`@pd` invocation; with `anvil-orchestrator-stable`
installed, the sprint-handoff gate is added at the end.

## Arguments

- None required. `@roadmap-orchestrator` conducts the conversation.

## Procedure

### 1. Invoke roadmap-orchestrator

Invoke the `@roadmap-orchestrator` agent. The agent follows its own
documented workflow (see `roadmap-orchestrator.agent.md`):

1. Invoke the `@pd` agent (from `anvil-core-stable`) to produce or update `ROADMAP.md` using `roadmap-format` (from `anvil-common-stable`)
2. Identify the "current" phase (first phase not marked Complete) and its prefix
3. Ask the user: *"Kick off a sprint for phase `<current-phase>` now?"*
4. If yes: inline-invoke the `@sprint-orchestrator` workflow for that phase
5. If no: stop and print `/anvil:sprint <current-phase>` as the recommended next command

### 2. Constraints

- **Do not invoke `@pd` directly from this skill.** `@roadmap-orchestrator` owns the roadmap + handoff flow.
- **Single handoff only.** One roadmap conversation, one optional sprint kickoff. Do not chain further.
- **Handoff is inline.** `@sprint-orchestrator` is invoked in the current context, not as a nested sub-agent dispatch.

### 3. On completion

Report:
- What changed in `ROADMAP.md` (new phases, status updates, scope adjustments)
- Whether the sprint handoff ran (and its outcome if so)
- Next-step guidance
