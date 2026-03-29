---
name: sprint
description: Break a ROADMAP phase into a sprint with granular tickets by dispatching the pm-agent
user-invocable: true
---

# Anvil Sprint

Create a sprint from a ROADMAP phase.

## Arguments

- `phase` (required) — the target phase by name, number, or prefix (e.g., `MVP`, `2`, `Phase 2`, `Auth System`)

## Procedure

### 1. Verify Config

Read `docs/anvil/config.yml`. If it doesn't exist:
> "Anvil isn't configured for this project yet. Run `/anvil:init` first."

Stop and wait.

### 2. Find Target Phase

Read `ROADMAP.md` at the project root. If it doesn't exist:
> "No ROADMAP.md found. Run `/anvil:roadmap` first to create the project roadmap."

Stop and wait.

Match the user's argument against phase names, numbers, and prefixes. If ambiguous, ask for clarification.

### 3. Check for Existing Sprint

Look in `docs/anvil/sprints/` for a directory matching this phase. If one exists:
> "A sprint already exists for this phase at `docs/anvil/sprints/{dir}/`. Do you want to regenerate it (this will overwrite existing tickets)?"

Stop and wait.

### 4. Create Branch

Read `git.branch_prefix` from config (default: `feature/`). Create a feature branch:

```bash
git checkout -b {branch_prefix}phase-{slug}
```

Where `{slug}` is the phase name in lowercase kebab-case.

### 5. Dispatch pm-agent

Dispatch the `pm-agent` as a sub-agent with:
- The target phase details from ROADMAP.md (name, version, prefix, theme, goals, deliverables, avoid-deepening, notes)
- The contents of `docs/anvil/config.yml`
- The sprint directory path to create

The pm-agent will explore the codebase, create tickets, and write the sprint README.

### 6. Review Output

After the pm-agent completes, present to the user:
- Number of tickets created
- Dependency chain summary
- Sprint directory path

### 7. Commit

```bash
git add docs/anvil/sprints/{directory}/
git commit -m "chore(sprint): generate {phase-name} sprint tickets"
```
