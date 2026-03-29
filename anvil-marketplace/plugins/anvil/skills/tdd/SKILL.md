---
name: tdd
description: TDD discipline reference — RED/GREEN/REFACTOR cycle, language-agnostic, used implicitly by dev-agent
user-invocable: true
---

# TDD Discipline

The RED/GREEN/REFACTOR cycle used by anvil for all implementation work.

## The Cycle

### 1. RED — Write a Failing Test

Write a test that specifies the desired behavior. The test MUST fail because the feature doesn't exist yet.

- **Do:** Assert on return values, side effects, and state changes
- **Do:** Cover happy path, error cases, and edge cases
- **Do:** Use existing test fixtures and helpers from the project
- **Don't:** Write production code
- **Don't:** Write tests that pass without asserting anything meaningful
- **Don't:** Write tests that fail due to syntax errors or import issues

**Commit:** `test(scope): add failing tests for <feature>`

### 2. GREEN — Make the Test Pass

Write the minimum production code needed to make the failing test pass.

- **Do:** Implement only what the test requires
- **Do:** Follow existing code conventions in the project
- **Don't:** Over-engineer or add features the test doesn't cover
- **Don't:** Write additional tests
- **Don't:** Break any previously passing tests

**Commit:** `feat(scope): implement <feature>` or `fix(scope): fix <issue>`

### 3. REFACTOR — Clean Up

If the code needs restructuring, do it now. Tests must still pass after refactoring.

- **Do:** Extract duplicated code, rename for clarity, simplify logic
- **Don't:** Change behavior — all tests must still pass
- **Don't:** Add new functionality

**Commit (if changes made):** `refactor(scope): <description>`

## How Anvil Uses TDD

The dev-agent implements every ticket through this cycle:

1. It dispatches the `red-agent` as a sub-agent with the feature spec → RED tests are written
2. It commits the failing tests
3. It dispatches the `green-agent` as a sub-agent with the test file → implementation is written
4. It commits the passing implementation
5. It refactors if needed and commits

## Language Agnostic

Anvil does not hardcode any test framework. The RED and GREEN agents read `docs/anvil/config.yml` for:
- `test_command` — how to run tests
- `test_dir` — where tests live
- `test_pattern` — how test files map to source files

They explore existing test files to discover the project's conventions, fixtures, and assertion style.

## Rules

- **Every feature or fix produces at minimum two commits:** one for tests (RED), one for implementation (GREEN)
- **Never combine RED and GREEN** in a single commit
- **Tests must fail for the right reason** — a missing feature, not a syntax error
- **One behavior per test** — each test method tests exactly one thing
- **Existing tests are sacred** — if your implementation breaks a passing test, fix your implementation
