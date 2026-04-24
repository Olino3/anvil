---
description: Read-only status summary. No writes, no agent dispatch. Shows ticket counts, in-progress work, blocked tickets, recent activity.
input:
  - phase: "Optional phase filter"
---

# Anvil Status

Produce a read-only status summary.

## Procedure

1. If `${input:phase}` is provided, scope to that phase's sprint directory. Otherwise, summarize all sprints under `docs/anvil/sprints/`.
2. For each sprint in scope:
   - Read the sprint README
   - Count tickets by Status (Open / In Progress / Done / Blocked)
   - List any tickets marked In Progress
   - List any blocked tickets and what they depend on
3. Print the summary. Do not modify any files.

## Constraints

- Read-only. No writes under any circumstances.
- No agent dispatch. This is a pure-data prompt.
