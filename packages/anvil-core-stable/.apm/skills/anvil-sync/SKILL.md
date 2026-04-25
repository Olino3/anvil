---
name: anvil-sync
description: Reconcile a sprint README status table with the actual ticket-file metadata via the @sprint-syncer agent
user-invocable: true
---

# Anvil Sync

**Goal:** delegate sprint-README/ticket reconciliation to the
`@sprint-syncer` agent and surface its sync report. This skill writes files
through the agent (not directly).

## Invocation

- Slash command: `/anvil-sync <phase>`
- APM runtime: `apm run anvil-sync --param phase=<phase>`
- Agent mention: `@sprint-syncer <phase>`

## Arguments

- `phase` (required, string) — sprint identifier matched against directory
  names under `docs/anvil/sprints/`. See Step 1 for matching rules.

## Schema reference

Sprint README output MUST conform to the `sprint-readme-format` skill
(from `anvil-common-stable`). Ticket files MUST conform to `ticket-template`.
The `@sprint-syncer` agent owns the reconciliation; this skill orchestrates.

## Procedure

### 1. Locate sprint

Use **Glob** on `docs/anvil/sprints/*` and match `<phase>` against directory
names with this precedence (case-insensitive):

1. **Exact** directory name.
2. **Version prefix**.
3. **Slug prefix**.

If multiple directories tie at the same precedence level, halt and output
verbatim:

> No unique sprint for `{phase}`. Candidates: {list}. Disambiguate.

If zero match, halt and output:

> No sprint found for `{phase}`. Available sprints: {list of directory names}.

### 2. Invoke @sprint-syncer

Pick the invocation path by host capability — do not guess:

- If the `Task` tool with `subagent_type=sprint-syncer` is available →
  invoke `@sprint-syncer`.
- Otherwise → run `apm run anvil-sync --param phase=<phase>` via **Bash**.

Pass the following payload:

- `sprint_dir` — directory path from Step 1.

The agent reads ticket files, rebuilds the README status tables, fixes
bidirectional dependency references, and returns a structured sync report.
Block until it returns. Do not retry on partial output. Do not invoke this
skill from inside a `sprint-syncer` subagent context (loop guard).

### 3. Present sync report

The `@sprint-syncer` report MUST contain these fields. If any are missing,
halt with an error.

- `phase` — sprint identifier.
- `status_changes` — list of README status row updates (empty list if none).
- `dependency_fixes` — list of ticket-file dependency edits (empty list if
  none).
- `sprint_progress` — string in the form `N/M done (P%)`.
- `errors` — list of recoverable issues encountered (empty list if none).

Surface every field, in order, to the user. Do not suppress empty lists —
report them as `None.` literals so the user sees the full state.

### 4. Completion contract

Emit as the final assistant message:

`Sync complete for {sprint_dir}. {N} status changes, {M} dependency fixes. Progress: P%.`

Then stop.

## Constraints

- **Mutating skill.** This invocation writes files (via the agent) without a
  per-change confirmation gate. If you need a preview, run `/anvil-status`
  first.
- **No direct README authoring.** All edits are made by `@sprint-syncer`.

## Failure modes

Halt and report — do not write directly:

- Phase did not match exactly one sprint (Step 1).
- `@sprint-syncer` invocation unavailable or errored (Step 2).
- Sync report is missing required fields (Step 3).
