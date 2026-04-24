---
description: Optional refactor step after GREEN. Clean up the implementation without changing behavior. Presents integration-choice matrix at completion.
input:
  - ticket: "Ticket ID (e.g., MVP-001)"
---

# Anvil REFACTOR

Clean up the implementation of ticket `${input:ticket}` without changing
behavior.

## Procedure

1. **Read the ticket** to understand scope.
2. **Read the GREEN commit's diff.** Identify code smells, duplication, unclear names.
3. **If refactor is warranted:** make the changes. Run the component's `test_command` after each change to confirm all tests still pass. Commit:
   ```
   refactor({scope}): {description}
   ```
   If no refactor is warranted, skip to step 4 without committing anything.
4. **Update ticket and sprint README.** Set the ticket's Status to `Done`, check satisfied acceptance criteria, update the sprint README's tickets table and status summary.
5. **Present the integration-choice matrix** from `worktree-discipline` (from anvil-common-stable): squash merge / merge / PR / keep worktree / discard.
6. **Execute the chosen option.** Follow `worktree-discipline` for git operations and cleanup.

## Constraints

- Behavior-preserving only. If tests fail, revert the refactor.
- No dispatch — this prompt is self-contained discipline.
