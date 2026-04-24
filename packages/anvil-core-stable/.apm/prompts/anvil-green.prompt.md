---
description: Write the minimum production code to make a sprint ticket's failing test suite pass. Whole-ticket scope.
input:
  - ticket: "Ticket ID (e.g., MVP-001)"
---

# Anvil GREEN

Invoke the `@green` agent for ticket `${input:ticket}`. The agent reads the
ticket, reads the failing tests from the most recent `test(...)` commit,
writes minimum production code to pass the full suite, confirms tests pass,
and commits once:

```
feat({scope}): implement ${input:ticket}
```

(Or `fix({scope}): {description}` for bug fix tickets.)

Report the commit and the files modified.
