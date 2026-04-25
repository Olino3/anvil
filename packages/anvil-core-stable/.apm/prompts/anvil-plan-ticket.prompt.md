---
description: Produce a RED/GREEN/REFACTOR plan for a sprint ticket without touching code or the worktree. Standalone re-use of dev-discipline.
input:
  - ticket: "Ticket ID (e.g., MVP-001)"
---

# Anvil Plan Ticket

Invoke the `dev-discipline.agent` to produce a RED/GREEN/REFACTOR plan for
ticket `${input:ticket}`. The agent owns the plan's shape, halt
conditions, and approval prompt — do not paraphrase or override them.

If `${input:ticket}` is missing, malformed, or cannot be located, request
clarification and stop. Do not fabricate a plan.

Plan only. Do not create or enter a worktree, do not modify files, do not
dispatch sub-agents (`@red`, `@green`, etc.), and do not invoke other
slash commands.

The agent ends by asking the user "Proceed with this plan?". Stop after
that line is emitted; wait for the next user turn before doing anything
further.
