---
name: sync
description: Fix drift between sprint ticket metadata and README status tables
user-invocable: true
---

# Anvil Sync

Sync a sprint's README with the actual state of its ticket files.

## Arguments

- `phase` (required) — the target sprint by phase name, version, or prefix

## Procedure

### 1. Locate Sprint

Search `docs/anvil/sprints/` for a directory matching the argument. If not found:
> "No sprint found for `{phase}`. Available sprints: {list of sprint directories}"

### 2. Dispatch sprint-syncer-agent

Dispatch the `sprint-syncer-agent` as a sub-agent with:
- The sprint directory path

The agent will:
1. Read all ticket files
2. Rebuild README status tables
3. Fix bidirectional dependency references
4. Generate a sync report

### 3. Present Report

Show the sync report highlighting:
- Status changes made to README
- Dependency fixes applied to ticket files
- Current sprint progress percentage
