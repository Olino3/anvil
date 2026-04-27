---
name: roadmap-format
description: Use when creating, validating, or editing `ROADMAP.md` phases and deliverables.
user-invocable: false
---

# ROADMAP Format

Canonical structure of `ROADMAP.md`. Agents must follow this format exactly unless overridden by higher-priority instructions.

## Location

`ROADMAP.md` at the project root. This is a first-class project document.

## Structure

```markdown
# ROADMAP — {Project Name}

> {Brief vision statement — one or two sentences describing what this project is becoming.}

## Phases

### Phase {N} — {Phase Name}
**Version:** {vX.Y.Z} <!-- optional: omit if project doesn't use semver -->
**Status:** {Not Started | In Progress | Complete}
**Prefix:** {PREFIX} <!-- uppercase, 3-5 chars, derived from phase name, unique across all phases -->
**Theme:** {One-sentence description of this phase's focus}

#### Goals
- {Goal with clear, measurable success criteria}
- {Goal}

#### Deliverables
- [ ] {Deliverable — brief description of a concrete output}
- [ ] {Deliverable}

#### Avoid Deepening
<!-- areas intentionally left shallow because a later phase replaces them -->

- {Area} — {which phase replaces it (or TBD if undetermined)}

#### Notes
- {Constraints, risks, dependencies on external systems}
- {Component impact notes}

---

<!-- repeat for each phase -->
```

## Example

```markdown
### Phase 1 — MVP
**Version:** v0.1.0
**Status:** In Progress
**Prefix:** MVP
**Theme:** Ship a usable single-user CLI that reads a config and executes one command end-to-end.

#### Goals
- CLI exits 0 on the happy path for ≥1 sample config under `examples/`
- `README.md` quickstart takes a new user from `git clone` to first green test in under 5 minutes

#### Deliverables
- [ ] `anvil` CLI entry point with `run` subcommand
- [ ] Config loader for `docs/anvil/config.yml`
- [ ] Integration test covering the MVP happy path

#### Avoid Deepening
- Multi-user auth — replaced by Phase 3 (AUTH)
- Plugin system — TBD

#### Notes
- Target Python 3.11+; do not add Windows support in this phase
```

## Field Semantics

| Field | Required | Rules |
|---|---|---|
| Phase Name | Yes | Human-readable, used as primary identity |
| Version | No | Semver format if provided. Sprint directory uses this when present |
| Status | Yes | One of: `Not Started`, `In Progress`, `Complete` |
| Prefix | Yes | Uppercase, 3-5 chars, unique across all phases. Used for ticket IDs |
| Theme | Yes | One sentence summarizing the phase focus |
| Goals | Yes | At least one goal. Each must include a quantitative or testable criterion (metric, pass/fail threshold, or named artifact) |
| Deliverables | Yes | Checkbox list. pm-agent generates tickets from these. ba-agent checks coverage |
| Avoid Deepening | No | Guidance for agents about tech debt. Reference which future phase handles it |
| Notes | No | Constraints, risks, external dependencies |

## Phase Ordering

Phases are numbered sequentially. Phase N MUST be completable using only artifacts from Phases 1..N-1; no forward references or dependencies on future phases are permitted.

## Avoid Deepening Rules

- Each entry names a future phase that replaces the area.
- If no future phase covers the concern, write `— TBD` and warn the caller. Do not invent a phase.

## Prefix Rules

- Derived from phase name: "MVP" from "MVP", "AUTH" from "Auth System", "DOCK" from "Docker Deployment"
- Must be unique across all phases in the ROADMAP
- Used as ticket ID prefix in sprints: `AUTH-001`, `AUTH-002`, etc.
- SPIKE tickets use a separate `SPIKE-NNN` sequence per sprint
- On collision (e.g., "AUTH" derived twice), suffix with phase number (`AUTH2`) or pick the next-most-distinctive token
- Never silently overwrite an existing prefix

## Negative Examples

- ❌ Do NOT use lowercase prefixes (e.g., `auth`; use `AUTH`)
- ❌ Do NOT omit Status, Prefix, or Theme fields
- ❌ Do NOT create circular phase dependencies (e.g., Phase 2 requires Phase 3)
- ❌ Do NOT reference a future phase in "Avoid Deepening" unless that phase exists

## Status Transitions

| From | To | Trigger | Actor |
|---|---|---|---|
| Not Started | In Progress | `/anvil-sprint` is run | pd-agent |
| In Progress | Complete (recommended) | All sprint tickets Done and verified | ba-agent (recommends) |
| In Progress | Complete (final) | ba-agent recommendation accepted | pd-agent |

## Procedure

When invoked to create or update ROADMAP.md:

1. Read the existing `ROADMAP.md` if present; validate against Field Semantics rules below
2. Validate each phase: unique Prefix, valid Status, at least one Goal and Deliverable
3. Check phase ordering: Phase N references only Phases 1..N-1 in Avoid Deepening
4. Emit the complete updated ROADMAP.md in a single fenced markdown block; do not include prose outside the fence
5. Report any rule violations before writing

## Pre-Write Validation Checklist

- [ ] Every phase has a unique 3–5 character uppercase Prefix
- [ ] Every phase Status is one of: `Not Started`, `In Progress`, `Complete`
- [ ] Every Deliverable line begins with `- [ ]` or `- [x]`
- [ ] No circular dependencies between phases
- [ ] No forward references in Avoid Deepening (all referenced future phases exist)
- [ ] No duplicate Prefix values, even within Avoid Deepening references
