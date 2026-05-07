---
name: anvil-roadmap
description: Create or update ROADMAP.md by delegating strategic planning to the @pd agent
user-invocable: true
---

# Anvil Roadmap

**Goal:** delegate roadmap authoring to the `@pd` agent, then commit the
result. Do not author ROADMAP.md content directly.

## Invocation

- Slash command: `/anvil-roadmap`
- APM runtime: `apm run anvil-roadmap`
- Agent mention: `@pd`

## Schema reference

`ROADMAP.md` MUST conform to the `roadmap-format` skill (from
`anvil-common-stable`). The `@pd` agent owns the content; this skill orchestrates.

## Procedure

### 1. Verify config

Use **Read** on `docs/anvil/config.yml`. If it does not exist, output
verbatim:

> Anvil isn't configured for this project yet. Run `/anvil-init` first.

Halt. Do not continue.

### 2. Determine operation

Use **Bash** `test -f ROADMAP.md` (or **Read**) at the project root.

- File present → `operation = update`; **Read** the existing contents.
- File absent → `operation = create`; existing contents are `null`.

### 3. Invoke @pd

The `Task` tool with `subagent_type=pd` is required.

- If available → invoke `@pd`.
- If unavailable → halt and output verbatim:

  > `@pd` is not available in this host. The `anvil-roadmap` skill requires
  > Task-based subagent dispatch. Run the host with subagent support, or
  > invoke the `@pd` agent file directly.

  Do **not** re-enter the `anvil-roadmap` skill (e.g., via `apm run
  anvil-roadmap`) as a fallback — that would recurse indefinitely.

Pass the following payload to the agent:

- `config` — full contents of `docs/anvil/config.yml`.
- `existing_roadmap` — contents of `ROADMAP.md`, or `null`.
- `operation` — `create` or `update`.

The agent owns all user-facing dialogue and writes/updates `ROADMAP.md`.
Block until it returns. If invocation fails, report the error and
halt — do not write `ROADMAP.md` directly.

### 4. Verify and commit

1. Use **Bash** `git diff --name-only` to confirm `ROADMAP.md` was modified
   (or is newly tracked).
2. If unchanged, output `No roadmap changes to commit.` and skip to Step 5.
3. Otherwise stage and commit:

   - On `create`:
     ```bash
     git add ROADMAP.md
     git commit -m "docs(roadmap): create project roadmap"
     ```
   - On `update`:
     ```bash
     git add ROADMAP.md
     git commit -m "docs(roadmap): update roadmap phases"
     ```

### 5. Completion contract

Emit as the final assistant message:

`ROADMAP.md <created|updated|unchanged>. Next: /anvil-sprint <phase>.`

Then stop.

## Failure modes

Halt and report — do not produce a partial roadmap or empty commit:

- `docs/anvil/config.yml` missing (Step 1).
- `@pd` invocation unavailable or failed (Step 3).
- Agent returned with `ROADMAP.md` absent or empty.
- Git commit failed (rerun guidance: check `git status`, retry).
