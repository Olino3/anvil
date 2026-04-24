---
name: anvil-status
description: Quick read-only sprint status summary — no file modifications
user-invocable: true
---

# Anvil Status

## Invocation

- Slash command: `/anvil:status [phase]`
- APM runtime: `apm run anvil:status` or `apm run anvil:status --param phase=<phase>`

Show a quick sprint status summary without modifying any files.

## Arguments

- `phase` (optional) — the target sprint by phase name, version, or prefix. If omitted, show status for all sprints.

## Procedure

### 1. Locate Sprint(s)

If a phase argument is provided, find the matching sprint directory. If not, list all directories under `docs/anvil/sprints/`.

If no sprints exist:
> "No sprints found under `docs/anvil/sprints/`. Run `/anvil:sprint <phase>` to create one."

### 2. Read Ticket Files

For each sprint, read all ticket `.md` files (excluding README.md and BA-REPORT.md). Extract:
- Ticket ID
- Title
- Status
- Component
- Dependencies

### 3. Compute Status

For each sprint, calculate:
- Ticket counts by status (Done, In Progress, Open, Blocked)
- Tickets that are blocked but whose blockers are all Done (can be unblocked)
- Overall progress percentage (Done / Total)

### 4. Output

Display a compact status table:

```
Sprint: MVP (v1.0.0)
Progress: 3/7 done (43%)

  Done:        MVP-001, MVP-003, SPIKE-001
  In Progress: MVP-004
  Open:        MVP-005, MVP-006
  Blocked:     MVP-002 (waiting on MVP-004)
  Unblockable: MVP-007 (blockers all Done)
```

**This is read-only.** No files are modified, no agents are dispatched.
