---
name: ba-report-format
description: Load before producing or reading `docs/anvil/sprints/*/BA-REPORT.md` sprint health reports.
user-invocable: false
---

# BA Report Format

Reference file for ba-agent. Defines the canonical format for sprint health reports.

## Location

`docs/anvil/sprints/{sprint-directory}/BA-REPORT.md`

The report is written inside the sprint directory it analyzes.

## Template

```markdown
# BA Report — {Phase Name} ({vX.Y.Z})

**Date:** {YYYY-MM-DD}
**Phase:** {N} — {Theme}
**Sprint:** docs/anvil/sprints/{sprint-directory}/

---

## Status Distribution

| Status | Count | Tickets |
|---|---|---|
| Done | {N} | {PREFIX}-001, {PREFIX}-002, {PREFIX}-003 |
| In Progress | {N} | {PREFIX}-004, {PREFIX}-005 |
| Open | {N} | {PREFIX}-006 |
| Blocked | {N} | — |

**Total:** {N} tickets

---

## Verification Results

| Ticket | Status | Verification | Issues |
|---|---|---|---|
| {PREFIX}-001 | Done | PASS | — |
| {PREFIX}-002 | Done | FAIL | {Command X failed: error message} |
| {PREFIX}-003 | Done | SKIPPED | {Requires hardware/sudo} |

---

## Gap Analysis

### Missing Coverage
{ROADMAP deliverables that have no corresponding ticket.}
- {Deliverable from ROADMAP} — no ticket covers this

### Scope Creep
{Tickets that don't map to any ROADMAP deliverable.}
- {SPIKE-NNN} — {reason and justification status}

---

## Dependency Issues

- {PREFIX}-003 blocks {PREFIX}-004, but {PREFIX}-004 does not list {PREFIX}-003 in Depends on
- {PREFIX}-005 is blocked by {PREFIX}-002 (Done) — can be unblocked
- Circular dependency detected: {PREFIX}-006 → {PREFIX}-007 → {PREFIX}-006

---

## Actions Taken

- Updated {PREFIX}-001 status: Open → Done (all criteria met, verification passed)
- Split {PREFIX}-006 into {PREFIX}-006a and {PREFIX}-006b (exceeded 8 acceptance criteria)
- Archived SPIKE-009 (superseded by {PREFIX}-003)
- Fixed bidirectional dependency: added Blocks reference in {PREFIX}-002 for {PREFIX}-004
- Synced README.md ticket table

---

## Recommendations

- {Actionable recommendation with context}
- Consider creating a ticket for ROADMAP deliverable X (missing coverage)
- {PREFIX}-002 verification is failing — investigate before sprint close
```

## Section Rules

Empty-state strings are literal — emit verbatim, do not paraphrase.

| Section | Required | Empty State |
|---|---|---|
| Status Distribution | Always | Never empty |
| Verification Results | Always | "No tickets in Done status." |
| Gap Analysis | Always | "All ROADMAP deliverables have ticket coverage. No scope creep detected." |
| Dependency Issues | Always | "All dependencies are consistent. No circular dependencies." |
| Actions Taken | Always | "No autonomous actions taken." |
| Recommendations | Always | "Sprint is healthy. No recommendations." |

## Verification Command Execution

- Source: extract commands from each Done ticket's `## Verification Steps` section
- Run from repo root unless the ticket specifies a different working directory
- If a command requires `sudo` or hardware access, mark as SKIPPED with reason
- If a command fails, record the last 5 lines of stderr+stdout, fenced as a code block in the Issues column
- Example: `` `ERROR: connection refused` ``
- If a ticket has multiple verification commands and more than one fails, record only the first failed command's output; append `(+{N} more failures)` when additional commands failed
- A ticket with ANY failed verification is reported as FAIL — do NOT change its status

## Ticket List Format

- List all ticket IDs comma-separated in Status Distribution table cells
- Do not truncate; include all IDs for each status
- Format: `{PREFIX}-001, {PREFIX}-002, {PREFIX}-003`

## Idempotency

- If `BA-REPORT.md` already exists, overwrite it completely
- Do not append dated sections or preserve old reports
- Each run produces a single, current report reflecting the live sprint state

## Actions Taken Scope

- Only record actions the agent is authorized to perform autonomously per ba-agent's policy
- Actions requiring approval go under Recommendations instead

## Data Sources

- Ticket files under `docs/anvil/sprints/{sprint-directory}/` — source of truth for Status, Depends on, Blocks, Verification Steps
- `ROADMAP.md` at repo root — source for Gap Analysis (Missing Coverage, Scope Creep)
- Do not fabricate ticket data or verification commands. Record missing fields as `missing` and surface the gap under Recommendations.
