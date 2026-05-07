---
description: Worktree isolation discipline — creation, branch naming, and integration-choice matrix for sprint ticket work.
applyTo: "**/*"
author: Olino3
version: "2.1.0"
---

# Worktree Discipline

## Activation

This instruction is **active** when any of the following hold:

- A skill that drives ticket implementation (e.g., `/develop`, `/tdd`) is invoked.
- The user's prompt references a ticket ID matching `[A-Z]+-[0-9]+`.
- You are about to make a code commit on a recognized sprint branch (see *Worktree creation*).

Outside those conditions this instruction is inert.

## Worktree creation

### Step 1 — Gather context

Run both commands and record the output:

```
git branch --show-current
git rev-parse --show-toplevel
```

### Step 2 — Decide whether to skip creation

Skip creation (you are already inside a worktree) when **all** the following are true:

1. Current branch matches the regex `^feature/[a-z0-9-]+-[A-Z]+-[0-9]+$` (i.e., `feature/{sprint-slug}-{TICKET-ID}`).
2. The path from `git rev-parse --show-toplevel` contains the segment `.worktrees/`.

If both conditions hold, proceed directly to ticket work. Otherwise, create a worktree per Step 3.

### Step 3 — Create the worktree

1. **Determine the sprint branch.** This is the branch you were on when the user invoked the ticket-driving skill (e.g., `/develop`). It typically matches `feature/<sprint-slug>` (see `commit-conventions.instructions.md` for branch naming).
2. **Derive `{sprint-slug}`.** Strip the leading `feature/` prefix from the sprint branch. Example: sprint branch `feature/mvp` → `{sprint-slug}` = `mvp`.
3. **Construct the worktree branch name:** `feature/{sprint-slug}-{TICKET-ID}`. Example: sprint `feature/mvp` + ticket `MVP-001` → `feature/mvp-MVP-001`.
4. **Construct the worktree path:** `.worktrees/{TICKET-ID}` relative to git root.
5. **Pre-flight checks** (halt with a clear message if any fail):
   - Current branch has no uncommitted changes that would be left behind. If it does, halt and ask the user to commit, stash, or discard them.
   - The path `.worktrees/{TICKET-ID}` does not already exist. If it does, halt and emit: `Worktree path already exists: .worktrees/{TICKET-ID}. Resume work there, or discard it first with: git worktree remove .worktrees/{TICKET-ID}`.
   - The branch `feature/{sprint-slug}-{TICKET-ID}` does not already exist locally or on any remote. If it does, halt and ask the user whether to check out the existing branch into a new worktree (swap `-b` for no flag) or choose a different ticket ID.
6. **Prepare `.worktrees/`:**
   - If `.worktrees/` does not exist at git root, create it.
   - Add `.worktrees/` to `.gitignore` if not already present.
7. **Create the worktree:**
   ```
   git worktree add .worktrees/{TICKET-ID} -b feature/{sprint-slug}-{TICKET-ID}
   ```
8. **Change working directory into the worktree** (absolute path is fine; relative to git root also works).
9. **Inform the user:** `Created worktree at .worktrees/{TICKET-ID} on branch feature/{sprint-slug}-{TICKET-ID}.`

### If the agent cannot determine a sprint branch

If the current branch does not match a recognized sprint pattern (`feature/<sprint-slug>`), halt and ask the user to specify the sprint branch. Do not invent one.

## Never commit directly to the sprint branch

Before any commit, verify the current branch is not the sprint branch. If it is, halt and invoke *Worktree creation* above. Always work through a worktree.

## Integration choice after ticket completion

At the end of a ticket (end of REFACTOR, or end of GREEN if no refactor), present the user with the five integration options below.

### Placeholder derivation

The commit-message and PR templates below reference these placeholders. Derive them as follows:

- `{TICKET-ID}` — from the worktree branch name (the suffix after the last sprint-slug component).
- `{sprint-branch}` — the sprint branch this worktree was created from.
- `{worktree-branch}` — the current branch (`feature/{sprint-slug}-{TICKET-ID}`).
- `{component}` — the primary directory changed in this worktree's commits. If changes span multiple directories, use the one with the largest share of changes. Cross-cutting → `repo` (matches `commit-conventions.instructions.md` scope rules).
- `{title}` — the sprint ticket's human-readable title. Read it from the sprint README / ticket file on the sprint branch. If not available, use the ticket ID alone (omit the ` — {title}` segment).

### Prompt format

Emit exactly:

```
Ticket {TICKET-ID} complete. Select integration option (1-5):
  1. Squash merge    — clean sprint-branch history
  2. Merge           — preserve RED/GREEN history
  3. Create PR       — team review before merge
  4. Keep worktree   — iterate more before integrating
  5. Discard         — implementation was wrong (requires explicit 'yes')
```

Wait for the user's numeric selection.

### Option table

| Option | When to use | Effect |
|---|---|---|
| 1. Squash merge | Clean sprint-branch history | `git checkout {sprint-branch} && git merge --squash {worktree-branch} && git commit -m "feat({component}): implement {TICKET-ID} — {title}"`; then `git worktree remove .worktrees/{TICKET-ID}` and `git branch -D {worktree-branch}` |
| 2. Merge | Preserve RED/GREEN history | `git checkout {sprint-branch} && git merge {worktree-branch}`; then remove worktree + delete dev branch |
| 3. Create PR | Team review before merge | `git push -u origin {worktree-branch}` and `gh pr create --base {sprint-branch} --head {worktree-branch} --title "feat({component}): {TICKET-ID} — {title}" --fill`; keep the worktree alive |
| 4. Keep worktree | Iterate more before integrating | No git operations; worktree stays |
| 5. Discard | Implementation was wrong | Require explicit `yes` confirmation (see below). Then remove worktree + delete dev branch |

### Discard confirmation state machine

When the user selects option 5:

1. Emit exactly: `Confirm discard of {TICKET-ID}? Type 'yes' to proceed.`
2. If input is exactly `yes` (case-insensitive, trimmed) → run `git worktree remove .worktrees/{TICKET-ID}` then `git branch -D {worktree-branch}`.
3. On any other input → return to the five-option menu. Do NOT re-prompt for confirmation; the user must select again.

### Non-interactive fallback

If no user is available to select an option (e.g., autonomous pipeline, no stdin), default to **Option 4 (Keep worktree)** and emit a next-steps summary:

```
Ticket {TICKET-ID} complete. Worktree retained at .worktrees/{TICKET-ID} on branch {worktree-branch}.
Next steps (run manually when ready):
  - Squash merge:  git checkout {sprint-branch} && git merge --squash {worktree-branch} && git commit -m "feat({component}): implement {TICKET-ID} — {title}"
  - Merge:         git checkout {sprint-branch} && git merge {worktree-branch}
  - Create PR:     gh pr create --base {sprint-branch} --head {worktree-branch} --fill
  - Discard:       git worktree remove .worktrees/{TICKET-ID} && git branch -D {worktree-branch}
```

NEVER default to a destructive option (1, 2, 5) when non-interactive.

## Cleanup rules

- Options 1, 2, 5: worktree directory removed, dev branch deleted.
- Options 3, 4: worktree and dev branch kept. Sprint README on the sprint branch will not show the ticket as Done until eventual merge.
