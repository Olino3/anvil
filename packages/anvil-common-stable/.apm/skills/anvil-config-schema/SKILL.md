---
name: anvil-config-schema
description: Reference — schema for docs/anvil/config.yml (components, test/build/lint/type_check commands per component). Consult when reading or writing the Anvil config.
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

## Fields

- **language** — identifier like `python`, `typescript`, `go`, `ruby`. Used by red/green agents to pick idiomatic test / implementation patterns.
- **source_dir** — relative path to where production code lives.
- **test_dir** — relative path to where tests live.
- **test_pattern** — glob or pattern that maps a source module to its test file. `{module}` placeholder is substituted with the module name. Example: `tests/test_{module}.py`.
- **test_command** — exact command to run the test suite for this component.
- **build_command** — optional. Run before tests to ensure compilation/build.
- **lint_command** — optional. Run after GREEN to catch style issues.
- **type_check_command** — optional. Run after GREEN in typed languages.

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

## Rules

- Every ticket's `Component:` field must match a key in this file. If it does not, `/anvil:develop` and `red.agent` / `green.agent` will fail to pick commands.
- Commands are run by the agent, not compiled or modified. Keep them shell-executable.
