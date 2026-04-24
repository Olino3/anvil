---
description: Rebuild a sprint README from its ticket files to fix drift. Read-only with respect to tickets; only the sprint README changes.
input:
  - phase: "Phase name, version, or prefix"
---

# Anvil Sync

Invoke the `@sprint-syncer` agent for phase `${input:phase}`.

Follow `anvil-sync` skill procedure. Use `sprint-readme-format` (from
anvil-common-stable) for the target structure.

Report which ticket statuses changed in the rebuild (if any).
