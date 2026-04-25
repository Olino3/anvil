---
name: anvil-sprint
description: Break a ROADMAP phase into a sprint of granular tickets via the @pm agent
user-invocable: true
---

# Anvil Sprint

**Goal:** delegate ticket generation for one ROADMAP phase to the `@pm`
agent, on a dedicated feature branch, then commit the result.

## Invocation

- Slash command: `/anvil-sprint <phase>`
- APM runtime: `apm run anvil-sprint --param phase=<phase>`
- Agent mention: `@pm <phase>`

## Arguments

- `phase` (required, string) — ROADMAP phase identifier. Matched as
  described in Step 2. Example values: `MVP`, `2`, `Phase 2`, `Auth System`.

## Schema reference

Sprint output (tickets + README) MUST conform to:

- `ticket-template` (from `anvil-common-stable`) for individual tickets.
- `sprint-readme-format` (from `anvil-common-stable`) for the sprint README.

The `@pm` agent owns the content; this skill orchestrates.

## Procedure

### 1. Verify config

Use **Read** on `docs/anvil/config.yml`. If absent, output verbatim:

> Anvil isn't configured for this project yet. Run `/anvil-init` first.

Halt.

### 2. Find the target phase

Use **Read** on `ROADMAP.md`. If absent, output verbatim:

> No ROADMAP.md found. Run `/anvil-roadmap` first.

Halt.

Match `<phase>` against ROADMAP entries with this precedence (case-insensitive):

1. **Exact name** match (e.g., `Auth System`).
2. **Phase number** match (e.g., `2`, `Phase 2`).
3. **Prefix** match against the phase name (e.g., `Auth` → `Auth System`).

If multiple entries tie at the same precedence level, halt and ask the user
to disambiguate. Do not guess.

### 3. Check for an existing sprint

Use **Glob** in `docs/anvil/sprints/` for a directory whose name matches the
phase slug. If one exists, halt and output verbatim:

> Sprint already exists at `docs/anvil/sprints/{dir}/`. Re-run with explicit
> regenerate intent to overwrite.

Do not regenerate without explicit user approval in the same turn.

### 4. Create branch

Read `git.branch_prefix` from config (default `feature/`). Build the slug:

- Lowercase the phase name.
- Replace any run of whitespace or punctuation with a single hyphen.
- Strip leading/trailing hyphens.

Then run, via **Bash**:

```bash
git checkout -b {branch_prefix}phase-{slug}
```

Example: phase `Auth System` → slug `auth-system` → branch
`feature/phase-auth-system`.

### 5. Invoke @pm

Pick the invocation path by host capability:

- If the `Task` tool with `subagent_type=pm` is available → invoke `@pm`.
- Otherwise → run `apm run anvil-sprint --param phase=<phase>` via **Bash**.

Pass the following payload to the agent:

- `phase` — the matched ROADMAP entry, with these fields: name, version,
  prefix, theme, goals, deliverables, avoid_deepening, notes.
- `config` — full contents of `docs/anvil/config.yml`.
- `sprint_dir` — `docs/anvil/sprints/{slug}/` (the directory to create).

The agent explores the codebase, writes ticket files, and writes the sprint
`README.md`. Block until it returns. If invocation fails, report and halt;
do not invent tickets.

### 6. Verify and report

After `@pm` returns:

1. Use **Glob** to count `.md` files in `docs/anvil/sprints/{slug}/` excluding
   `README.md`.
2. Use **Read** on the sprint `README.md` to extract the dependency-chain
   summary.
3. If ticket count is `0` or `README.md` is missing, halt with an error.
   Do not retry.

Output to the user:

- Number of tickets created.
- Dependency chain summary.
- Sprint directory path.

### 7. Commit

```bash
git add docs/anvil/sprints/{slug}/
git commit -m "chore(sprint): generate {slug} sprint tickets"
```

Use the same `{slug}` from Step 4.

### 8. Completion contract

Emit as the final assistant message:

`Sprint {slug} created with N tickets on branch {branch}. Next: /anvil-develop <ticket-id>.`

Then stop.

## Failure modes

Halt and report — do not produce partial output:

- Config or ROADMAP missing (Steps 1, 2).
- Phase match is ambiguous and user has not disambiguated (Step 2).
- Sprint directory already exists (Step 3).
- Branch checkout failed (Step 4).
- `@pm` agent unavailable, errored, or produced zero tickets (Steps 5, 6).
- Git commit failed (Step 7).
