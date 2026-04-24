---
description: Write the complete failing test suite (all acceptance criteria, happy + edge) for a sprint ticket. Whole-ticket scope.
input:
  - ticket: "Ticket ID (e.g., MVP-001)"
---

# Anvil RED

Invoke the `@red` agent for ticket `${input:ticket}`. The agent reads the
ticket, enumerates every acceptance criterion, writes happy-path and
edge-case tests per criterion, confirms they fail for the right reason, and
commits once:

```
test({scope}): add failing tests for ${input:ticket} acceptance criteria
```

Report the commit and the test file path(s).
