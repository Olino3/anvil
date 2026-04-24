---
name: anvil-review
description: Run sprint health analysis and verification by invoking the ba agent. The ba agent reports recommended cleanup; it does not apply it.
user-invocable: true
---

# Anvil Review

## Invocation

- Slash command: `/anvil:review <phase>`
- APM runtime: `apm run anvil:review --param phase=<phase>`
- Agent mention: `@ba <phase>`

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

### 3. Invoke ba agent

Invoke `@ba` (where supported) or run `apm run anvil:review --param phase=<phase>` with:
- The sprint directory path
- The matching ROADMAP phase details
- The project config

The `@ba` agent will:
1. Analyze sprint health
2. Verify Done tickets
3. Check ROADMAP coverage gaps
4. Validate dependencies
5. Write BA-REPORT.md ending with a **Recommended actions** section

The agent does **not** apply cleanup — ticket splits, archival, status corrections, and README rebuilds are user actions (or orchestrator actions).

### 4. Present Results

After the `@ba` agent completes, read `BA-REPORT.md` and present:
- Status distribution
- Any verification failures
- Any gaps or scope creep
- Recommended actions

Highlight items that need user attention. The user (or the `review-orchestrator` in the orchestrator package) decides which recommendations to apply.
