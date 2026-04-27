---
description: Read-only status summary. No writes, no agent dispatch. Shows ticket counts, in-progress work, and blocked tickets.
input:
  - phase: "Optional phase filter — name, version, or prefix matched case-insensitively against sprint directory names"
---

# Anvil Status

Produce a read-only status summary as the final assistant message.

## Procedure

1. **Determine scope.**
   - If `${input:phase}` is provided, resolve it case-insensitively against directory names under `docs/anvil/sprints/`. Scope to `docs/anvil/sprints/<resolved-phase>/`. If no directory matches, report the unresolved phase and stop.
   - Otherwise, scope to every sprint directory under `docs/anvil/sprints/`.
2. **For each sprint in scope:**
   - Read the sprint `README.md`. If absent or unparseable, report that sprint as `status: unknown` and continue (do not fabricate counts).
   - Count tickets by `Status:` (`Open` / `In Progress` / `Done` / `Blocked`).
   - Collect tickets marked `In Progress` (ID + title).
   - Collect tickets marked `Blocked` (ID + title + their `Depends on:` field).
3. **Emit the summary** in the format below, then stop. Do not propose follow-up actions.

## Output Format

```
## Sprint Status

| Sprint | Open | In Progress | Done | Blocked |
| ------ | ---- | ----------- | ---- | ------- |
| <name> | <n>  | <n>         | <n>  | <n>     |

### In Progress
- [<TICKET-ID>] <title>

### Blocked
- [<TICKET-ID>] <title> (depends on: <comma-separated IDs>)
```

Omit the `In Progress` or `Blocked` section if it would be empty.

## Constraints

- Read-only. Issue no tool calls that create, modify, or delete files.
- No agent dispatch. This is a pure-data prompt.
