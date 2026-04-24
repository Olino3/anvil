---
description: Automated one-ticket TDD loop. Locate ticket, auto-worktree, plan, approval, RED → GREEN → optional REFACTOR → verification → integration choice.
input:
  - ticket: "Ticket ID (e.g., MVP-001)"
---

# Anvil Develop — Orchestrated

Invoke the `@develop-orchestrator` agent for ticket `${input:ticket}`.

Follow the workflow in `develop-orchestrator.agent.md`. Honor the approval
gates documented in the `orchestration-gates` skill.

On completion, report: commits created, files modified, integration choice
executed, and whether any SPIKE tickets were created.
