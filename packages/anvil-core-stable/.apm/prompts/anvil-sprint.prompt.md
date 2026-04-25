---
description: Break a ROADMAP phase into granular sprint tickets by invoking the Project Manager agent.
input:
  - phase: "Phase name, number, or prefix matched case-insensitively against ROADMAP phase IDs and titles (e.g. MVP, 2, AUTH)"
---

# Anvil Sprint

Generate the sprint for phase `${input:phase}` via the Project Manager
agent (`@pm`).

- **Phase resolution:** match `${input:phase}` case-insensitively against
  ROADMAP phase IDs and titles. If no phase matches, halt and ask the user
  to disambiguate; do not guess.
- **Procedure:** follow the `anvil-sprint` skill.
- **Output structure (both required):** `sprint-readme-format` for the
  sprint directory's `README.md`; `ticket-template` for each ticket file.
  Both skills are in anvil-common-stable.
- **Failure:** if `@pm` does not return a sprint directory, report the
  blocker and stop. Do not re-invoke `@pm` after it returns.

At completion, report to the user the sprint directory path and the first
unblocked ticket ID (lowest-ID ticket whose `Depends on` field is empty or
fully satisfied). Suggest next step: `/anvil-develop <ticket-id>`.
