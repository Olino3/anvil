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

### 5. Create Worktree

Create an isolated worktree so the dev-agent's commits don't touch the sprint branch.

**Branch name:** `{sprint-branch}/dev/{ticket-id}`
Example: if the sprint branch is `feature/mvp` and the ticket is `MVP-001`, the worktree branch is `feature/mvp/dev/MVP-001`.

**Use the best available worktree mechanism, in priority order:**

1. **Superpowers skill (preferred):** If `superpowers:using-git-worktrees` is listed in the available skills, invoke it via the Skill tool. Pass the desired branch name. This handles directory selection, `.gitignore` verification, project setup, and test baseline automatically.

2. **Built-in EnterWorktree (fallback):** If the superpowers skill is not available, use the built-in `EnterWorktree` tool with the branch name. Note to the user:
   > "Using built-in worktree (superpowers:using-git-worktrees not available). Project setup and test baseline were skipped."

3. **Neither available (edge case):** Warn the user and offer:
   - Proceed without isolation (current behavior — commits go directly to the sprint branch)
   - Abort

After this step, the working directory is inside the worktree on the dev branch. All subsequent work happens here.

### 6. Dispatch dev-agent

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

### 7. Present Integration Options

After the dev-agent completes successfully, present the user with these options for integrating the work into the sprint branch:

> **How would you like to integrate this work into `{sprint-branch}`?**
>
> 1. **Squash merge** — Collapse all commits into one clean commit on the sprint branch. Best for clean history.
> 2. **Merge** — Bring all TDD commits as-is onto the sprint branch. Best for preserving RED/GREEN history.
> 3. **Create PR** — Push the branch and open a PR against the sprint branch. Best for team review.
> 4. **Keep worktree** — Leave the worktree and branch for continued work. Nothing is integrated yet.
> 5. **Discard** — Delete the worktree and all commits. Requires confirmation.

Wait for the user to choose before proceeding to Step 8.

### 8. Execute Integration and Cleanup

Execute the user's chosen option:

**Option 1 — Squash merge:**
```
git checkout {sprint-branch}
git merge --squash {worktree-branch}
git commit -m "feat({component}): implement {ticket-id} — {ticket title}"
```
Then remove the worktree and delete the dev branch:
- If worktree was created with `EnterWorktree`: use `ExitWorktree`
- If worktree was created with superpowers skill: `git worktree remove {path}` then `git branch -D {worktree-branch}`

**Option 2 — Merge:**
```
git checkout {sprint-branch}
git merge {worktree-branch}
```
Then remove worktree and delete dev branch (same cleanup as Option 1).

**Option 3 — Create PR:**
```
git push -u origin {worktree-branch}
gh pr create --base {sprint-branch} --head {worktree-branch} \
  --title "{ticket-id}: {ticket title}" \
  --body "## Summary\n- Implements {ticket-id}\n- {commit count} commits (RED/GREEN/REFACTOR)\n\n## Acceptance Criteria\n{checked criteria from ticket}\n\n## Verification\n{verification results from dev-agent}"
```
Keep the worktree alive — the user may push more commits.

**Option 4 — Keep worktree:**
No git operations. Report to the user:
> "Worktree kept at `{path}` on branch `{worktree-branch}` with {N} commits. Run `/anvil:develop` again or integrate manually when ready."

**Option 5 — Discard:**
Confirm with the user first:
> "This will delete the worktree and all {N} commits on `{worktree-branch}`. Are you sure?"

On confirmation, remove the worktree and delete the dev branch (same cleanup as Option 1). If the user declines, go back to Step 7 to choose again.

### 9. Post-Completion

After the dev-agent completes, the ticket and sprint README are already updated. No additional action needed.
