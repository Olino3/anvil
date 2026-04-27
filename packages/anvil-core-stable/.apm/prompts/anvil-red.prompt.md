---
description: Write the complete failing test suite (all acceptance criteria, happy + edge) for a sprint ticket. Whole-ticket scope.
input:
  - ticket: "Ticket ID (e.g., MVP-001)"
---

# Anvil RED

Invoke the `@red` agent for ticket `${input:ticket}`. The agent reads the
ticket, enumerates every acceptance criterion, writes happy-path and
edge-case tests per criterion, confirms each test fails because the
production code is missing or unimplemented (not because of syntax,
import, or configuration errors), and commits exactly once.

If the ticket has zero acceptance criteria or any criterion is ambiguous,
halt and report the missing or ambiguous items. Do not invent criteria.

Commit message (`{scope}` is the ticket's `Component:` field, verbatim):

```
test({scope}): add failing tests for ${input:ticket} acceptance criteria
```

Constraints: exactly one commit; do not amend or create follow-ups. If any
test passes, halt and report the passing test name and the criterion it
covers (this signals wrong scope or pre-existing implementation).

Report: the commit SHA and the test file path(s) added or modified.
