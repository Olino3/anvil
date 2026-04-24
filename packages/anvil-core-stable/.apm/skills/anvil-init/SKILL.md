---
name: anvil-init
description: Interactive project setup — detect tech stack, configure components, write docs/anvil/config.yml
user-invocable: true
---

# Anvil Init

## Invocation

- Slash command: `/anvil:init`
- APM runtime: `apm run anvil:init`
- Agent mention (Cursor, Copilot): not applicable — init is a project-setup skill, not an agent

Set up anvil for this project through interactive conversation.

## Procedure

### 1. Check Existing Config

Read `docs/anvil/config.yml`. If it exists, tell the user:
> "Anvil is already configured for this project. Would you like to update the existing config or start fresh?"

If updating, read the current config and present it as the starting point.

### 2. Auto-Detect Stack

Scan the project root for build/config files to detect components:

| File | Language | Likely Test Runner |
|---|---|---|
| `pyproject.toml`, `setup.py`, `setup.cfg` | Python | pytest, unittest |
| `package.json` | JavaScript/TypeScript | jest, vitest, mocha |
| `Cargo.toml` | Rust | cargo test |
| `go.mod` | Go | go test |
| `pom.xml`, `build.gradle` | Java/Kotlin | JUnit, Maven Surefire |
| `Gemfile`, `*.gemspec` | Ruby | RSpec, Minitest |
| `mix.exs` | Elixir | ExUnit |
| `composer.json` | PHP | PHPUnit |
| `*.csproj`, `*.sln` | C#/.NET | dotnet test |

For each detected file, explore further:
- Read `package.json` for `scripts.test` to determine test command
- Read `pyproject.toml` for `[tool.pytest]` or `[tool.ruff]` sections
- Look at directory structure for source and test directories

### 3. Present Findings

Show the user what you found:
> "I detected a Python project with pytest (`src/` → `test/`) and a TypeScript frontend with vitest (`apps/web/src/` → `apps/web/tests/`). Sound right?"

### 4. Configure Components

For each component (detected or user-specified), confirm or ask:
- **Name** — short identifier (e.g., `api`, `frontend`, `worker`)
- **Language** — programming language
- **source_dir** — where source code lives
- **test_dir** — where tests live
- **test_pattern** — how test files map to source (e.g., `test/test_{module}.py`)
- **test_command** — command to run tests
- **build_command** (optional) — command to build/compile
- **lint_command** (optional) — command to run linter
- **type_check_command** (optional) — command to run type checker

### 5. Git Conventions

Ask:
- "What's your default branch? (main/master/develop)" — default: `main`
- "Branch prefix for feature work?" — default: `feature/`

### 6. Write Config

Create `docs/anvil/` directory if needed. Write `docs/anvil/config.yml`.

### 7. Next Steps

Check if `ROADMAP.md` exists at the project root:
- If no: suggest running `/anvil:roadmap` to create the project roadmap
- If yes: suggest running `/anvil:sprint <phase>` to create a sprint from an existing phase
