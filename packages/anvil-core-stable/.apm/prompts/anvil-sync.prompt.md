---
description: Rebuild a sprint README from its ticket files to fix drift. Read-only with respect to tickets; only the sprint README changes.
input:
  - phase: "Phase name, version, or prefix matched case-insensitively against ROADMAP phase IDs and titles"
---

# Anvil Sync

Invoke the `@sprint-syncer` agent for phase `${input:phase}`.

- **Phase resolution:** match `${input:phase}` case-insensitively against
  ROADMAP phase IDs and titles. If no phase matches, halt and ask the
  user to disambiguate; do not infer.
- **Procedure:** follow the `anvil-sync` skill.
- **Output structure:** the `sprint-readme-format` skill (from
  anvil-common-stable) is authoritative for the rebuilt `README.md`.
- **Write scope:** only the sprint `README.md` changes. Ticket files are
  read-only in this prompt.
- **Single pass:** do not re-invoke `@sprint-syncer` after it returns.

Report status changes as a bulleted list, one entry per affected ticket:

```
- <TICKET-ID>: <previous-status> -> <new-status>
```

If no statuses changed, report exactly: `No status changes.`
