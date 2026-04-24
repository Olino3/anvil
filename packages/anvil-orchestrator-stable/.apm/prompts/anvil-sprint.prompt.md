---
description: Generate a sprint for a ROADMAP phase and optionally hand off to develop-orchestrator for the first unblocked ticket.
input:
  - phase: "Phase name, number, or prefix"
---

# Anvil Sprint — Orchestrated

Invoke the `@sprint-orchestrator` agent for phase `${input:phase}`.

Follow the workflow in `sprint-orchestrator.agent.md`. Honor the
one-ticket-handoff approval gate.

No multi-ticket loop. If the user wants auto-develop-every-ticket, report
that the feature is reserved for anvil-autonomous-stable.
