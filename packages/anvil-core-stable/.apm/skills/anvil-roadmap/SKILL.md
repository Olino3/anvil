---
name: anvil-roadmap
description: Create or update the project ROADMAP.md by invoking the pd agent for strategic planning
user-invocable: true
---

# Anvil Roadmap

## Invocation

- Slash command: `/anvil:roadmap`
- APM runtime: `apm run anvil:roadmap`
- Agent mention: `@pd`

Create or update the project's ROADMAP.md through collaborative planning.

## Arguments

- None required. The `@pd` agent will converse with the user to understand what's needed.

## Procedure

### 1. Verify Config

Read `docs/anvil/config.yml`. If it doesn't exist:
> "Anvil isn't configured for this project yet. Run `/anvil:init` first to set up the project config."

Stop and wait for the user.

### 2. Check Existing ROADMAP

Check if `ROADMAP.md` exists at the project root. Pass this information to the `@pd` agent.

### 3. Invoke pd agent

Invoke `@pd` (where supported) or run `apm run anvil:roadmap` with:
- The contents of `docs/anvil/config.yml`
- The contents of `ROADMAP.md` (if it exists)
- Whether this is a create or update operation

The agent will converse with the user and write/update `ROADMAP.md`.

### 4. Commit

After the `@pd` agent completes:

If new ROADMAP:
```
git add ROADMAP.md
git commit -m "docs(roadmap): create project roadmap"
```

If updated:
```
git add ROADMAP.md
git commit -m "docs(roadmap): update roadmap phases"
```
