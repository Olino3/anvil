---
description: RED/GREEN/REFACTOR discipline — language-agnostic TDD cycle for Anvil ticket implementation.
applyTo: "**/*"
author: Olino3
version: "2.1.0"
---

# TDD Discipline

The RED/GREEN/REFACTOR cycle used by anvil for all implementation work.

## Activation

This instruction is **active** whenever you are writing code or tests for a sprint ticket, feature, or fix. Outside that context (e.g., documentation-only edits, config changes, exploratory spikes) it is inert.

The frontmatter `applyTo: "**/*"` means the instruction is *available* on any file, not that every edit triggers the cycle. The trigger is the nature of the work (implementing behavior), not the file path.

## The Cycle

### 1. RED — Write a Failing Test

Write a test that specifies the desired behavior. The test MUST fail because the feature doesn't exist yet.

- **Do:** Assert on return values, side effects, and state changes
- **Do:** Cover happy path, error cases, and edge cases
- **Do:** Use existing test fixtures and helpers from the project
- **Don't:** Write production code
- **Don't:** Write tests that pass without asserting anything meaningful
- **Don't:** Write tests that fail due to syntax errors or import issues

**Verification gate:** Run the project's test command and observe the output. The test MUST fail with an error about missing functionality (e.g., `NameError`, `AttributeError`, `undefined`, assertion on absent behavior) — NOT a syntax, import, or fixture-loading error. Do not proceed to GREEN until the failing output has been observed and the failure reason confirmed.

**Commit:** `test(scope): add failing tests for <feature>`

### 2. GREEN — Make the Test Pass

Write the minimum production code needed to make the failing test pass.

- **Do:** Implement only what the test requires
- **Do:** Follow existing code conventions in the project
- **Don't:** Over-engineer or add features the test doesn't cover
- **Don't:** Write additional tests
- **Don't:** Break any previously passing tests

**Verification gate:** Re-run the project's test command. The new test MUST pass AND every previously passing test MUST still pass. Do not commit until both conditions are confirmed from actual test output.

**Commit:** `feat(scope): implement <feature>` or `fix(scope): fix <issue>`

### 3. REFACTOR — Clean Up

After GREEN, inspect the code for duplication, unclear names, or unnecessary complexity.

- **Refactor only when** duplication, naming, or complexity is demonstrably reduced. Skip this phase otherwise — do not refactor cosmetically.
- **Do:** Extract duplicated code, rename for clarity, simplify logic
- **Don't:** Change behavior — all tests must still pass
- **Don't:** Add new functionality

**Verification gate:** Re-run the test command. All tests must still pass.

**Commit (if changes made):** `refactor(scope): <description>`

## Cycle-break recovery

If GREEN reveals that the RED test was wrong (asserted the wrong behavior, targeted the wrong function, missed a required edge case):

1. Revert the GREEN commit (`git revert HEAD`).
2. Fix the RED test and re-commit with `test(scope): fix failing tests for <feature>`.
3. Re-run the GREEN phase against the corrected test.

Do NOT edit the RED test after committing it in order to match a broken implementation. The test is the specification.

## Orchestration (informational — not steps you execute)

This section describes how Anvil's `dev-agent` orchestrates the cycle. You do not execute these steps unless you *are* the `dev-agent`. Treat this as context for the surrounding system.

1. The `dev-agent` dispatches the `red-agent` as a sub-agent with the feature spec → RED tests are written.
2. It commits the failing tests.
3. It dispatches the `green-agent` as a sub-agent with the test file → implementation is written.
4. It commits the passing implementation.
5. It refactors if needed and commits.

**Sub-agent fallback:** If the `red-agent` or `green-agent` sub-agents are not available (e.g., the instruction is being consumed by a single-agent harness), perform each phase directly using the same RED / GREEN / REFACTOR rules above. The discipline is the contract; the agents are one implementation of it.

## Language Agnostic

Anvil does not hardcode any test framework. The RED and GREEN phases read `docs/anvil/config.yml` for:
- `test_command` — how to run tests
- `test_dir` — where tests live
- `test_pattern` — how test files map to source files

Explore existing test files to discover the project's conventions, fixtures, and assertion style.

**Config fallback:** If `docs/anvil/config.yml` is missing or any required key is absent, halt and request the config from the user. Do NOT guess a test command or infer a test directory — a wrong guess produces tests that never run, which silently breaks the RED verification gate.

## Rules

- **Every feature or fix produces at minimum two commits:** one for tests (RED), one for implementation (GREEN)
- **Never combine RED and GREEN** in a single commit
- **Tests must fail for the right reason** — a missing feature, not a syntax error (see the RED verification gate)
- **One behavior per test** — each test method tests exactly one thing
- **Existing passing tests are immutable constraints** — the implementation yields to them, not the reverse. If implementation breaks a passing test, fix the implementation.
- **Commit only when the surrounding workflow permits commits.** Some harnesses call these phases without autonomous commit authority; in that case, stage the changes and report the intended commit message instead.
