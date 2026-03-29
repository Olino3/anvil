# ROADMAP Format

Reference file for pd-agent and ba-agent. Defines the canonical structure of `ROADMAP.md`.

## Location

`ROADMAP.md` at the project root. This is a first-class project document.

## Structure

```markdown
# ROADMAP — {Project Name}

> {Brief vision statement — one or two sentences describing what this project is becoming.}

## Phases

### Phase {N} — {Phase Name}
**Version:** {vX.Y.Z} *(optional — omit if project doesn't use semver)*
**Status:** {Not Started | In Progress | Complete}
**Prefix:** {PREFIX} *(uppercase, 3-5 characters, derived from phase name, unique across all phases)*
**Theme:** {One-sentence description of this phase's focus}

#### Goals
- {Goal with clear, measurable success criteria}
- {Goal}

#### Deliverables
- [ ] {Deliverable — brief description of a concrete output}
- [ ] {Deliverable}

#### Avoid Deepening
_{Areas to avoid investing in because a later phase replaces them.}_
- {Area} — {which phase replaces it}

#### Notes
- {Constraints, risks, dependencies on external systems}
- {Component impact notes}

---

*(repeat for each phase)*
```

## Field Semantics

| Field | Required | Rules |
|---|---|---|
| Phase Name | Yes | Human-readable, used as primary identity |
| Version | No | Semver format if provided. Sprint directory uses this when present |
| Status | Yes | One of: `Not Started`, `In Progress`, `Complete` |
| Prefix | Yes | Uppercase, 3-5 chars, unique across all phases. Used for ticket IDs |
| Theme | Yes | One sentence summarizing the phase focus |
| Goals | Yes | At least one goal with measurable success criteria |
| Deliverables | Yes | Checkbox list. pm-agent generates tickets from these. ba-agent checks coverage |
| Avoid Deepening | No | Guidance for agents about tech debt. Reference which future phase handles it |
| Notes | No | Constraints, risks, external dependencies |

## Phase Ordering

Phases are numbered sequentially. Dependencies between phases are implicit in ordering — Phase N should be completable without Phase N+1.

## Prefix Rules

- Derived from phase name: "MVP" from "MVP", "AUTH" from "Auth System", "DOCK" from "Docker Deployment"
- Must be unique across all phases in the ROADMAP
- Used as ticket ID prefix in sprints: `AUTH-001`, `AUTH-002`, etc.
- SPIKE tickets use a separate `SPIKE-NNN` sequence per sprint

## Status Transitions

```
Not Started → In Progress → Complete
```

- pd-agent sets `In Progress` when `/anvil:sprint` is run for the phase
- ba-agent recommends `Complete` when all sprint tickets are Done and verified
- pd-agent makes the final status update
