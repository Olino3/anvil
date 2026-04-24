---
name: anvil-config-schema
description: Use when reading, validating, or writing `docs/anvil/config.yml` component definitions.
user-invocable: false
---

# docs/anvil/config.yml — Schema

Anvil's per-project config file. Describes each component of the project and
the commands used to test, build, lint, and type-check it.

## Top-level structure

```yaml
components:
  <component-name>:
    language: <language-id>
    source_dir: <path>
    test_dir: <path>
    test_pattern: <glob>
    test_command: <shell command>
    build_command: <shell command>       # optional
    lint_command: <shell command>        # optional
    type_check_command: <shell command>  # optional
```

Template syntax: `<component-name>` and `<path>` are placeholder tokens (not literal keys).

**Required fields:** language, source_dir, test_dir, test_pattern, test_command

## Fields

- **language** — identifier like `python`, `typescript`, `go`, `ruby`. Used by red/green agents to select language-specific test scaffolding and assertion syntax.
- **source_dir** — relative path (from repo root) to where production code lives.
- **test_dir** — relative path (from repo root) to where tests live.
- **test_pattern** — glob or pattern that maps a source module to its test file. The `{module}` placeholder is substituted with the module name (file basename without extension). Example: `tests/test_{module}.py` with module `auth` → `tests/test_auth.py`.
- **test_command** — exact command to run the test suite for this component. Executed from repo root.
- **build_command** — optional. Executed before tests to ensure compilation/build succeeds.
- **lint_command** — optional. Executed after GREEN phase to catch style issues.
- **type_check_command** — optional. Executed after GREEN in typed languages.

## Example

```yaml
components:
  api:
    language: python
    source_dir: src/api
    test_dir: tests/api
    test_pattern: "tests/api/test_{module}.py"
    test_command: "pytest tests/api -v"
    lint_command: "ruff check src/api tests/api"
    type_check_command: "mypy src/api"
  web:
    language: typescript
    source_dir: web/src
    test_dir: web/tests
    test_pattern: "web/tests/{module}.test.ts"
    test_command: "npm test --prefix web"
    build_command: "npm run build --prefix web"
```

## Read Path

Always Read `docs/anvil/config.yml` from repo root; do not cache across turns.

## Operations

When consulting this schema, perform one or more of these operations:

1. **lookup_component(name)** — retrieve the commands and metadata for a named component.
2. **validate(config)** — check that all required fields are present, all `Component:` field values in tickets match component keys, and all paths are relative to repo root.
3. **resolve_test_command(component, module)** — apply the `{module}` substitution to `test_pattern` and return the resolved command path.

## On Validation Failure

If a component name is missing or a required field is absent:
- Emit error: `component '<name>' not found in docs/anvil/config.yml; available components: [<keys>]`
- Or: `component '<name>' missing required field '<field>'; found: [<fields>]`
- Halt and request the agent provide or correct the config.

## Rules

- Every ticket's `Component:` field must exactly match a key in this file. If it does not, red/green agents will fail to pick commands.
- Commands are run as-is by the agent; they are not modified or compiled. Keep them shell-executable and testable from the repo root.
- Relative paths must be relative to repo root unless a command explicitly changes directory.
