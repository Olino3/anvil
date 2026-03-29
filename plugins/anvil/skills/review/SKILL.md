---
name: review
description: Run sprint health analysis and verification by dispatching the ba-agent
user-invocable: true
---

# Anvil Review

Review sprint health, verify completed tickets, and generate a BA report.

## Arguments

- `phase` (required) — the target sprint by phase name, version, or prefix

## Procedure

### 1. Locate Sprint

Search `docs/anvil/sprints/` for a directory matching the argument. Match against directory names (which contain version and/or phase slug). If not found:
> "No sprint found for `{phase}`. Available sprints: {list of sprint directories}"

### 2. Read Context

- Read `ROADMAP.md` to find the matching phase (for gap analysis)
- Read `docs/anvil/config.yml` for project context

### 3. Dispatch ba-agent

Dispatch the `ba-agent` as a sub-agent with:
- The sprint directory path
- The matching ROADMAP phase details
- The project config

The ba-agent will:
1. Analyze sprint health
2. Verify Done tickets
3. Check ROADMAP coverage gaps
4. Validate dependencies
5. Perform autonomous cleanup
6. Sync the README
7. Write BA-REPORT.md

### 4. Present Results

After the ba-agent completes, read `BA-REPORT.md` and present:
- Status distribution
- Any verification failures
- Any gaps or scope creep
- Actions taken
- Recommendations

Highlight items that need user attention.
