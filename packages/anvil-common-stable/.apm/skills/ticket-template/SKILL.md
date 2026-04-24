---
name: ticket-template
description: Use when creating, validating, or editing sprint ticket files.
user-invocable: false
---

# Ticket Template

Reference file for pm-agent, dev-agent, ba-agent, and sprint-syncer-agent. Defines the canonical format for sprint tickets.

**Cross-references:** See `docs/anvil/config.yml` (component keys), `ROADMAP.md` (phase Prefix field).

## File Naming

`{PREFIX}-{NNN}-{kebab-description}.md`

Examples: `MVP-001-user-login.md`, `AUTH-003-session-management.md`, `SPIKE-001-evaluate-jwt-libs.md`

- PREFIX: from the phase's `Prefix` field in ROADMAP.md
- NNN: zero-padded three-digit sequential number, starting at 001
- SPIKE tickets use the `SPIKE` prefix with their own sequence per sprint

## Template

```markdown
# {PREFIX}-{NNN} — {Title}

**Status:** {Open | In Progress | Done | Blocked}
**Phase:** {Phase Name} ({vX.Y.Z})
**Type:** {Feat | Fix | Chore | Refactor | Docs}
**Component:** {component-name from config.yml}
**Depends on:** {[PREFIX-NNN](PREFIX-NNN-slug.md) | _(none)_}
**Blocks:** {[PREFIX-NNN](PREFIX-NNN-slug.md) | _(none)_}

---

## Context

Why this ticket exists. Current state, the problem it solves, and key constraints.

---

## Acceptance Criteria

- [ ] First criterion — specific, testable, unambiguous
- [ ] Second criterion
- [ ] (maximum ~8 criteria; if more needed, split into a new ticket)

---

## Implementation Checklist

### 1. {Step title}

- [ ] {Sub-step with enough detail to act on (name a file, command, or function)}
- [ ] {Sub-step}

### 2. {Step title}

- [ ] {Sub-step}

### Final. Commit

Suggested commit message following commit conventions.

---

## Verification Steps

Runnable commands that verify the ticket is done. Use test/build/lint commands from `{Component}` in `docs/anvil/config.yml`. Every command must pass before marking Done.

---

## Notes

- Caveats, risks, things deferred to other tickets (link SPIKE if created)
- Out-of-scope items requiring SPIKE tickets
```

**Sentinel:** Use the literal string `_(none)_` when there are no dependencies or blocks.

## Field Definitions

| Field | Values | Set By |
|---|---|---|
| Status | `Open` (new), `In Progress` (work started), `Done` (verified), `Blocked` (waiting) | pm-agent (creates as Open); dev-agent (In Progress/Done); ba-agent (may update based on verification) |
| Phase | Phase name and optional version from ROADMAP.md | pm-agent |
| Type | `Feat`, `Fix`, `Chore`, `Refactor`, `Docs` (case-sensitive, exact match required) | pm-agent (default: `Chore` for non-feature work) |
| Component | Must match a component key in `docs/anvil/config.yml` | pm-agent (lookup before setting) |
| Depends on | Relative markdown link to dependency ticket, or `_(none)_` | pm-agent, dev-agent (when creating SPIKEs) |
| Blocks | Relative markdown link to blocked ticket, or `_(none)_` | pm-agent, sprint-syncer-agent (fixes bidirectional refs) |

## Dependency Rules

- Dependencies MUST be bidirectional: if A depends on B, then B must list A in Blocks
- sprint-syncer-agent automatically fixes missing reverse references
- No circular dependencies allowed
- dev-agent refuses to start a ticket whose dependencies are not all `Done`

## Acceptance Criteria Rules

- Maximum ~8 criteria per ticket. If more are needed, split the ticket into two
- Each criterion must be specific and testable — measurable outcomes, not vague statements
- Example: ✅ "Password field must be masked in the UI" vs ❌ "Login works correctly"
- pm-agent writes initial criteria derived from ROADMAP deliverables
- dev-agent checks criterion boxes as implementation proceeds

## SPIKE Tickets

- Created by dev-agent when out-of-scope or uncertain work is discovered during implementation
- Use `SPIKE-NNN` prefix with a separate numbering sequence per sprint
- Default Type: `Chore` or `Docs` (research SPIKEs), or `Refactor` (cleanup SPIKEs)
- Do not block the current ticket; they represent future exploratory or cleanup work
- Creation flow: dev-agent discovers scope issue → file SPIKE ticket → continue parent ticket → note SPIKE under Notes

## Failure Mode

If any Verification Steps command fails:
- Set Status: `Blocked` (not `Done`)
- Add a Note describing the failure and root cause
- Do not advance Status until all verification commands pass

## Operational Triggers

**pm-agent:**
- When creating a new ticket: read ROADMAP.md (extract Phase, Prefix), read docs/anvil/config.yml (validate Component), generate filename matching `{PREFIX}-{NNN}-{kebab-description}.md`

**dev-agent:**
- Before starting work: verify all `Depends on` tickets are `Done`; if not, set Status `Blocked`
- After implementation: run all Verification Steps commands from the component's config (bash tool)
- If any command fails: set Status `Blocked` and add failure note

**ba-agent:**
- When reviewing: verify all acceptance criteria are checked, no circular dependencies exist, all Blocks/Depends on references are bidirectional

## Pre-Save Checklist

When creating or updating a ticket file:

- [ ] Filename matches `{PREFIX}-{NNN}-kebab-description.md` pattern
- [ ] All six header fields present: Status, Phase, Type, Component, Depends on, Blocks
- [ ] Component field matches a key in `docs/anvil/config.yml`
- [ ] Type is one of: `Feat`, `Fix`, `Chore`, `Refactor`, `Docs` (case-sensitive)
- [ ] All Depends on links resolve to existing ticket files
- [ ] Dependencies are bidirectional: if A → B, then B lists A in Blocks
- [ ] Acceptance criteria are specific and testable
- [ ] Verification Steps are runnable commands from the component's config
