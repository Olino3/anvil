---
description: Sprint health + verification. Runs BA analysis against a phase; reports cleanup recommendations without applying them.
input:
  - phase: "Phase name, version, or prefix (e.g. MVP, 1.0.0, AUTH)"
---

# Anvil Review

Invoke the `@ba` agent for phase `${input:phase}`.

Follow the `anvil-review` skill's procedure; produce a `BA-REPORT.md` using
the `ba-report-format` skill (from anvil-common-stable).

The BA agent only **reports** cleanup recommendations. Applying them
(ticket splits, archival, status corrections) is a separate action —
the user does it manually, or the orchestrator package's
`review-orchestrator` applies them with a single approval.

Report the path to the generated `BA-REPORT.md`.
