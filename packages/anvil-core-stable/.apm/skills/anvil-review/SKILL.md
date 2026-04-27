---
name: anvil-review
description: Sprint health analysis and verification — delegate to the @ba agent, present recommendations, do not apply cleanup
user-invocable: true
---

# Anvil Review

**Goal:** delegate sprint health analysis to the `@ba` agent and present its
**Recommended actions** to the user. This skill does not apply cleanup —
ticket splits, archival, status corrections, and README rebuilds are user
or orchestrator actions.

## Invocation

- Slash command: `/anvil-review <phase>`
- APM runtime: `apm run anvil-review --param phase=<phase>`
- Agent mention: `@ba <phase>`

## Arguments

- `phase` (required, string) — sprint identifier matched against directory
  names under `docs/anvil/sprints/`. See Step 1 for matching rules.

## Schema reference

`BA-REPORT.md` MUST conform to the `ba-report-format` skill (from
`anvil-common-stable`). The `@ba` agent owns the report; this skill
orchestrates and surfaces results.

## Procedure

### 1. Locate sprint

Use **Glob** on `docs/anvil/sprints/*` and match `<phase>` against directory
names with this precedence (case-insensitive):

1. **Exact** directory name (e.g., `v2.1-auth-system`).
2. **Version prefix** (e.g., `v2.1` → `v2.1-auth-system`).
3. **Slug prefix** (e.g., `auth` → `v2.1-auth-system`).

If multiple directories tie at the same precedence level, halt and output
verbatim:

> No unique sprint for `{phase}`. Candidates: {list}. Disambiguate.

If zero match, halt and output:

> No sprint found for `{phase}`. Available sprints: {list of directory names}.

### 2. Read context

Both reads must succeed before invoking the agent:

- Use **Read** on `ROADMAP.md` to find the matching phase (for gap analysis).
- Use **Read** on `docs/anvil/config.yml`.

If either is missing, halt with the missing path. Do not invoke `@ba` with
partial context.

### 3. Invoke @ba

Pick the invocation path by host capability — do not guess:

- If the `Task` tool with `subagent_type=ba` is available → invoke `@ba`.
- Otherwise → run `apm run anvil-review --param phase=<phase>` via **Bash**.

Pass the following payload:

- `sprint_dir` — directory path from Step 1.
- `roadmap_phase` — the matched ROADMAP phase block.
- `config` — full contents of `docs/anvil/config.yml`.

Block until the agent returns. Do not retry on partial output. The agent
writes `BA-REPORT.md` inside the sprint directory.

(Sub-agent reference, informational only: `@ba` analyzes sprint health,
verifies Done tickets, checks ROADMAP coverage, validates dependencies, and
ends `BA-REPORT.md` with a **Recommended actions** section. See the `@ba`
agent definition for details.)

### 4. Present results

Use **Read** on `{sprint_dir}/BA-REPORT.md`. If the file is missing or has
no **Recommended actions** section, halt with an error.

Surface to the user, in this order:

1. **Status distribution** — counts by status from the report.
2. **Verification failures** — empty-state literal `None.` if there are none.
3. **Gaps and scope creep** — empty-state literal `None.` if there are none.
4. **Recommended actions** — verbatim from the report, marked with severity.

### 5. Completion contract

Emit as the final assistant message:

`Review complete for {sprint_dir}. {N} recommended actions. Apply via orchestrator or user action.`

Then stop. Do not apply any recommended action. Do not invoke any other
skill.

## Constraints

- **Read-and-report only on results.** This skill only writes to
  `BA-REPORT.md` indirectly via the `@ba` agent.
- **Cleanup is out-of-scope.** Splits, archival, status corrections, and
  README rebuilds are user or `review-orchestrator` actions.

## Failure modes

Halt and report — do not produce a partial review:

- Phase did not match exactly one sprint (Step 1).
- `ROADMAP.md` or `docs/anvil/config.yml` missing (Step 2).
- `@ba` invocation unavailable, errored, or timed out (Step 3).
- `BA-REPORT.md` missing or malformed after the agent returns (Step 4).
