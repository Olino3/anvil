---
name: anvil-status
description: Read-only sprint status summary — print to stdout, no file writes, no agent dispatch
user-invocable: true
---

# Anvil Status

**Goal:** print a deterministic, read-only summary of one or all sprints. No
file is written, no agent is dispatched, no follow-up step is suggested
beyond the summary itself.

## Invocation

- Slash command: `/anvil-status [phase]`
- APM runtime: `apm run anvil-status` or `apm run anvil-status --param phase=<phase>`

## Arguments

- `phase` (optional, string) — sprint identifier matched against directory
  names under `docs/anvil/sprints/`. See Step 1 for matching rules. Omit to
  summarize every sprint.

## Schema reference

Tickets are read from the `ticket-template` schema (from
`anvil-common-stable`). Status and dependency fields appear as bold
markdown header lines at the top of each ticket file (not YAML frontmatter):

- `**Status:** {value}` — one of `Open`, `In Progress`, `Done`, `Blocked`.
  Anything else is treated as `Open` and noted in the malformed list, below.
- `**Depends on:** {markdown links | _(none)_}` — comma-separated
  markdown links to dependency tickets. The literal sentinel `_(none)_`
  means no dependencies. Ticket IDs are extracted from the link text or
  filename (`^([A-Z]+-\d+)`).
- `**Blocks:** {markdown links | _(none)_}` — same shape as `Depends on`,
  in the reverse direction. Read for completeness; not required by this
  skill's output.

## Constraints

- **Tools allowed:** `Glob`, `Read`, `Bash` (read-only commands like `ls`).
- **Tools forbidden:** `Write`, `Edit`, `NotebookEdit`, any mutating `Bash`.
- **Output destination:** the assistant message (stdout). No files written.
- **Termination:** after Step 4 the skill is complete; do not propose any
  follow-up step.

## Procedure

### 1. Locate sprint(s)

Use **Glob** on `docs/anvil/sprints/*` (directories only).

- `phase` provided → match it against directory names with this precedence
  (case-insensitive):
  1. **Exact** name.
  2. **Version prefix**.
  3. **Slug prefix**.
  On a tie at the same precedence level, list candidates and halt.
  On zero match, output verbatim and halt:

  > No sprint found for `{phase}`. Available sprints: {list}.

- `phase` omitted → process every sprint directory in **lexicographic
  order**.

If `docs/anvil/sprints/` does not exist or is empty, output verbatim and
halt:

> No sprints found under `docs/anvil/sprints/`. Run `/anvil-sprint <phase>` to create one.

### 2. Read ticket files

For each sprint, use **Glob** to enumerate `*.md` files in the directory,
then **Read** each. Exclude:

- `README.md`
- `BA-REPORT.md`
- Any other non-ticket file (e.g., `CHANGELOG.md`, `NOTES.md`).

A ticket is identified by a `**Status:**` bold-markdown header line near
the top of the file. Files without that line are skipped and noted in
the malformed list.

For each ticket, extract: ID (from filename, `^([A-Z]+-\d+)`), title
(first `# ` heading), status (canonical, see schema), component
(`**Component:**` line), dependencies (`**Depends on:**` line, ticket
IDs parsed from each markdown link).

### 3. Compute status

For each sprint, compute:

- Counts by status: `Done`, `In Progress`, `Open`, `Blocked`.
- **Unblockable**: a ticket whose `status = Blocked` AND every dependency
  has `status = Done`. (Ready to move to `Open` or `In Progress`.)
- Progress percentage: `Done / Total`, rounded to nearest integer.
- Malformed tickets: any with missing/unrecognized `**Status:**` line or
  unresolved `**Depends on:**` ticket IDs.

### 4. Output

Print one block per sprint, separated by a blank line, in the order from
Step 1. Use this exact shape:

```
Sprint: {Name} ({version})
Progress: {done}/{total} done ({pct}%)

  Done:        {comma-separated ticket IDs, or "—"}
  In Progress: {comma-separated ticket IDs, or "—"}
  Open:        {comma-separated ticket IDs, or "—"}
  Blocked:     {ID (waiting on UNFINISHED-DEPS), ...} or "—"
  Unblockable: {ID (blockers all Done), ...} or "—"
  Malformed:   {ID (reason), ...} or "—"
```

Then stop. The skill is complete.

## Failure modes

Halt and report — never partially summarize:

- `phase` matched zero or multiple sprints (Step 1).
- A sprint directory is unreadable (Step 2).
- Circular dependency detected during the unblockable check (Step 3) —
  report the cycle and continue with the remaining sprints.
