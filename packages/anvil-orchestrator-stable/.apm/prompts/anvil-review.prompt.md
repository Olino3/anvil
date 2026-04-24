---
description: Sprint health + verification + auto-apply cleanup actions with a single approval.
input:
  - phase: "Phase name, version, or prefix"
---

# Anvil Review — Orchestrated

Invoke the `@review-orchestrator` agent for phase `${input:phase}`.

Follow the workflow in `review-orchestrator.agent.md`. Honor the
all-or-nothing approval gate for applying cleanup actions.
