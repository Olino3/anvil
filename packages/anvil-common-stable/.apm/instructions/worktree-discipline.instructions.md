---
description: Worktree isolation discipline — creation, branch naming, and integration-choice matrix for sprint ticket work.
applyTo: "**/*"
author: Olino3
version: "2.0.0"
---

# Worktree Discipline

This instruction applies when implementing a sprint ticket or about to
start or finish ticket work. When that is not the case, this instruction
is inert.

## Worktree creation

1. Check current branch. Run `git branch --show-current` and `git rev-parse --show-toplevel`.
2. If already in a worktree (branch name matches `*/dev/*` OR `feature/*-*-[A-Z]+-[0-9]+`, and path contains `.worktrees/`), skip creation.
3. Otherwise:
   a. Determine the sprint branch from the current branch name (the branch you are on when invoking develop).
   b. Worktree branch name: `feature/{sprint-slug}-{ticket-id}`, where `{sprint-slug}` is the sprint branch with any leading `feature/` prefix stripped. Example: sprint branch `feature/mvp`, ticket `MVP-001` → sprint-slug `mvp` → worktree branch `feature/mvp-MVP-001`.
   c. Worktree path: `.worktrees/{ticket-id}` relative to git root.
   d. If `.worktrees/` does not exist, create it. Add `.worktrees/` to `.gitignore` if not already present.
   e. Create: `git worktree add .worktrees/{ticket-id} -b feature/{sprint-slug}-{ticket-id}`
   f. Change working directory into the worktree.
   g. Inform the user: "Created worktree at `.worktrees/{ticket-id}` on branch `feature/{sprint-slug}-{ticket-id}`."

## Never commit directly to the sprint branch

Always work through a worktree. If you find yourself about to commit to the sprint branch, stop and create a worktree first.

## Integration choice after ticket completion

At the end of a ticket (end of REFACTOR, or end of GREEN if no refactor), present the user with five options for integrating the worktree's commits:

| Option | When to use | Effect |
|---|---|---|
| 1. Squash merge | Clean sprint-branch history | `git checkout {sprint-branch} && git merge --squash {worktree-branch} && git commit -m "feat({component}): implement {ticket-id} — {title}"`; then `git worktree remove .worktrees/{ticket-id}` and `git branch -D {worktree-branch}` |
| 2. Merge | Preserve RED/GREEN history | `git checkout {sprint-branch} && git merge {worktree-branch}`; then remove worktree + delete dev branch |
| 3. Create PR | Team review before merge | `git push -u origin {worktree-branch}` and `gh pr create --base {sprint-branch} --head {worktree-branch}`; keep the worktree alive |
| 4. Keep worktree | Iterate more before integrating | No git operations; worktree stays |
| 5. Discard | Implementation was wrong | Require explicit "yes" confirmation. Then remove worktree + delete dev branch |

## Cleanup rules

- Options 1, 2, 5: worktree directory removed, dev branch deleted.
- Options 3, 4: worktree and dev branch kept. Sprint README on the sprint branch will not show the ticket as Done until eventual merge.
