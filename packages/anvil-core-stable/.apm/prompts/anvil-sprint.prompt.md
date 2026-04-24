---
description: Break a ROADMAP phase into granular sprint tickets by invoking the Project Manager agent.
input:
  - phase: "Phase name, number, or prefix (e.g. MVP, 2, AUTH)"
---

# Anvil Sprint

Invoke the `@pm` agent to generate the sprint for phase `${input:phase}`.

Follow the `anvil-sprint` skill's procedure; use the `sprint-readme-format`
and `ticket-template` skills (from anvil-common-stable) for target structure.

At completion, inform the user the sprint directory was created and what the
first unblocked ticket is. Suggest: `/anvil:develop <ticket-id>`.
