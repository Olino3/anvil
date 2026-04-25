---
name: anvil-roadmap
description: Use when starting roadmap-driven phase planning in an Anvil project. Creates or updates ROADMAP.md via @pd, then optionally inlines the sprint workflow for the current roadmap phase. All sub-agent dispatch from the main session.
user-invocable: true
---

# Anvil Roadmap — Flattened (Main-Session Driven)

## Invocation

- Slash command: `/anvil-roadmap`
- APM runtime: `apm run anvil-roadmap`

## Arguments

- None. The `@pd` sub-agent conducts the conversation with the user.

## Glossary

- **`@pd` dispatch.** A Task-tool call with `subagent_type: "pd"` to
  the Product Director leaf agent.
- **Flat dispatch.** A Task-tool call originating from the current
  main session (not nested inside another sub-agent).
- **Roadmap phase.** A milestone block inside `ROADMAP.md` (Phase 1,
  Phase 2, …). The orchestrator workflow's own internal stages are
  numbered Stage 0–3 in `anvil-roadmap.prompt.md` to avoid collision
  with these.

## Authoritative source

The executable workflow is `anvil-roadmap.prompt.md` (orchestrator
override, this package). This skill summarizes role and boundaries
only — read the prompt for full step-by-step procedure.

## Stages

The main session runs the workflow flat from itself.

| # | Stage | Owner | Notes |
|---|---|---|---|
| 1 | Verify config | main session | **Read** `docs/anvil/config.yml`. If absent, halt and emit `Config missing. Run /anvil-init first.` Do not proceed. |
| 2 | Roadmap conversation | `@pd` (Task) | Writes / updates `ROADMAP.md` via conversation with the user. |
| 3 | Commit | main session | `git commit -m "docs(roadmap): create project roadmap"` (new) or `... update roadmap phases"` (update). Skip the commit if `git diff --name-only` shows no changes. |
| 4 | Identify current phase | main session | First `## Phase N` heading in `ROADMAP.md` whose body lacks `Status: Complete`. If all phases are Complete, emit `All roadmap phases are Complete.` and stop without offering the handoff. |
| 5 | Handoff offer | main session | Prompt the user with the literal string: `Kick off a sprint for <current-phase> now? (yes/no)` Accept only `yes` / `y` (case-insensitive). |
| 6a | If yes | main session (inline) | Inline-execute `anvil-sprint.prompt.md` (orchestrator version, this package) with `${input:phase} = <current-phase>`. |
| 6b | If no | main session | Stop. Output the recommended next command: `/anvil-sprint <current-phase>`. |
| 6c | Inline failure handling | main session | If the inlined sprint workflow halts or the user cancels, surface the failure and stop. Do not retry. |

## Sub-agent dispatch shape

```
Task(subagent_type="pd", prompt="<pd template from prompt file>")
```

The exact prompt template lives in `anvil-roadmap.prompt.md`; pass it
verbatim. If `@pd` returns an error or no output, halt — do NOT write
`ROADMAP.md` directly.

## Constraints

- **No orchestrator sub-agent.** Orchestration lives in the main
  session — sub-agents cannot themselves dispatch further sub-agents
  on Claude Code.
- **Flat sub-agent dispatches only.** The `@pd` dispatch in Stage 2,
  and any dispatches from the inlined sprint / develop workflows, all
  originate from this same main session.
- **Single handoff only.** One roadmap conversation, one optional
  sprint kickoff per run. When inlining the sprint workflow, suppress
  any further handoff offers it contains.
- **Handoff is inline workflow execution**, not a sub-agent call.

## On completion

Output three sections:

```
### ROADMAP.md changes
- {created | updated | unchanged}
- Phases changed: {comma-separated names, or "none"}

### Sprint handoff
- {ran (with outcome summary) | declined | not offered (all phases Complete)}

### Next steps
- {next-step guidance}
```
