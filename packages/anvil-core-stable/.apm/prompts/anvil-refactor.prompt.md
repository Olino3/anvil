---
description: Optional refactor step after GREEN. Clean up the implementation without changing behavior. Presents integration-choice matrix at completion.
input:
  - ticket: "Ticket ID (e.g., MVP-001)"
---

# Anvil REFACTOR

Clean up the implementation of ticket `${input:ticket}` without changing
behavior.

`{scope}` is the ticket's `Component:` field, verbatim. `{description}` is
an imperative summary ≤72 chars (e.g., `extract token validation`).
`test_command` is the component's test command in `docs/anvil/config.yml`.

## Procedure

1. **Read the ticket** to understand scope.
2. **Read the GREEN commit's diff** (the most recent `feat(...)` or `fix(...)` commit on the current branch). Identify code smells: duplication, unclear names, dead code, leaky abstractions.
3. **Refactor (conditional).**
   - **If smells were identified in step 2:** make the changes. Run `test_command` after each change; if any test fails, revert that change. Commit:
     ```
     refactor({scope}): {description}
     ```
   - **If no smells were identified:** skip to step 4 without committing.
4. **Update ticket and sprint README.** Set the ticket's `Status:` to `Done`, check off satisfied acceptance criteria, and update the sprint README's tickets table and status summary.
5. **Present the integration-choice matrix** from `anvil-common-stable/.apm/instructions/worktree-discipline.instructions.md`: squash merge / merge / PR / keep worktree / discard. Wait for the user's choice; do not infer one.
6. **Execute the chosen option** per `worktree-discipline` for git operations and cleanup.

## Constraints

- Behavior-preserving only. If `test_command` fails after a change, revert that change.
- No sub-agent dispatch. Execute all steps in this session within the existing worktree.
- Do not edit tests in this step — refactor production code only.
