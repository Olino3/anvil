---
name: ticket-template
description: Reference — required fields and sections for every sprint ticket file. Consult when creating a new ticket or a SPIKE.
user-invocable: false
---

# Ticket Template

Reference file for pm-agent, dev-agent, ba-agent, and sprint-syncer-agent. Defines the canonical format for sprint tickets.

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

{Why this ticket exists. Current state, the problem it solves, and key constraints.}

---

## Acceptance Criteria

- [ ] {Criterion — specific, testable, unambiguous}
- [ ] {Criterion}

---

## Implementation Checklist

### 1. {Step title}

- [ ] {Sub-step with enough detail to act on}
- [ ] {Sub-step}

### N. Commit

{Suggested commit message following commit conventions.}

---

## Verification Steps

{Runnable commands that verify the ticket is done. Use test/build/lint commands from the component's config in docs/anvil/config.yml. Every command must pass before closing.}

---

## Notes

- {Caveats, risks, things deferred to other tickets}
- {Out-of-scope items that may need SPIKE tickets}
```

## Field Definitions

| Field | Values | Set By |
|---|---|---|
| Status | `Open` (new), `In Progress` (dev-agent working), `Done` (verified complete), `Blocked` (dependency not met) | pm-agent creates as Open. dev-agent sets In Progress/Done. ba-agent may update based on verification |
| Phase | Phase name and optional version from ROADMAP.md | pm-agent |
| Type | `Feat` (new feature), `Fix` (bug fix), `Chore` (non-code), `Refactor` (restructuring), `Docs` (documentation) | pm-agent |
| Component | Must match a component key in `docs/anvil/config.yml` | pm-agent |
| Depends on | Relative markdown link to dependency ticket, or `_(none)_` | pm-agent, dev-agent (when creating SPIKEs) |
| Blocks | Relative markdown link to blocked ticket, or `_(none)_` | pm-agent, sprint-syncer-agent (fixes bidirectional refs) |

## Dependency Rules

- Dependencies MUST be bidirectional: if A depends on B, then B must list A in Blocks
- sprint-syncer-agent fixes missing reverse references
- No circular dependencies allowed
- dev-agent refuses to start a ticket whose dependencies are not all `Done`

## Acceptance Criteria Rules

- Maximum ~8 criteria per ticket. If more are needed, split the ticket
- Each criterion must be specific and testable — no vague statements like "works correctly"
- pm-agent writes initial criteria from ROADMAP deliverables
- dev-agent checks criteria boxes as implementation proceeds

## SPIKE Tickets

- Created by dev-agent when out-of-scope work is discovered during implementation
- Use `SPIKE-NNN` prefix with a separate numbering sequence per sprint
- Typically Type: `Chore`, `Docs`, or `Refactor`
- Do not block the current ticket — they represent future work
