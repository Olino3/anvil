---
description: Sprint health + verification. Runs BA analysis against a phase; reports cleanup recommendations without applying them.
input:
  - phase: "Phase name, version, or prefix matched case-insensitively against ROADMAP phase IDs and titles (e.g. MVP, 1.0.0, AUTH)"
---

# Anvil Review

Invoke the `@ba` agent for phase `${input:phase}`.

- **Phase resolution:** match `${input:phase}` case-insensitively against
  ROADMAP phase IDs and titles. If no phase matches, halt and ask the
  user to disambiguate.
- **Procedure:** follow the `anvil-review` skill.
- **Output structure:** the `ba-report-format` skill (from
  anvil-common-stable) is authoritative for `BA-REPORT.md`. Do not emit
  freeform output.
- **Output location:** write `BA-REPORT.md` into the sprint directory for
  the resolved phase (`docs/anvil/sprints/<phase>/BA-REPORT.md`).
- **Failure:** if the phase is unresolved or `@ba` cannot complete, report
  the blocker and stop without writing a partial `BA-REPORT.md`.

This prompt only **reports** cleanup recommendations. Do not apply them in
this run — no ticket edits, no archival, no status corrections. Applying
recommendations is a separate, user-approved action (run manually, or via
the orchestrator package's `review-orchestrator`).

Report the absolute path to the generated `BA-REPORT.md` as the final
assistant message.
