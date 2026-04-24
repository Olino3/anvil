---
description: Anvil commit message conventions — scope, type, and message style.
applyTo: "**/*"
author: Olino3
version: "2.1.0"
---

# Commit Conventions

All anvil agents MUST follow these conventions when creating commits.

Anvil follows a **RED / GREEN / REFACTOR** TDD cycle (see `tdd-discipline.instructions.md`). Commit types below map to cycle phases where noted.

## Format

```
type(scope): description
```

## Types

| Type | When to Use |
|---|---|
| `test` | RED phase — failing tests committed before implementation |
| `feat` | GREEN phase — new feature implementation to pass RED tests |
| `fix` | GREEN phase — bug fix implementation to pass RED tests (see Exceptions) |
| `chore` | Non-code changes: sprint tickets, config, dependency updates |
| `docs` | Documentation changes: ROADMAP, README, specs |
| `refactor` | Code restructuring without behavior change (REFACTOR phase) |
| `style` | Formatting, whitespace, naming — no logic changes |

## Scope selection

- **Single-component change:** scope = the component / module name (e.g., `auth`, `api`, `frontend`). Pattern: `^[a-z0-9-]+$`.
- **Multi-component change:** scope = the *dominant* changed component (the one receiving the largest or most consequential edit).
- **Cross-cutting change** (touches unrelated components or the repository root): scope = `repo`.
- **Reserved scopes** (exceptions to the component rule): `sprint` and `roadmap`. Use these for sprint-ticket artifacts and ROADMAP updates regardless of which files changed — see *Sprint Artifact Commits* below.

## Rules

- **One logical unit per commit.** If you can describe it with "and", split it into two commits.
- **Descriptions MUST NOT contain the conjunction ` and `.** This is machine-checkable and enforces the one-unit rule.
- **RED before GREEN.** The test commit always precedes the implementation commit. Never combine them.
- **Description** is imperative mood, lowercase, no trailing period (e.g., "add user validation").
- **No empty commits.** Every commit must modify at least one tracked file's content. Whitespace-only or no-op commits are prohibited unless typed `style`.

## Exceptions

- **`docs`, `chore`, and `style`** are NOT subject to RED/GREEN pairing. They stand alone.
- **`fix` without a preceding `test` commit** is permitted only for trivial hotfixes where writing a regression test is disproportionate (e.g., typo in a user-facing string, dependency version bump to patch a CVE). Otherwise, pair `fix` with a preceding `test` commit that captures the bug as a failing test — the normal TDD rule.
- **`refactor`** requires a passing test suite before and after; no test commit is added.

## TDD Commit Pairs

Every non-exception feature or fix produces at minimum two commits:

1. `test(scope): add failing tests for <feature>` — RED phase
2. `feat(scope): implement <feature>` or `fix(scope): fix <issue>` — GREEN phase
3. *(Optional)* `refactor(scope): extract <abstraction>` — REFACTOR phase (tests must still pass)

## Negative example

REJECTED:
```
feat(auth): add login and fix logout bug
```

Why: contains ` and `; bundles a feature with a fix; violates one-logical-unit rule.

CORRECTED — two commits:
```
feat(auth): add login
fix(auth): reject empty session token on logout
```

## Sprint Artifact Commits

Use literal reserved scopes for these workflow commits:

- `chore(sprint): generate <phase-name> sprint tickets` — after pm-agent creates a sprint
- `docs(roadmap): create project roadmap` — initial ROADMAP creation
- `docs(roadmap): update <phase-name>` — ROADMAP updates
- `chore(sprint): update <ticket-id> status` — ticket status changes

## Branch Naming

Read `git.branch_prefix` from `docs/anvil/config.yml`, then append `phase-<slug>`:

```
feature/phase-mvp
feature/phase-auth-system
fix/phase-hotfix-login
```

**Fallback:** If `docs/anvil/config.yml` is missing or the `git.branch_prefix` key is absent, use `feature/` as the prefix. Do NOT prompt the user — the default is authoritative.

## Pre-commit validation checklist

Before calling `git commit`, verify every predicate holds. If any fails, fix the message or the staged changes before committing.

1. Type is exactly one of: `test`, `feat`, `fix`, `chore`, `docs`, `refactor`, `style`.
2. Scope matches `^[a-z0-9-]+$`, OR is a reserved scope (`sprint`, `roadmap`).
3. Description is lowercase and has no trailing period.
4. Description does not contain the substring ` and ` (with spaces).
5. If type is `feat` or `fix` (non-exception), the immediately preceding commit on this branch is a `test(<same-scope>): ...` commit, OR the exception rule above applies and has been noted.
6. Staged changes modify at least one tracked file's content (not whitespace-only, unless type is `style`).

## Execution mechanics

- Use the Bash tool to invoke `git commit -m "..."` with a HEREDOC when the message spans multiple lines.
- Stage files by name (`git add path/to/file`). Do NOT use `git add -A` or `git add .` — those risk sweeping in sensitive or unrelated files.
- Trailers (e.g., `Co-authored-by:`) are permitted after a blank line following the subject. They do not count toward the ` and ` rule and do not affect scope/type validation.
