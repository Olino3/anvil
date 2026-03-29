---
name: develop
description: Implement a single sprint ticket using TDD by dispatching the dev-agent with RED/GREEN sub-agents
user-invocable: true
---

# Anvil Develop

Implement a single sprint ticket.

## Arguments

- `ticket-id` (required) — the ticket to implement (e.g., `MVP-001`, `AUTH-003`, `SPIKE-002`)

## Procedure

### 1. Locate Ticket

Search `docs/anvil/sprints/` for a file matching `{ticket-id}*.md`. If not found:
> "Could not find ticket `{ticket-id}` in any sprint directory under `docs/anvil/sprints/`."

If found in multiple sprints (unlikely but possible), ask the user which one.

### 2. Verify Config

Read `docs/anvil/config.yml`. The dev-agent needs this for component test/build commands.

### 3. Read Sprint Context

Read the sprint's `README.md` to understand:
- Which branch to work on
- Dependency state of all tickets
- Current sprint progress

### 4. Verify Branch

Check that the current git branch matches the sprint's Branch field. If not:
> "You're on branch `{current}` but this sprint expects `{expected}`. Switch branches first?"

### 5. Dispatch dev-agent

Dispatch the `dev-agent` with:
- The ticket file path and contents
- The sprint README path and contents
- The contents of `docs/anvil/config.yml`
- The sprint directory path (for creating SPIKEs)

The dev-agent will:
1. Check dependencies
2. Create and present an implementation plan
3. Wait for user approval
4. Execute via RED/GREEN sub-agents
5. Update ticket status and sprint README

### 6. Post-Completion

After the dev-agent completes, the ticket and sprint README are already updated. No additional action needed.
