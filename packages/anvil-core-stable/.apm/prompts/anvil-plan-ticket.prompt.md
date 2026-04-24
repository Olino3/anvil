---
description: Produce a RED/GREEN/REFACTOR plan for a sprint ticket without touching code or the worktree. Standalone re-use of dev-discipline.
input:
  - ticket: "Ticket ID (e.g., MVP-001)"
---

# Anvil Plan Ticket

Invoke `dev-discipline.agent` to produce a plan for ticket `${input:ticket}`.

Do not create a worktree, do not modify any files. Plan only.

At completion, ask the user: *"Proceed with this plan?"* Stop after the
response.
