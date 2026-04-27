---
description: Write the minimum production code to make a sprint ticket's failing test suite pass. Whole-ticket scope.
input:
  - ticket: "Ticket ID (e.g., MVP-001)"
---

# Anvil GREEN

Invoke the `@green` agent for ticket `${input:ticket}`. The agent reads
the ticket, reads the failing tests from the most recent `test(...)`
commit on the current branch, writes minimum production code to pass the
full suite, confirms every test passes, and commits exactly once.

Precondition: a RED commit (`test({scope}): ...`) must exist on the
current branch. If none is found, halt and report. Do not write tests in
this prompt — modify production code only.

Commit message (`{scope}` is the ticket's `Component:` field, verbatim):

```
feat({scope}): implement ${input:ticket}
```

Use `fix({scope}): {description}` for bug-fix tickets, where `{description}`
is an imperative summary ≤72 chars.

Constraints: exactly one commit; do not amend, do not edit test files, do
not skip or delete tests. If any test still fails after implementation, do
not commit — halt and report the failing test names.

Report: the commit SHA and the files modified.
