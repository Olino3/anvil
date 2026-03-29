# Commit Conventions

Reference file for all anvil agents. Agents MUST follow these conventions when creating commits.

## Format

```
type(scope): description
```

## Types

| Type | When to Use |
|---|---|
| `test` | RED phase — failing tests committed before implementation |
| `feat` | GREEN phase — new feature implementation to pass RED tests |
| `fix` | GREEN phase — bug fix implementation to pass RED tests |
| `chore` | Non-code changes: sprint tickets, config, dependency updates |
| `docs` | Documentation changes: ROADMAP, README, specs |
| `refactor` | Code restructuring without behavior change (REFACTOR phase) |
| `style` | Formatting, whitespace, naming — no logic changes |

## Rules

- **One logical unit per commit.** If you can describe it with "and", split it into two commits.
- **RED before GREEN.** The test commit always precedes the implementation commit. Never combine them.
- **Scope** matches the component or module being changed (e.g., `auth`, `api`, `frontend`).
- **Description** is imperative mood, lowercase, no trailing period (e.g., "add user validation").
- **No empty commits.** Every commit must contain meaningful changes.

## TDD Commit Pairs

Every feature or fix produces at minimum two commits:

1. `test(scope): add failing tests for <feature>` — RED phase
2. `feat(scope): implement <feature>` or `fix(scope): fix <issue>` — GREEN phase

Optional third commit for refactoring:

3. `refactor(scope): extract <abstraction>` — REFACTOR phase (tests must still pass)

## Sprint Artifact Commits

- `chore(sprint): generate <phase-name> sprint tickets` — after pm-agent creates sprint
- `docs(roadmap): create project roadmap` — initial ROADMAP creation
- `docs(roadmap): update <phase-name>` — ROADMAP updates
- `chore(sprint): update <ticket-id> status` — ticket status changes

## Branch Naming

Read `git.branch_prefix` from `docs/anvil/config.yml` (default: `feature/`), then append `phase-<slug>`:

```
feature/phase-mvp
feature/phase-auth-system
fix/phase-hotfix-login
```
