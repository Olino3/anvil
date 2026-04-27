---
name: anvil-init
description: Interactive project setup — detect tech stack, configure components, write docs/anvil/config.yml
user-invocable: true
---

# Anvil Init

**Goal:** produce a valid `docs/anvil/config.yml` via interactive confirmation
of the detected stack.

## Invocation

- Slash command: `/anvil-init`
- APM runtime: `apm run anvil-init`

## Schema reference

`docs/anvil/config.yml` MUST conform to the `anvil-config-schema` skill (from
`anvil-common-stable`). Do not introduce keys or types the schema does not
define. Read that skill before producing the file.

## Procedure

### 1. Check existing config

Use **Read** on `docs/anvil/config.yml`.

- If the file does not exist → set `mode = fresh`, continue to Step 2.
- If the file exists → ask the user to choose one of:
  - `update` — load current values and use them as defaults in later steps.
  - `fresh` — discard current values and start over (will overwrite on save).
  - `abort` — stop the skill and exit.

  Halt until the user picks one. Default to `update` only if the user replies
  with anything ambiguous.

### 2. Auto-detect stack

Use **Glob** at the project root to look for the build/config files in the
table below. For each match, use **Read** to extract more detail (test
command, source/test directories).

| File | Language | Likely test runner |
|---|---|---|
| `pyproject.toml`, `setup.py`, `setup.cfg` | Python | pytest, unittest |
| `package.json` | JavaScript / TypeScript | jest, vitest, mocha |
| `Cargo.toml` | Rust | cargo test |
| `go.mod` | Go | go test |
| `pom.xml`, `build.gradle` | Java / Kotlin | JUnit, Maven Surefire |
| `Gemfile`, `*.gemspec` | Ruby | RSpec, Minitest |
| `mix.exs` | Elixir | ExUnit |
| `composer.json` | PHP | PHPUnit |
| `*.csproj`, `*.sln` | C# / .NET | dotnet test |

If nothing matches (e.g., Zig, Nim, custom build), set `detected = []` and ask
the user to enter one or more components manually in Step 4.

### 3. Present findings

Tell the user, in plain prose, what you detected. Use this template:

> Detected: `<language>` component in `<source_dir>` using `<test_command>`.
> Confirm or correct.

Halt for confirmation before continuing.

### 4. Configure components

Confirm the following fields per component in **a single batched prompt**
(not one prompt per field), unless the user asked for per-field review.

Required fields:

- **name** — short identifier (e.g., `api`, `frontend`, `worker`).
- **language** — open-valued string; use the table value when detected.
- **source_dir** — relative path to source.
- **test_dir** — relative path to tests.
- **test_pattern** — how test files map to source (e.g., `test/test_{module}.py`).
- **test_command** — shell command that runs the test suite.

Optional fields (omit if unknown — do not invent):

- **build_command**
- **lint_command**
- **type_check_command**

### 5. Git conventions

Ask, batched in one prompt:

- Default branch (`main` / `master` / `develop`) — default `main`.
- Branch prefix for feature work — default `feature/`.

### 6. Write config

1. Use **Bash** `mkdir -p docs/anvil` if the directory does not exist.
2. Use **Write** to create or overwrite `docs/anvil/config.yml`.
3. Use **Read** to load the file back and verify the required keys for each
   component are present (`name`, `language`, `source_dir`, `test_dir`,
   `test_pattern`, `test_command`) plus the top-level `git` block.
4. If validation fails, report which keys are missing and halt without
   continuing to Step 7.

Re-running the skill against the same repo MUST yield a structurally
equivalent file (idempotent).

### 7. Next step

Choose one branch based on the project state:

- No `ROADMAP.md` at the project root → suggest `/anvil-roadmap`.
- `ROADMAP.md` exists, `docs/anvil/sprints/` is empty or missing → suggest
  `/anvil-sprint <phase>`.
- `ROADMAP.md` and at least one sprint exist → suggest `/anvil-status`.

### 8. Completion contract

Emit as the final assistant message, exactly one of:

- `docs/anvil/config.yml created. Next: <suggestion from Step 7>.`
- `docs/anvil/config.yml updated. Next: <suggestion from Step 7>.`

Then stop. Do not invoke any other skill or volunteer follow-up work.

## Failure modes

Halt and report the cause; do not produce a partial config:

- User chose `abort` in Step 1.
- No stack detected and the user declined manual entry.
- Required field omitted in Step 4.
- Write failed (permission denied, disk full).
- Validation in Step 6 found missing keys.
