# APM-First Marketplace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the Anvil repo as an APM-first monorepo of three packages (anvil-common-stable, anvil-core-stable, anvil-orchestrator-stable), replacing today's Claude-first plugin layout in a v2.0.0 hard cut.

**Architecture:** Monorepo under `packages/`, each package authored as `.apm/{agents,skills,prompts,instructions}` and compiled via `apm install` to Claude Code, Copilot CLI, Cursor, OpenCode. Common is shared via transitive dep; orchestrator depends on common + core and overrides core's stage-entry prompts by last-writer-wins at compiled paths. Slash commands come from prompt compilation — no separate `.apm/commands/` directory.

**Tech Stack:** Microsoft APM (0.9.0+), markdown-with-frontmatter primitives, git worktrees, GitHub Actions for release CI. No code generation, no build tools beyond APM itself. Spec at `shared/specs/2026-04-23-apm-first-marketplace-design.md`.

---

## Spec Reference

Before starting any task, read `shared/specs/2026-04-23-apm-first-marketplace-design.md` end-to-end. The plan below implements that spec literally. When a task says "per spec §X," that section is the source of truth.

## File Responsibility Map

This is the target layout after v2.0.0 ships. Tasks below create or modify each file in the order they're needed.

| Path | Responsibility | Comes from |
|---|---|---|
| `marketplace.json` | Registers the three packages; `anvil-common-stable` flagged internal | new (replaces `.claude-plugin/marketplace.json`) |
| `apm.yml` (root) | Workspace metadata for contributors running APM at repo root | new (replaces the comment-only shim) |
| `packages/anvil-common-stable/apm.yml` | Package manifest: name, version, description, empty deps | new |
| `packages/anvil-common-stable/.apm/instructions/commit-conventions.instructions.md` | Always-loaded commit message discipline | port of `plugins/anvil/skills/reference/commit-conventions.md` |
| `packages/anvil-common-stable/.apm/instructions/tdd-discipline.instructions.md` | Always-loaded RED/GREEN/REFACTOR discipline | port of `plugins/anvil/skills/tdd/SKILL.md` |
| `packages/anvil-common-stable/.apm/instructions/worktree-discipline.instructions.md` | Always-loaded worktree creation + integration-choice rules | extracted from `plugins/anvil/agents/dev-agent.agent.md` Phase 0 + `commands/develop.md` Steps 5, 7, 8 |
| `packages/anvil-common-stable/.apm/skills/roadmap-format/SKILL.md` | Reference for ROADMAP.md structure | port of `plugins/anvil/skills/reference/roadmap-format.md` |
| `packages/anvil-common-stable/.apm/skills/sprint-readme-format/SKILL.md` | Reference for sprint README structure | port of `plugins/anvil/skills/reference/sprint-readme-format.md` |
| `packages/anvil-common-stable/.apm/skills/ticket-template/SKILL.md` | Reference for ticket file structure | port of `plugins/anvil/skills/reference/ticket-template.md` |
| `packages/anvil-common-stable/.apm/skills/ba-report-format/SKILL.md` | Reference for BA-REPORT.md structure | port of `plugins/anvil/skills/reference/report-format.md` |
| `packages/anvil-common-stable/.apm/skills/anvil-config-schema/SKILL.md` | Reference for `docs/anvil/config.yml` schema | new (extracted from `plugins/anvil/skills/init/SKILL.md`) |
| `packages/anvil-core-stable/apm.yml` | Package manifest; depends on common; declares `anvil:<stage>` scripts | new |
| `packages/anvil-core-stable/.apm/agents/red.agent.md` | Whole-ticket failing-test persona | port of `plugins/anvil/agents/red-agent.agent.md`, rescoped to "all acceptance criteria + edge cases in one invocation" |
| `packages/anvil-core-stable/.apm/agents/green.agent.md` | Whole-ticket minimum-implementation persona | port of `plugins/anvil/agents/green-agent.agent.md`, rescoped to "make the full failing suite pass" |
| `packages/anvil-core-stable/.apm/agents/dev-discipline.agent.md` | Plan-and-approve persona; no dispatch | new (replaces the planning phases of today's `dev-agent.agent.md`) |
| `packages/anvil-core-stable/.apm/agents/pd.agent.md` | Roadmap author | port of `plugins/anvil/agents/pd-agent.agent.md` |
| `packages/anvil-core-stable/.apm/agents/pm.agent.md` | Sprint generator | port of `plugins/anvil/agents/pm-agent.agent.md` |
| `packages/anvil-core-stable/.apm/agents/ba.agent.md` | Sprint health + verification | port of `plugins/anvil/agents/ba-agent.agent.md`, with autonomous-cleanup paragraphs removed (orchestrator adds that) |
| `packages/anvil-core-stable/.apm/agents/sprint-syncer.agent.md` | Sprint README rebuild | port of `plugins/anvil/agents/sprint-syncer-agent.agent.md` |
| `packages/anvil-core-stable/.apm/skills/anvil-init/SKILL.md` | When/how to initialize an Anvil project | port of `plugins/anvil/skills/init/SKILL.md` |
| `packages/anvil-core-stable/.apm/skills/anvil-roadmap/SKILL.md` | When/how to use `pd.agent` | port of `plugins/anvil/skills/roadmap/SKILL.md` |
| `packages/anvil-core-stable/.apm/skills/anvil-sprint/SKILL.md` | When/how to use `pm.agent` | port of `plugins/anvil/skills/sprint/SKILL.md` |
| `packages/anvil-core-stable/.apm/skills/anvil-develop/SKILL.md` | Ticket implementation discipline (plan-then-red-then-green-then-refactor) | port of `plugins/anvil/skills/develop/SKILL.md`, rewritten for "plan-and-stop" behavior |
| `packages/anvil-core-stable/.apm/skills/anvil-review/SKILL.md` | When/how to use `ba.agent` | port of `plugins/anvil/skills/review/SKILL.md` |
| `packages/anvil-core-stable/.apm/skills/anvil-sync/SKILL.md` | When/how to rebuild sprint README | port of `plugins/anvil/skills/sync/SKILL.md` |
| `packages/anvil-core-stable/.apm/skills/anvil-status/SKILL.md` | Read-only status summary | port of `plugins/anvil/skills/status/SKILL.md` |
| `packages/anvil-core-stable/.apm/prompts/anvil-init.prompt.md` | `/anvil:init` entry point | new, invokes `anvil-init` skill |
| `packages/anvil-core-stable/.apm/prompts/anvil-roadmap.prompt.md` | `/anvil:roadmap` entry point | new, invokes `pd.agent` |
| `packages/anvil-core-stable/.apm/prompts/anvil-sprint.prompt.md` | `/anvil:sprint <phase>` entry point | new, invokes `pm.agent`; `input: [phase]` |
| `packages/anvil-core-stable/.apm/prompts/anvil-develop.prompt.md` | `/anvil:develop <ticket>` — locate, verify deps, auto-worktree, plan, stop | new, wraps Phase 0 of today's dev-agent + `dev-discipline.agent` planning |
| `packages/anvil-core-stable/.apm/prompts/anvil-plan-ticket.prompt.md` | Standalone plan-for-a-ticket (used by develop.prompt.md and available directly) | new, invokes `dev-discipline.agent` |
| `packages/anvil-core-stable/.apm/prompts/anvil-red.prompt.md` | `/anvil:red <ticket>` — whole-ticket failing suite | new, invokes `red.agent` |
| `packages/anvil-core-stable/.apm/prompts/anvil-green.prompt.md` | `/anvil:green <ticket>` — whole-ticket minimum code | new, invokes `green.agent` |
| `packages/anvil-core-stable/.apm/prompts/anvil-refactor.prompt.md` | `/anvil:refactor <ticket>` — self-contained refactor discipline | new, no dedicated agent |
| `packages/anvil-core-stable/.apm/prompts/anvil-review.prompt.md` | `/anvil:review <phase>` entry point | new, invokes `ba.agent` |
| `packages/anvil-core-stable/.apm/prompts/anvil-sync.prompt.md` | `/anvil:sync <phase>` entry point | new, invokes `sprint-syncer.agent` |
| `packages/anvil-core-stable/.apm/prompts/anvil-status.prompt.md` | `/anvil:status [phase]` entry point | new, read-only |
| `packages/anvil-orchestrator-stable/apm.yml` | Package manifest; depends on common + core; declares four override scripts | new |
| `packages/anvil-orchestrator-stable/.apm/agents/develop-orchestrator.agent.md` | Plan → RED → GREEN → REFACTOR → integration, single-level dispatch | new, replaces today's `dev-agent` flow with dispatch flattened |
| `packages/anvil-orchestrator-stable/.apm/agents/sprint-orchestrator.agent.md` | `pm` → optional one-ticket handoff | new |
| `packages/anvil-orchestrator-stable/.apm/agents/roadmap-orchestrator.agent.md` | `pd` → optional sprint handoff | new |
| `packages/anvil-orchestrator-stable/.apm/agents/review-orchestrator.agent.md` | `ba` → auto-apply cleanup with single approval | new |
| `packages/anvil-orchestrator-stable/.apm/skills/orchestration-gates/SKILL.md` | When to pause for approval; how to resume | new |
| `packages/anvil-orchestrator-stable/.apm/prompts/anvil-develop.prompt.md` | Overrides core; full inner loop | new |
| `packages/anvil-orchestrator-stable/.apm/prompts/anvil-sprint.prompt.md` | Overrides core; generates sprint, offers one-ticket handoff | new |
| `packages/anvil-orchestrator-stable/.apm/prompts/anvil-roadmap.prompt.md` | Overrides core; offers sprint handoff | new |
| `packages/anvil-orchestrator-stable/.apm/prompts/anvil-review.prompt.md` | Overrides core; auto-applies cleanup | new |
| `shared/Workflows.md` | Rewritten playbook for three-package model | rewrite of existing `Workflows.md` |
| `shared/CONTRIBUTING.md` | How to work on Anvil locally (apm install from packages/*) | new |
| `README.md` | Rewritten; v1→v2 mapping; install paths for both packages; .gitignore guidance | rewrite |
| `.github/workflows/release.yml` | Builds 8 plugin bundles, creates release | new (if repo has no existing release workflow to extend) |

**Deleted in the migration:** `plugins/anvil/` (entire tree), `.claude-plugin/marketplace.json`, current `apm.yml` (comment-only shim), current `Workflows.md`.

**Branch naming scheme for worktrees (per spec, user-revised):** `feature/{sprint-branch}-{ticket-id}` (not `{sprint-branch}/dev/{ticket-id}`). Carry this through every place it appears.

---

## Phase 0 — De-risk and set up the implementation branch

The spec flags three risks. Two of them (APM install ordering, OpenCode/Copilot dispatch) block the orchestrator design if they don't behave. Verify them before authoring orchestrator content.

### Task 0.1: Create implementation branch and scratch project

**Files:**
- Create branch: `v2.0.0-alpha` off `develop`
- Create: `/tmp/anvil-v2-scratch/` (outside the repo; a disposable APM project for integration testing)

- [ ] **Step 1: Create the implementation branch**

```bash
cd /var/home/olino3/git/anvil
git checkout develop
git pull --ff-only
git checkout -b v2.0.0-alpha
```

Expected: `git branch --show-current` prints `v2.0.0-alpha`.

- [ ] **Step 2: Create a scratch APM project for integration testing**

```bash
mkdir -p /tmp/anvil-v2-scratch
cd /tmp/anvil-v2-scratch
git init
apm init --yes
```

Expected: `/tmp/anvil-v2-scratch/apm.yml` exists.

- [ ] **Step 3: Commit the branch point**

```bash
cd /var/home/olino3/git/anvil
git commit --allow-empty -m "chore: begin v2.0.0 APM-first migration"
```

Expected: `git log -1 --format=%s` prints the commit subject.

### Task 0.2: Verify APM install ordering and override behavior (Risk #1)

**Files:**
- Create in scratch: `/tmp/anvil-v2-risk-1/` (second scratch project just for this test)

The spec assumes that when two packages deploy to the same compiled path, the deeper-in-the-dep-graph package deploys first and the shallower one wins. Verify before building on this assumption.

- [ ] **Step 1: Create two minimal local APM packages with a deliberate file collision**

```bash
mkdir -p /tmp/anvil-v2-risk-1/pkg-base/.apm/prompts
mkdir -p /tmp/anvil-v2-risk-1/pkg-override/.apm/prompts

cat > /tmp/anvil-v2-risk-1/pkg-base/apm.yml <<'EOF'
name: pkg-base
version: 1.0.0
description: Base package for override test
dependencies:
  apm: []
  mcp: []
EOF

cat > /tmp/anvil-v2-risk-1/pkg-base/.apm/prompts/hello.prompt.md <<'EOF'
---
description: Hello from base
input: []
---
This is the BASE version.
EOF

cat > /tmp/anvil-v2-risk-1/pkg-override/apm.yml <<'EOF'
name: pkg-override
version: 1.0.0
description: Overrides pkg-base hello
dependencies:
  apm:
    - /tmp/anvil-v2-risk-1/pkg-base
  mcp: []
EOF

cat > /tmp/anvil-v2-risk-1/pkg-override/.apm/prompts/hello.prompt.md <<'EOF'
---
description: Hello from override
input: []
---
This is the OVERRIDE version.
EOF
```

- [ ] **Step 2: Install pkg-override into a consumer project and check the compiled content**

```bash
mkdir -p /tmp/anvil-v2-risk-1/consumer
cd /tmp/anvil-v2-risk-1/consumer
mkdir -p .claude
apm init --yes
apm install /tmp/anvil-v2-risk-1/pkg-override --target claude
cat .claude/commands/hello.md
```

Expected: file contains "This is the OVERRIDE version." — not the base version.

- [ ] **Step 3: Record the result**

If Step 2 shows OVERRIDE: the spec's assumption holds. Proceed.

If Step 2 shows BASE: the collision rule does not favor the shallower package. Stop and revise the spec to use distinct command names (`/anvil:develop` core, `/anvil:auto-develop` orchestrator) for all four orchestrator overrides. Document the pivot in `shared/specs/2026-04-23-apm-first-marketplace-design.md` under a "Design revisions" section.

```bash
# Document the outcome either way:
echo "Risk #1 result: OVERRIDE worked / did not work (pick one)" >> /tmp/anvil-v2-risk-1/RESULT.txt
```

- [ ] **Step 4: Clean up the risk-1 scratch**

```bash
rm -rf /tmp/anvil-v2-risk-1
```

Expected: directory gone.

- [ ] **Step 5: Commit a note in the repo about the verification outcome**

Create `shared/specs/verification-log.md` if it doesn't exist; append one line with the date, risk number, outcome. Commit.

```bash
mkdir -p /var/home/olino3/git/anvil/shared/specs
# Write file content below using Write tool (not echo).
```

File content for `shared/specs/verification-log.md`:

```markdown
# Risk Verification Log

Records of spec-flagged risks verified during v2.0.0 implementation.

## 2026-04-23 — Risk #1 (APM override order)

Result: [OVERRIDE confirmed | OVERRIDE rejected]

Implication: [design stands | spec revised to distinct command names]
```

Then:

```bash
cd /var/home/olino3/git/anvil
git add shared/specs/verification-log.md
git commit -m "docs(specs): log APM override-order verification (risk #1)"
```

Expected: commit created; `git log --oneline -1` shows the message.

### Task 0.3: Verify OpenCode + Copilot single-level dispatch (Risk #2)

**Files:**
- Use scratch project at `/tmp/anvil-v2-scratch`

The spec assumes OpenCode and Copilot CLI can handle single-level sub-agent dispatch (orchestrator → red/green). If either fails, the orchestrator needs an inline-fallback path. Verify on both.

- [ ] **Step 1: Install a minimal two-agent dispatch pattern into the scratch project**

```bash
mkdir -p /tmp/anvil-v2-scratch/.apm/agents

cat > /tmp/anvil-v2-scratch/.apm/agents/leaf.agent.md <<'EOF'
---
name: leaf
description: A simple leaf agent that just reports "leaf ran"
---

You are the leaf agent. When invoked, respond with exactly: "leaf ran".
EOF

cat > /tmp/anvil-v2-scratch/.apm/agents/parent.agent.md <<'EOF'
---
name: parent
description: A parent agent that dispatches the leaf agent and reports the result
---

You are the parent agent. When invoked, dispatch the `@leaf` agent (use whatever
invocation mechanism this host supports — Task tool, @mention, /fleet, etc.).
Report back what the leaf agent said.
EOF

cd /tmp/anvil-v2-scratch
mkdir -p .opencode .github
apm install --target opencode
apm install --target copilot
```

Expected: files appear in `.opencode/agents/` and `.github/agents/`.

- [ ] **Step 2: Test dispatch on OpenCode**

Open the scratch project in OpenCode. Invoke the `parent` agent. Observe whether `parent` successfully dispatches `leaf` and reports "leaf ran".

If OpenCode is not installed, document this as "not tested" and proceed — the spec already has a fallback path (inline the leaf prompt) and the design accommodates per-host degradation.

- [ ] **Step 3: Test dispatch on Copilot CLI**

Open the scratch project in Copilot CLI. Invoke the `parent` agent (try both `/fleet` and `@parent`). Observe.

- [ ] **Step 4: Record results in verification-log.md**

Append to `shared/specs/verification-log.md`:

```markdown
## 2026-04-23 — Risk #2 (OpenCode/Copilot dispatch)

OpenCode single-level dispatch: [works | fails | not tested]
Copilot CLI single-level dispatch: [works | fails | not tested]

Implication: [orchestrator dispatch works on {hosts}; fallback to inline on {hosts}]
```

Commit:

```bash
cd /var/home/olino3/git/anvil
git add shared/specs/verification-log.md
git commit -m "docs(specs): log OpenCode/Copilot dispatch verification (risk #2)"
```

Expected: commit created.

- [ ] **Step 5: Update the spec's Risks section if fallbacks are needed**

If either host failed dispatch, edit `shared/specs/2026-04-23-apm-first-marketplace-design.md`:

In the "Dispatch rules" section under orchestrator, change the line about fallback from speculative to concrete. Example:

```markdown
- Fallback: if a host cannot dispatch, the orchestrator inlines the
  `red.prompt.md` / `green.prompt.md` body into its own session.
  Confirmed-needed hosts: {list hosts that failed Step 2/3}.
```

Commit the edit:

```bash
git add shared/specs/2026-04-23-apm-first-marketplace-design.md
git commit -m "docs(specs): concretize dispatch fallback based on risk #2 results"
```

### Task 0.4: Confirm the plugin-bundle naming convention (Risk #3)

**Files:**
- Modify: `shared/specs/2026-04-23-apm-first-marketplace-design.md` (tighten naming section if needed)

- [ ] **Step 1: Lock the naming convention in the spec**

Open `shared/specs/2026-04-23-apm-first-marketplace-design.md`, find the "v2.0.0 release artifacts" section. The spec already lists the names. Verify the pattern is unambiguous: `anvil-<package-short>-<version>-<host>.tar.gz` where `<package-short>` is `core-stable` or `orchestrator-stable` (dropping the `anvil-` prefix) — or keep the full name. Pick one explicitly.

Edit to remove ambiguity. Commit:

```bash
cd /var/home/olino3/git/anvil
git add shared/specs/2026-04-23-apm-first-marketplace-design.md
git commit -m "docs(specs): lock plugin-bundle naming convention (risk #3)"
```

Expected: the spec's bundle names are now generated by one clear pattern. Skip the commit if no change was needed — the spec already has the names as `anvil-core-stable-2.0.0-claude.tar.gz` etc. and that pattern is clear. Note that in the verification-log instead:

```markdown
## 2026-04-23 — Risk #3 (bundle naming)

Pattern: anvil-<package-name>-<version>-<host>.tar.gz
Example: anvil-core-stable-2.0.0-claude.tar.gz

Implication: CI workflow must match this exact pattern.
```

Commit the verification-log update.

---

## Phase 1 — Build `anvil-common-stable`

Smallest package, no dependencies, foundation for everything else. All ports from existing `plugins/anvil/skills/reference/` content with minor edits.

### Task 1.1: Scaffold the package

**Files:**
- Create: `packages/anvil-common-stable/apm.yml`
- Create: `packages/anvil-common-stable/.apm/` (directory)
- Create: `packages/anvil-common-stable/.apm/instructions/` (directory)
- Create: `packages/anvil-common-stable/.apm/skills/` (directory)

- [ ] **Step 1: Create the directory structure**

```bash
cd /var/home/olino3/git/anvil
mkdir -p packages/anvil-common-stable/.apm/instructions
mkdir -p packages/anvil-common-stable/.apm/skills
```

Expected: `ls packages/anvil-common-stable/.apm` shows `instructions` and `skills`.

- [ ] **Step 2: Write the package manifest**

Write to `packages/anvil-common-stable/apm.yml`:

```yaml
name: anvil-common-stable
version: 2.0.0
description: Shared primitives for Anvil — formats, templates, TDD / commit / worktree discipline.
author: Olino3
license: MIT
dependencies:
  apm: []
  mcp: []
scripts: {}
```

Expected: `cat packages/anvil-common-stable/apm.yml | head -5` shows `name: anvil-common-stable`.

- [ ] **Step 3: Commit the scaffold**

```bash
git add packages/anvil-common-stable/
git commit -m "feat(common): scaffold anvil-common-stable package"
```

Expected: commit created.

### Task 1.2: Port commit-conventions as an instruction

**Files:**
- Create: `packages/anvil-common-stable/.apm/instructions/commit-conventions.instructions.md`
- Source: `plugins/anvil/skills/reference/commit-conventions.md`

- [ ] **Step 1: Read the source**

```bash
cat plugins/anvil/skills/reference/commit-conventions.md
```

Note the current file has no APM frontmatter (it's a plain markdown reference).

- [ ] **Step 2: Write the instruction file with APM frontmatter**

Create the file with frontmatter prepended to the source's body. Use the
Write tool with this content pattern:

```markdown
---
description: Anvil commit message conventions — scope, type, and message style.
applyTo: "**/*"
author: Olino3
version: "2.0.0"
---

<CONTENT-OF: plugins/anvil/skills/reference/commit-conventions.md — copy
the entire file verbatim, appending it after the frontmatter's closing `---`
with one blank line in between.>
```

Concretely, after writing: `wc -l packages/anvil-common-stable/.apm/instructions/commit-conventions.instructions.md` should equal `wc -l plugins/anvil/skills/reference/commit-conventions.md + 7` (six frontmatter lines + one blank).

Expected: `head -5 packages/anvil-common-stable/.apm/instructions/commit-conventions.instructions.md` shows the frontmatter. The body after line 7 is byte-identical to the source.

- [ ] **Step 3: Commit**

```bash
git add packages/anvil-common-stable/.apm/instructions/commit-conventions.instructions.md
git commit -m "feat(common): port commit-conventions as instruction"
```

Expected: commit created.

### Task 1.3: Port TDD discipline as an instruction

**Files:**
- Create: `packages/anvil-common-stable/.apm/instructions/tdd-discipline.instructions.md`
- Source: `plugins/anvil/skills/tdd/SKILL.md`

- [ ] **Step 1: Write the instruction file**

Create the file with the new frontmatter, then the body of the source
SKILL.md (dropping the source's own frontmatter), then the "When this
instruction applies" closing paragraph. Use the Write tool with this
content pattern:

```markdown
---
description: RED/GREEN/REFACTOR discipline — language-agnostic TDD cycle for Anvil ticket implementation.
applyTo: "**/*"
author: Olino3
version: "2.0.0"
---

<CONTENT-OF: plugins/anvil/skills/tdd/SKILL.md body only — drop the source's
frontmatter (the first `---` block at the top) and keep everything from the
body's first heading onward.>

## When this instruction applies

This instruction applies whenever you are writing code or tests for a sprint
ticket. RED → GREEN → REFACTOR is mandatory. Do not skip RED. Do not
write code without a failing test first.
```

Concretely: `awk '/^---$/{n++; next} n==2' plugins/anvil/skills/tdd/SKILL.md` prints the source body without its frontmatter. Paste that between your new frontmatter and the closing paragraph.

Expected: `head -5` shows the new frontmatter; the TDD body matches the source.

- [ ] **Step 2: Commit**

```bash
git add packages/anvil-common-stable/.apm/instructions/tdd-discipline.instructions.md
git commit -m "feat(common): port TDD discipline as instruction"
```

Expected: commit created.

### Task 1.4: Author worktree-discipline as a new instruction

**Files:**
- Create: `packages/anvil-common-stable/.apm/instructions/worktree-discipline.instructions.md`
- Sources: `plugins/anvil/agents/dev-agent.agent.md` (Phase 0), `plugins/anvil/commands/develop.md` (Steps 5, 7, 8)

**Note:** Use the user-revised branch-naming scheme: `feature/{sprint-branch}-{ticket-id}`.

- [ ] **Step 1: Write the instruction file**

Write to `packages/anvil-common-stable/.apm/instructions/worktree-discipline.instructions.md`:

```markdown
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
```

Expected: file exists; contains the branch naming scheme `feature/{sprint-branch}-{ticket-id}`; grep for `feature/` in the file returns the expected occurrences.

- [ ] **Step 2: Commit**

```bash
git add packages/anvil-common-stable/.apm/instructions/worktree-discipline.instructions.md
git commit -m "feat(common): add worktree-discipline instruction"
```

Expected: commit created.

### Task 1.5: Port the four reference skills

**Files:**
- Create: `packages/anvil-common-stable/.apm/skills/roadmap-format/SKILL.md`
- Create: `packages/anvil-common-stable/.apm/skills/sprint-readme-format/SKILL.md`
- Create: `packages/anvil-common-stable/.apm/skills/ticket-template/SKILL.md`
- Create: `packages/anvil-common-stable/.apm/skills/ba-report-format/SKILL.md`

Each one wraps its source in APM skill frontmatter. Do one per step; commit after each.

- [ ] **Step 1: Port roadmap-format**

```bash
mkdir -p packages/anvil-common-stable/.apm/skills/roadmap-format
```

Write to `packages/anvil-common-stable/.apm/skills/roadmap-format/SKILL.md`:

```markdown
---
name: roadmap-format
description: Reference — structure of ROADMAP.md (phases, prefixes, goals, deliverables, avoid-deepening). Consult when creating or editing ROADMAP.md.
user-invocable: false
---

<CONTENT-OF: plugins/anvil/skills/reference/roadmap-format.md — copy verbatim after the frontmatter closing `---`>
```

- [ ] **Step 2: Port sprint-readme-format**

```bash
mkdir -p packages/anvil-common-stable/.apm/skills/sprint-readme-format
```

Write to `.../sprint-readme-format/SKILL.md`:

```markdown
---
name: sprint-readme-format
description: Reference — structure of docs/anvil/sprints/*/README.md (tickets table, dependency graph, counts). Consult when creating or updating a sprint README.
user-invocable: false
---

<CONTENT-OF: plugins/anvil/skills/reference/sprint-readme-format.md — copy verbatim after the frontmatter closing `---`>
```

- [ ] **Step 3: Port ticket-template**

```bash
mkdir -p packages/anvil-common-stable/.apm/skills/ticket-template
```

Write to `.../ticket-template/SKILL.md`:

```markdown
---
name: ticket-template
description: Reference — required fields and sections for every sprint ticket file. Consult when creating a new ticket or a SPIKE.
user-invocable: false
---

<CONTENT-OF: plugins/anvil/skills/reference/ticket-template.md — copy verbatim after the frontmatter closing `---`>
```

- [ ] **Step 4: Port ba-report-format**

```bash
mkdir -p packages/anvil-common-stable/.apm/skills/ba-report-format
```

Write to `.../ba-report-format/SKILL.md`:

```markdown
---
name: ba-report-format
description: Reference — structure of BA-REPORT.md. Consult when producing or reading a sprint BA report.
user-invocable: false
---

<CONTENT-OF: plugins/anvil/skills/reference/report-format.md — copy verbatim after the frontmatter closing `---`>
```

- [ ] **Step 5: Commit all four**

```bash
git add packages/anvil-common-stable/.apm/skills/
git commit -m "feat(common): port reference-format skills (roadmap, sprint-readme, ticket-template, ba-report)"
```

Expected: commit created; `ls packages/anvil-common-stable/.apm/skills/` shows four directories.

### Task 1.6: Author the anvil-config-schema skill

**Files:**
- Create: `packages/anvil-common-stable/.apm/skills/anvil-config-schema/SKILL.md`
- Source: extract from `plugins/anvil/skills/init/SKILL.md`

- [ ] **Step 1: Read the init skill to find the config.yml schema discussion**

```bash
cat plugins/anvil/skills/init/SKILL.md
```

Look for the section defining the `config.yml` structure — components, test_command, build_command, lint_command, etc.

- [ ] **Step 2: Write the schema skill**

Write to `packages/anvil-common-stable/.apm/skills/anvil-config-schema/SKILL.md`:

```markdown
---
name: anvil-config-schema
description: Reference — schema for docs/anvil/config.yml (components, test/build/lint/type_check commands per component). Consult when reading or writing the Anvil config.
user-invocable: false
---

# docs/anvil/config.yml — Schema

Anvil's per-project config file. Describes each component of the project and
the commands used to test, build, lint, and type-check it.

## Top-level structure

\`\`\`yaml
components:
  <component-name>:
    language: <language-id>
    source_dir: <path>
    test_dir: <path>
    test_pattern: <glob>
    test_command: <shell command>
    build_command: <shell command>       # optional
    lint_command: <shell command>        # optional
    type_check_command: <shell command>  # optional
\`\`\`

## Fields

- **language** — identifier like `python`, `typescript`, `go`, `ruby`. Used by red/green agents to pick idiomatic test / implementation patterns.
- **source_dir** — relative path to where production code lives.
- **test_dir** — relative path to where tests live.
- **test_pattern** — glob or pattern that maps a source module to its test file. `{module}` placeholder is substituted with the module name. Example: `tests/test_{module}.py`.
- **test_command** — exact command to run the test suite for this component.
- **build_command** — optional. Run before tests to ensure compilation/build.
- **lint_command** — optional. Run after GREEN to catch style issues.
- **type_check_command** — optional. Run after GREEN in typed languages.

## Example

\`\`\`yaml
components:
  api:
    language: python
    source_dir: src/api
    test_dir: tests/api
    test_pattern: "tests/api/test_{module}.py"
    test_command: "pytest tests/api -v"
    lint_command: "ruff check src/api tests/api"
    type_check_command: "mypy src/api"
  web:
    language: typescript
    source_dir: web/src
    test_dir: web/tests
    test_pattern: "web/tests/{module}.test.ts"
    test_command: "npm test --prefix web"
    build_command: "npm run build --prefix web"
\`\`\`

## Rules

- Every ticket's `Component:` field must match a key in this file. If it does not, `/anvil:develop` and `red.agent` / `green.agent` will fail to pick commands.
- Commands are run by the agent, not compiled or modified. Keep them shell-executable.
```

- [ ] **Step 3: Commit**

```bash
git add packages/anvil-common-stable/.apm/skills/anvil-config-schema/
git commit -m "feat(common): add anvil-config-schema reference skill"
```

Expected: commit created.

### Task 1.7: Validate `anvil-common-stable` installs cleanly

**Files:**
- Use scratch project at `/tmp/anvil-v2-scratch`

- [ ] **Step 1: Install common into scratch**

```bash
cd /tmp/anvil-v2-scratch
rm -rf apm_modules .apm apm.lock.yaml .claude .github .cursor .opencode
apm init --yes
apm install /var/home/olino3/git/anvil/packages/anvil-common-stable
```

Expected: exit 0. Output mentions deploying files. `apm list` shows `anvil-common-stable`.

- [ ] **Step 2: Check compiled outputs for each host target**

```bash
apm install /var/home/olino3/git/anvil/packages/anvil-common-stable --target all
ls -la .claude/skills/ 2>/dev/null
ls -la .github/skills/ 2>/dev/null
ls -la .cursor/skills/ 2>/dev/null
ls -la .opencode/skills/ 2>/dev/null
```

Expected: at least one target directory exists and contains `ticket-template/`, `roadmap-format/`, etc.

- [ ] **Step 3: Clean scratch**

```bash
cd /tmp/anvil-v2-scratch
rm -rf apm_modules .apm apm.lock.yaml .claude .github .cursor .opencode
```

Expected: scratch project returned to baseline (only `apm.yml` and `.git/`).

- [ ] **Step 4: No commit needed**

Validation only; no repo changes.

---

## Phase 2 — Build `anvil-core-stable`

The discipline package. Depends on common. Five sub-phases: scaffold, port agents, port skills, author prompts, validate.

### Task 2.1: Scaffold the package

**Files:**
- Create: `packages/anvil-core-stable/apm.yml`
- Create: `packages/anvil-core-stable/.apm/agents/` (directory)
- Create: `packages/anvil-core-stable/.apm/skills/` (directory)
- Create: `packages/anvil-core-stable/.apm/prompts/` (directory)

- [ ] **Step 1: Create directories**

```bash
cd /var/home/olino3/git/anvil
mkdir -p packages/anvil-core-stable/.apm/agents
mkdir -p packages/anvil-core-stable/.apm/skills
mkdir -p packages/anvil-core-stable/.apm/prompts
```

Expected: `ls packages/anvil-core-stable/.apm` shows three directories.

- [ ] **Step 2: Write apm.yml**

Write to `packages/anvil-core-stable/apm.yml`:

```yaml
name: anvil-core-stable
version: 2.0.0
description: Anvil discipline — agents, skills, and parameterized prompts for human-driven sprint TDD. No dispatch.
author: Olino3
license: MIT
dependencies:
  apm:
    - /var/home/olino3/git/anvil/packages/anvil-common-stable
  mcp: []
scripts:
  anvil:init: anvil-init.prompt.md
  anvil:roadmap: anvil-roadmap.prompt.md
  anvil:sprint: anvil-sprint.prompt.md
  anvil:plan: anvil-plan-ticket.prompt.md
  anvil:develop: anvil-develop.prompt.md
  anvil:red: anvil-red.prompt.md
  anvil:green: anvil-green.prompt.md
  anvil:refactor: anvil-refactor.prompt.md
  anvil:review: anvil-review.prompt.md
  anvil:sync: anvil-sync.prompt.md
  anvil:status: anvil-status.prompt.md
```

**Note:** The local path dependency is only for local development. It will be rewritten to `Olino3/anvil/packages/anvil-common-stable` in Task 8.2 before release.

- [ ] **Step 3: Commit**

```bash
git add packages/anvil-core-stable/
git commit -m "feat(core): scaffold anvil-core-stable package"
```

Expected: commit created.

### Task 2.2: Port red.agent.md (whole-ticket scope)

**Files:**
- Create: `packages/anvil-core-stable/.apm/agents/red.agent.md`
- Source: `plugins/anvil/agents/red-agent.agent.md`

- [ ] **Step 1: Write red.agent.md with rescoping**

Write to `packages/anvil-core-stable/.apm/agents/red.agent.md`:

```markdown
---
name: red
description: RED persona — writes a complete failing test suite for all acceptance criteria (happy path + edge cases) of a sprint ticket. Does not write production code.
author: Olino3
version: "2.0.0"
---

# RED — Write Failing Tests for an Entire Ticket

You are the RED agent. Your job is to write a complete failing test suite for
a sprint ticket, covering **every acceptance criterion with happy-path and
edge-case tests**, in one invocation. You write tests only — never production
code.

## Inputs

- The target ticket ID (e.g., `MVP-001`)
- The ticket file (located under `docs/anvil/sprints/**/<ticket-id>*.md`)
- `docs/anvil/config.yml` for component test commands

## Workflow

1. **Read the ticket file.** Parse acceptance criteria, implementation checklist, and any notes about constraints. Every acceptance criterion will become one or more test cases.

2. **Read project config.** Look up the ticket's `Component:` field in `docs/anvil/config.yml` to find: language, test_dir, test_pattern, test_command.

3. **Explore existing tests.** Read 2-3 existing test files in the component's `test_dir` to understand framework, assertion style, fixtures, naming conventions.

4. **Explore source structure.** Read relevant source files to understand existing interfaces and types. Do NOT implement anything.

5. **Write the complete failing test suite.** For each acceptance criterion in the ticket:
   - Write at least one happy-path test (expected behavior with valid inputs)
   - Write at least one edge-case or error-case test (boundary values, invalid inputs, empty data, concurrent access, etc.)
   - Each test method tests exactly one behavior
   - Assert on behavior (return values, side effects, state changes)
   - Use existing fixtures where available

6. **Determine test file location(s)** using the component's `test_pattern`. Replace `{module}` with the module name under test. If a matching test file already exists, add tests to it. Multiple test files are fine if the ticket spans multiple modules.

7. **Run the tests** using the component's `test_command` to confirm they FAIL. Tests must fail because the feature does not exist yet — not because of syntax errors, import errors, or missing fixtures. Fix any test that fails for the wrong reason.

8. **Commit the tests:**
   ```
   test({scope}): add failing tests for {ticket-id} acceptance criteria
   ```
   Where `{scope}` matches the ticket's component.

9. **Output**: the test file path(s), a summary of each test case (criterion N, happy/edge case), and confirmation the full suite fails for the right reason.

## Constraints

- **Do NOT write production code.** Stop after the failing tests are written and committed.
- **Tests must fail because the feature is missing**, not because of syntax errors or import issues.
- **Use project conventions.** Discover framework, assertion style, fixtures from existing tests.
- **Whole-ticket scope.** One invocation covers all criteria — do not stop after the first criterion.

## Success Criteria

- One commit containing failing tests for every acceptance criterion
- Each criterion has both happy-path and edge-case coverage
- All new tests fail for the right reason
- No production code written
```

- [ ] **Step 2: Commit**

```bash
git add packages/anvil-core-stable/.apm/agents/red.agent.md
git commit -m "feat(core): port red agent with whole-ticket scope"
```

Expected: commit created.

### Task 2.3: Port green.agent.md (whole-ticket scope)

**Files:**
- Create: `packages/anvil-core-stable/.apm/agents/green.agent.md`
- Source: `plugins/anvil/agents/green-agent.agent.md`

- [ ] **Step 1: Write green.agent.md**

Write to `packages/anvil-core-stable/.apm/agents/green.agent.md`:

```markdown
---
name: green
description: GREEN persona — writes minimum production code to make an entire ticket's failing test suite pass. Does not write additional tests.
author: Olino3
version: "2.0.0"
---

# GREEN — Implement to Pass an Entire Ticket's Tests

You are the GREEN agent. Your job is to write the minimum production code
needed to make the whole failing test suite (for a sprint ticket) pass. You
do not write additional tests.

## Inputs

- The target ticket ID (e.g., `MVP-001`)
- The failing test file path(s) from the RED agent's last commit
- `docs/anvil/config.yml` for component commands

## Workflow

1. **Read the ticket file** to understand the intended functionality and scope.

2. **Read project config.** Look up the component in `docs/anvil/config.yml` to find: language, source_dir, test_command, build_command.

3. **Read the failing tests.** Understand exactly what behavior is expected — return values, side effects, error conditions. The tests are your specification.

4. **Run the tests** to confirm current FAIL state using the component's `test_command`.

5. **Read project conventions.** Check the project's CLAUDE.md, README, or architecture docs for conventions about module structure, imports, logging, error handling, configuration.

6. **Implement the minimum production code** to make all failing tests pass:
   - Write only what the tests require — no extra features, no speculative code
   - Follow existing code style and patterns in the source directory
   - Place code in the correct location within the component's `source_dir`
   - If `build_command` exists, run it after changes

7. **Run the tests again** to confirm GREEN state:
   - All RED tests must now pass
   - All previously-passing tests must still pass
   - If any pre-existing test breaks, fix your implementation — not the test

8. **Commit the implementation:**
   ```
   feat({scope}): implement {ticket-id}
   ```
   Or `fix({scope}): {description}` for bug fix tickets. `{scope}` matches the ticket's component.

9. **Output**: a summary of files created/modified and confirmation that the full test suite passes.

## Constraints

- **Do NOT write additional tests.** That is the RED agent's job.
- **Do NOT over-engineer.** Implement only what the tests require.
- **No hardcoded commands.** Read commands from `docs/anvil/config.yml`.
- **Respect project conventions.** Read the project's own docs for architecture and style rules.
- **Fix implementation, not tests.** If a pre-existing test breaks, fix your implementation.

## Success Criteria

- One commit making the whole ticket's test suite pass
- Zero previously-passing tests broken
- No new tests written
- Implementation is minimal — no speculative code or unused abstractions
```

- [ ] **Step 2: Commit**

```bash
git add packages/anvil-core-stable/.apm/agents/green.agent.md
git commit -m "feat(core): port green agent with whole-ticket scope"
```

Expected: commit created.

### Task 2.4: Author dev-discipline.agent.md

**Files:**
- Create: `packages/anvil-core-stable/.apm/agents/dev-discipline.agent.md`
- Source: extract planning logic from `plugins/anvil/agents/dev-agent.agent.md` Phase 1

- [ ] **Step 1: Write dev-discipline.agent.md**

Write to `packages/anvil-core-stable/.apm/agents/dev-discipline.agent.md`:

```markdown
---
name: dev-discipline
description: Plan-and-approve persona for a sprint ticket. Reads the ticket, produces a RED/GREEN/REFACTOR plan, asks for approval, and stops. Does not dispatch other agents.
author: Olino3
version: "2.0.0"
---

# Dev Discipline — Plan-and-Approve

You are the Dev Discipline agent. Your job is to review a single sprint ticket,
produce a clear implementation plan, present it for approval, and stop. You
do not dispatch sub-agents. You do not write code or tests.

## Inputs

- The target ticket ID
- The ticket file path
- `docs/anvil/config.yml` for component context
- Sprint README path (for dependency context)

## Workflow

1. **Read the ticket.** Parse all fields: status, phase, type, component, dependencies, acceptance criteria, implementation checklist, verification steps, notes.

2. **Read project config.** Look up the component in `docs/anvil/config.yml`.

3. **Check dependencies.** Read the sprint README and verify all tickets in `Depends on:` have Status: Done. If any are not Done, refuse to proceed. Report which dependencies are blocking and stop.

4. **Produce the plan.** Since RED and GREEN operate at whole-ticket scope, the plan is simple:
   - **Step 1 — RED:** write the complete failing test suite (all acceptance criteria, happy + edge per criterion). Resulting commit: `test({scope}): add failing tests for {ticket-id} acceptance criteria`.
   - **Step 2 — GREEN:** implement minimum code to pass the full suite. Commit: `feat({scope}): implement {ticket-id}`.
   - **Step 3 — REFACTOR (optional):** clean up if warranted. Commit: `refactor({scope}): {description}`.
   - **Step 4 — Integration choice** (at end of REFACTOR or GREEN): present the five-option matrix (squash / merge / PR / keep / discard).

   The meaningful planning work is surfacing ambiguities or risks **inside the ticket** — under-specified criteria, missing edge cases, implicit dependencies on other parts of the codebase. Enumerate these as a bulleted list under the plan.

5. **Present the plan** and ask the user: *"Proceed with this plan?"* Stop and wait for approval. Do nothing else.

## Constraints

- **Do NOT dispatch other agents.** You are planning only.
- **Do NOT write code or tests.** You are planning only.
- **Flag ambiguity.** If any acceptance criterion is unclear, list it under "Questions before we proceed" rather than guessing.

## Success Criteria

- The plan is written and presented
- All ambiguities / risks surfaced
- The user has approved or redirected
- No code or tests written
```

- [ ] **Step 2: Commit**

```bash
git add packages/anvil-core-stable/.apm/agents/dev-discipline.agent.md
git commit -m "feat(core): add dev-discipline plan-and-approve agent"
```

Expected: commit created.

### Task 2.5: Port pd, pm, ba, sprint-syncer agents

**Files:**
- Create: `packages/anvil-core-stable/.apm/agents/pd.agent.md`
- Create: `packages/anvil-core-stable/.apm/agents/pm.agent.md`
- Create: `packages/anvil-core-stable/.apm/agents/ba.agent.md`
- Create: `packages/anvil-core-stable/.apm/agents/sprint-syncer.agent.md`
- Sources: `plugins/anvil/agents/{pd-agent,pm-agent,ba-agent,sprint-syncer-agent}.agent.md`

- [ ] **Step 1: Port pd-agent → pd.agent.md**

Read source:
```bash
cat plugins/anvil/agents/pd-agent.agent.md
```

Write to `packages/anvil-core-stable/.apm/agents/pd.agent.md`: copy the source verbatim, then update the frontmatter `name:` field from `pd-agent` to `pd`.

- [ ] **Step 2: Port pm-agent → pm.agent.md**

Same as Step 1 but for `pm-agent.agent.md` → `pm.agent.md`; rename in frontmatter.

- [ ] **Step 3: Port ba-agent → ba.agent.md with autonomous-cleanup paragraphs removed**

Read source:
```bash
cat plugins/anvil/agents/ba-agent.agent.md
```

Write to `packages/anvil-core-stable/.apm/agents/ba.agent.md`: copy verbatim, **remove** any paragraphs or workflow steps that describe ba-agent *applying* cleanup actions (splits, archival, status corrections). Keep everything that describes *reporting* cleanup recommendations. The report must end with a "Recommended actions" section listing what the user (or review-orchestrator) should apply.

Update frontmatter `name:` to `ba`. If the ba-agent's description mentions "autonomous cleanup," rephrase to "analyzes and reports recommended cleanup; does not apply changes."

- [ ] **Step 4: Port sprint-syncer-agent → sprint-syncer.agent.md**

Same mechanical port; rename to `sprint-syncer` in frontmatter.

- [ ] **Step 5: Commit all four**

```bash
git add packages/anvil-core-stable/.apm/agents/pd.agent.md \
        packages/anvil-core-stable/.apm/agents/pm.agent.md \
        packages/anvil-core-stable/.apm/agents/ba.agent.md \
        packages/anvil-core-stable/.apm/agents/sprint-syncer.agent.md
git commit -m "feat(core): port pd, pm, ba, sprint-syncer agents"
```

Expected: commit created; `ls packages/anvil-core-stable/.apm/agents/` shows 7 files (red, green, dev-discipline, pd, pm, ba, sprint-syncer).

### Task 2.6: Port the seven stage skills

**Files:**
- Create seven `SKILL.md` files under `packages/anvil-core-stable/.apm/skills/anvil-*/`
- Sources: `plugins/anvil/skills/{init,roadmap,sprint,develop,review,sync,status}/SKILL.md`

For each skill, port the source verbatim except:

- Update frontmatter `name:` to `anvil-<stage>` (e.g., `anvil-init`, `anvil-roadmap`)
- Update any sentence that says "this skill dispatches dev-agent" or implies automatic dispatch — rewrite to name the explicit user action (e.g., "invoke `@pd` or run `apm run anvil:roadmap`")
- Add an "Invocation" section near the top of each SKILL.md listing the three ways to trigger the underlying prompt: slash command on Claude/OpenCode, `@<agent>` on Cursor/Copilot, `apm run anvil:<stage>` everywhere

Do one per step; commit at the end.

- [ ] **Step 1: Port init skill**

```bash
mkdir -p packages/anvil-core-stable/.apm/skills/anvil-init
```

Read `plugins/anvil/skills/init/SKILL.md`. Copy to `.../anvil-init/SKILL.md`, update `name: init` → `name: anvil-init`. Add the "Invocation" section at the top:

```markdown
## Invocation

- Slash command: `/anvil:init`
- APM runtime: `apm run anvil:init`
- Agent mention (Cursor, Copilot): not applicable — init is a project-setup skill, not an agent
```

- [ ] **Step 2: Port roadmap skill**

```bash
mkdir -p packages/anvil-core-stable/.apm/skills/anvil-roadmap
```

Port `plugins/anvil/skills/roadmap/SKILL.md` → `.../anvil-roadmap/SKILL.md` with name update and invocation section. Replace any "dispatches pd-agent" wording with "invoke `@pd` (where supported) or run `apm run anvil:roadmap`".

Invocation section:

```markdown
## Invocation

- Slash command: `/anvil:roadmap`
- APM runtime: `apm run anvil:roadmap`
- Agent mention: `@pd`
```

- [ ] **Step 3: Port sprint skill**

```bash
mkdir -p packages/anvil-core-stable/.apm/skills/anvil-sprint
```

Port `plugins/anvil/skills/sprint/SKILL.md` → `.../anvil-sprint/SKILL.md`. Name update + invocation section. Replace dispatch language.

Invocation:

```markdown
## Invocation

- Slash command: `/anvil:sprint <phase>`
- APM runtime: `apm run anvil:sprint --param phase=<phase>`
- Agent mention: `@pm <phase>`
```

- [ ] **Step 4: Port develop skill (rewritten for plan-and-stop)**

```bash
mkdir -p packages/anvil-core-stable/.apm/skills/anvil-develop
```

Port `plugins/anvil/skills/develop/SKILL.md` → `.../anvil-develop/SKILL.md`, but rewrite the "Procedure" section to reflect plan-and-stop:

- Steps 1-4 (locate, verify config, read sprint context, verify branch) stay.
- Step 5 (create worktree) stays — auto-worktree is core's responsibility.
- Step 6 (dispatch dev-agent) is replaced with: "Invoke `dev-discipline.agent` to produce a plan. Stop after the user approves. Report the three follow-up commands the user should run: `/anvil:red <ticket-id>`, `/anvil:green <ticket-id>`, `/anvil:refactor <ticket-id>`."
- Steps 7-9 (present integration options, execute integration, post-completion) are **removed** — those happen at the end of `/anvil:refactor` (or `/anvil:green` if no refactor), not at the end of `/anvil:develop`.

Invocation:

```markdown
## Invocation

- Slash command: `/anvil:develop <ticket-id>`
- APM runtime: `apm run anvil:develop --param ticket=<ticket-id>`
```

- [ ] **Step 5: Port review skill**

```bash
mkdir -p packages/anvil-core-stable/.apm/skills/anvil-review
```

Port `plugins/anvil/skills/review/SKILL.md`. Name update + invocation. Soften any language implying ba-agent applies cleanup autonomously; it only reports.

Invocation:

```markdown
## Invocation

- Slash command: `/anvil:review <phase>`
- APM runtime: `apm run anvil:review --param phase=<phase>`
- Agent mention: `@ba <phase>`
```

- [ ] **Step 6: Port sync skill**

```bash
mkdir -p packages/anvil-core-stable/.apm/skills/anvil-sync
```

Port `plugins/anvil/skills/sync/SKILL.md`. Name update + invocation.

Invocation:

```markdown
## Invocation

- Slash command: `/anvil:sync <phase>`
- APM runtime: `apm run anvil:sync --param phase=<phase>`
- Agent mention: `@sprint-syncer <phase>`
```

- [ ] **Step 7: Port status skill**

```bash
mkdir -p packages/anvil-core-stable/.apm/skills/anvil-status
```

Port `plugins/anvil/skills/status/SKILL.md`. Name update + invocation.

Invocation:

```markdown
## Invocation

- Slash command: `/anvil:status [phase]`
- APM runtime: `apm run anvil:status` or `apm run anvil:status --param phase=<phase>`
```

- [ ] **Step 8: Commit all seven skills**

```bash
git add packages/anvil-core-stable/.apm/skills/
git commit -m "feat(core): port seven stage skills with updated invocation sections"
```

Expected: commit created; `ls packages/anvil-core-stable/.apm/skills/` shows seven directories.

### Task 2.7: Author the eleven core prompts

Each prompt in `packages/anvil-core-stable/.apm/prompts/` has APM frontmatter declaring `description:` and `input:`, and a body that is the prompt itself (often very short — just "Invoke the `@<agent>` agent with the following parameters" for prompts that wrap a single agent).

Do one per step; commit all at the end.

- [ ] **Step 1: anvil-init.prompt.md**

Write to `packages/anvil-core-stable/.apm/prompts/anvil-init.prompt.md`:

```markdown
---
description: Initialize Anvil for this project — detect tech stack, configure components, write docs/anvil/config.yml.
input: []
---

# Anvil Init

Set up Anvil for this project through interactive conversation. Invoke the
`anvil-init` skill and follow its procedure.

Refer to `anvil-config-schema` skill (from anvil-common-stable) for the target
schema of `docs/anvil/config.yml`.

At completion, inform the user: `docs/anvil/config.yml` created / updated.
Next step: `/anvil:roadmap` (or `apm run anvil:roadmap`).
```

- [ ] **Step 2: anvil-roadmap.prompt.md**

Write:

```markdown
---
description: Create or update ROADMAP.md through a conversation with the Product Director agent.
input: []
---

# Anvil Roadmap

Invoke the `@pd` agent (Product Director). Reference the `anvil-roadmap` skill
for the procedure, and the `roadmap-format` skill (from anvil-common-stable)
for the target structure.

At completion, inform the user: `ROADMAP.md` created / updated. Next step:
`/anvil:sprint <phase>` (or `apm run anvil:sprint --param phase=<phase>`).
```

- [ ] **Step 3: anvil-sprint.prompt.md**

Write:

```markdown
---
description: Break a ROADMAP phase into granular sprint tickets by invoking the Project Manager agent.
input:
  - phase: "Phase name, number, or prefix (e.g. MVP, 2, AUTH)"
---

# Anvil Sprint

Invoke the `@pm` agent to generate the sprint for phase `${input:phase}`.

Follow the `anvil-sprint` skill's procedure; use the `sprint-readme-format`
and `ticket-template` skills (from anvil-common-stable) for target structure.

At completion, inform the user the sprint directory was created and what the
first unblocked ticket is. Suggest: `/anvil:develop <ticket-id>`.
```

- [ ] **Step 4: anvil-develop.prompt.md** (the locate/verify/worktree/plan/stop entry point)

Write:

```markdown
---
description: Plan implementation of a single sprint ticket. Locates ticket, verifies deps, auto-creates worktree, invokes dev-discipline for a plan, asks for approval, stops.
input:
  - ticket: "Ticket ID (e.g., MVP-001)"
---

# Anvil Develop — Plan Only

Plan the implementation of ticket `${input:ticket}`.

## Procedure

1. **Locate the ticket.** Search `docs/anvil/sprints/**/<ticket>*.md`. If not found, report and stop.
2. **Verify configuration.** Read `docs/anvil/config.yml`. Fail if missing.
3. **Read sprint context.** Read the sprint `README.md` containing the ticket.
4. **Verify branch.** If the current git branch does not match the sprint's Branch field, ask the user to switch first.
5. **Auto-create worktree.** Follow `worktree-discipline` instructions (from anvil-common-stable): create `.worktrees/${input:ticket}` on branch `feature/{sprint-slug}-${input:ticket}` (where sprint-slug is the sprint branch with any leading `feature/` stripped). Add `.worktrees/` to `.gitignore` if needed. `cd` into the worktree.
6. **Invoke `dev-discipline.agent`** to produce a plan for the ticket and ask for approval. Stop after approval.
7. **Report next steps.** Tell the user to run, in order: `/anvil:red ${input:ticket}`, `/anvil:green ${input:ticket}`, then optionally `/anvil:refactor ${input:ticket}`. `/anvil:refactor` (or `/anvil:green` if no refactor warranted) will present the integration-choice matrix at completion.

## Constraints

- Do not proceed past Step 6. The user runs red/green/refactor separately.
- Do not dispatch `@red` or `@green` here. That is orchestrator's job.
```

- [ ] **Step 5: anvil-plan-ticket.prompt.md**

Write:

```markdown
---
description: Produce a RED/GREEN/REFACTOR plan for a sprint ticket without touching code or the worktree. Standalone re-use of dev-discipline.
input:
  - ticket: "Ticket ID (e.g., MVP-001)"
---

# Anvil Plan Ticket

Invoke `dev-discipline.agent` to produce a plan for ticket `${input:ticket}`.

Do not create a worktree, do not modify any files. Plan only.

At completion, ask the user: *"Proceed with this plan?"* Stop after the
response.
```

- [ ] **Step 6: anvil-red.prompt.md**

Write:

```markdown
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
```

- [ ] **Step 7: anvil-green.prompt.md**

Write:

```markdown
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
```

- [ ] **Step 8: anvil-refactor.prompt.md** (self-contained, no dedicated agent)

Write:

```markdown
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
```

- [ ] **Step 9: anvil-review.prompt.md**

Write:

```markdown
---
description: Sprint health + verification. Runs BA analysis against a phase; reports cleanup recommendations without applying them.
input:
  - phase: "Phase name, version, or prefix (e.g. MVP, 1.0.0, AUTH)"
---

# Anvil Review

Invoke the `@ba` agent for phase `${input:phase}`.

Follow the `anvil-review` skill's procedure; produce a `BA-REPORT.md` using
the `ba-report-format` skill (from anvil-common-stable).

The BA agent only **reports** cleanup recommendations. Applying them
(ticket splits, archival, status corrections) is a separate action —
the user does it manually, or the orchestrator package's
`review-orchestrator` applies them with a single approval.

Report the path to the generated `BA-REPORT.md`.
```

- [ ] **Step 10: anvil-sync.prompt.md**

Write:

```markdown
---
description: Rebuild a sprint README from its ticket files to fix drift. Read-only with respect to tickets; only the sprint README changes.
input:
  - phase: "Phase name, version, or prefix"
---

# Anvil Sync

Invoke the `@sprint-syncer` agent for phase `${input:phase}`.

Follow `anvil-sync` skill procedure. Use `sprint-readme-format` (from
anvil-common-stable) for the target structure.

Report which ticket statuses changed in the rebuild (if any).
```

- [ ] **Step 11: anvil-status.prompt.md**

Write:

```markdown
---
description: Read-only status summary. No writes, no agent dispatch. Shows ticket counts, in-progress work, blocked tickets, recent activity.
input:
  - phase: "Optional phase filter"
---

# Anvil Status

Produce a read-only status summary.

## Procedure

1. If `${input:phase}` is provided, scope to that phase's sprint directory. Otherwise, summarize all sprints under `docs/anvil/sprints/`.
2. For each sprint in scope:
   - Read the sprint README
   - Count tickets by Status (Open / In Progress / Done / Blocked)
   - List any tickets marked In Progress
   - List any blocked tickets and what they depend on
3. Print the summary. Do not modify any files.

## Constraints

- Read-only. No writes under any circumstances.
- No agent dispatch. This is a pure-data prompt.
```

- [ ] **Step 12: Commit all eleven prompts**

```bash
git add packages/anvil-core-stable/.apm/prompts/
git commit -m "feat(core): author eleven prompts (init, roadmap, sprint, develop, plan, red, green, refactor, review, sync, status)"
```

Expected: commit created; `ls packages/anvil-core-stable/.apm/prompts/` shows eleven `.prompt.md` files.

### Task 2.8: Validate `anvil-core-stable` installs and compiles

**Files:**
- Use scratch at `/tmp/anvil-v2-scratch`

- [ ] **Step 1: Fresh install into scratch**

```bash
cd /tmp/anvil-v2-scratch
rm -rf apm_modules .apm apm.lock.yaml .claude .github .cursor .opencode
apm init --yes
mkdir -p .claude .github .cursor .opencode
apm install /var/home/olino3/git/anvil/packages/anvil-core-stable --target all
```

Expected: exit 0; output mentions installing both `anvil-core-stable` AND its transitive dep `anvil-common-stable`.

- [ ] **Step 2: Verify compiled agent files for each host**

```bash
ls .claude/agents/    # expect: red.md, green.md, dev-discipline.md, pd.md, pm.md, ba.md, sprint-syncer.md
ls .github/agents/    # expect: *.agent.md versions of the same
ls .cursor/agents/    # expect: *.md
ls .opencode/agents/  # expect: *.md
```

Expected: each directory contains seven agent files.

- [ ] **Step 3: Verify compiled prompts and slash commands**

```bash
ls .claude/commands/anvil/  # expect: init.md, roadmap.md, sprint.md, develop.md, plan-ticket.md, red.md, green.md, refactor.md, review.md, sync.md, status.md
ls .github/prompts/         # expect: 11 *.prompt.md files
ls .opencode/commands/      # expect: 11 *.md files
```

Expected: each host has eleven prompts compiled to its native location.

- [ ] **Step 4: Verify compiled skills**

```bash
ls .claude/skills/   # expect: 7 anvil-* dirs + 5 from common (roadmap-format, sprint-readme-format, ticket-template, ba-report-format, anvil-config-schema)
```

Expected: twelve skill directories total.

- [ ] **Step 5: Verify `apm run` script registration**

```bash
apm list
```

Expected: shows 11 `anvil:*` scripts.

- [ ] **Step 6: Smoke-test one script compilation**

```bash
apm preview anvil:red --param ticket=TEST-001
```

Expected: prints the RED prompt body with `${input:ticket}` substituted to `TEST-001`.

- [ ] **Step 7: Clean scratch**

```bash
rm -rf apm_modules .apm apm.lock.yaml .claude .github .cursor .opencode
```

Expected: scratch returned to baseline.

- [ ] **Step 8: No commit; validation only.**

---

## Phase 3 — Build `anvil-orchestrator-stable`

Single-stage automation on top of core. Depends on common + core.

### Task 3.1: Scaffold the package

**Files:**
- Create: `packages/anvil-orchestrator-stable/apm.yml`
- Create: `packages/anvil-orchestrator-stable/.apm/agents/`
- Create: `packages/anvil-orchestrator-stable/.apm/skills/`
- Create: `packages/anvil-orchestrator-stable/.apm/prompts/`

- [ ] **Step 1: Create directories**

```bash
cd /var/home/olino3/git/anvil
mkdir -p packages/anvil-orchestrator-stable/.apm/agents
mkdir -p packages/anvil-orchestrator-stable/.apm/skills
mkdir -p packages/anvil-orchestrator-stable/.apm/prompts
```

Expected: `ls packages/anvil-orchestrator-stable/.apm` shows three directories.

- [ ] **Step 2: Write apm.yml**

Write to `packages/anvil-orchestrator-stable/apm.yml`:

```yaml
name: anvil-orchestrator-stable
version: 2.0.0
description: Anvil orchestrator — high-level human-in-the-loop automation for sprint TDD. One stage, one approval, full inner loop.
author: Olino3
license: MIT
dependencies:
  apm:
    - /var/home/olino3/git/anvil/packages/anvil-common-stable
    - /var/home/olino3/git/anvil/packages/anvil-core-stable
  mcp: []
scripts:
  anvil:develop: anvil-develop.prompt.md
  anvil:sprint: anvil-sprint.prompt.md
  anvil:roadmap: anvil-roadmap.prompt.md
  anvil:review: anvil-review.prompt.md
```

- [ ] **Step 3: Commit**

```bash
git add packages/anvil-orchestrator-stable/
git commit -m "feat(orchestrator): scaffold anvil-orchestrator-stable package"
```

Expected: commit created.

### Task 3.2: Author develop-orchestrator.agent.md

**Files:**
- Create: `packages/anvil-orchestrator-stable/.apm/agents/develop-orchestrator.agent.md`

- [ ] **Step 1: Write develop-orchestrator.agent.md**

Write to `packages/anvil-orchestrator-stable/.apm/agents/develop-orchestrator.agent.md`:

```markdown
---
name: develop-orchestrator
description: One-ticket automation — auto-creates worktree, produces plan, asks for approval, then runs RED → GREEN → (optional REFACTOR) → verification → integration-choice with single-level sub-agent dispatch.
author: Olino3
version: "2.0.0"
---

# Develop Orchestrator

You are the Develop Orchestrator. Your job is to drive the full inner loop of
implementing a single sprint ticket: plan, dispatch RED, dispatch GREEN,
optionally REFACTOR, run verification, present the integration choice, and
execute it. The human approves once (the plan) and optionally selects the
integration choice at the end. Everything else is automatic.

You use **single-level sub-agent dispatch only**: you dispatch `@red` and
`@green` (from `anvil-core-stable`), and you never dispatch other
orchestrators.

## Inputs

- The target ticket ID

## Workflow

### Phase 0: Prep

1. Execute the logic from core's `anvil-develop.prompt.md` Steps 1-5:
   locate ticket, verify config, read sprint context, verify branch,
   auto-create worktree per `worktree-discipline` (from anvil-common-stable).
2. `cd` into the worktree.

### Phase 1: Plan

3. Invoke `dev-discipline.agent` (from anvil-core-stable) to produce a plan
   and ask for approval. Stop and wait.

### Phase 2: Execute

4. On approval, dispatch `@red <ticket>` (core's `red.agent`). Wait for
   completion. Inspect the resulting `test(...)` commit. If the commit is
   missing or the tests do not fail for the right reason, stop and report —
   do not proceed to GREEN.

5. Dispatch `@green <ticket>` (core's `green.agent`). Wait for completion.
   Inspect the resulting `feat(...)` or `fix(...)` commit. If the commit is
   missing or tests still fail, stop and report.

6. **If refactor is warranted**, invoke core's `anvil-refactor.prompt.md`
   inline (no dedicated agent). Run until completion of that prompt's Step
   3 (the refactor commit). Stop there — do NOT proceed to the refactor
   prompt's own integration-choice step.

### Phase 3: Verify

7. Run every command in the ticket's Verification Steps section. If any
   fails, stop and report — do not apply the integration choice.

### Phase 4: Ticket + README update

8. Update the ticket file: Status → Done, check satisfied acceptance
   criteria.
9. Update the sprint README's tickets table and status summary.

### Phase 5: Integrate

10. Present the five-option integration-choice matrix from
    `worktree-discipline`. Wait for the user's choice.
11. Execute the chosen option's git operations and cleanup per
    `worktree-discipline`.

## Constraints

- **Single-level dispatch only.** Never dispatch another orchestrator.
- **Fallback on hosts that cannot dispatch.** If `@red` or `@green` cannot
  be dispatched (host limitation), inline the body of core's
  `anvil-red.prompt.md` / `anvil-green.prompt.md` into your own context
  and execute it there. Record this in your output summary as
  "dispatch unavailable — inlined {agent}".
- **Do not expand ticket scope.** Create SPIKEs per the `ticket-template`
  skill for out-of-scope discoveries.

## Success Criteria

- Plan approved, RED commit, GREEN commit, optional REFACTOR commit
- All verification steps pass
- Ticket set to Done; sprint README updated
- Integration choice executed; worktree state matches the user's choice
```

- [ ] **Step 2: Commit**

```bash
git add packages/anvil-orchestrator-stable/.apm/agents/develop-orchestrator.agent.md
git commit -m "feat(orchestrator): add develop-orchestrator agent"
```

Expected: commit created.

### Task 3.3: Author sprint-orchestrator.agent.md

**Files:**
- Create: `packages/anvil-orchestrator-stable/.apm/agents/sprint-orchestrator.agent.md`

- [ ] **Step 1: Write sprint-orchestrator.agent.md**

Write to `packages/anvil-orchestrator-stable/.apm/agents/sprint-orchestrator.agent.md`:

```markdown
---
name: sprint-orchestrator
description: Generate a sprint by invoking the pm agent, then optionally hand off to develop-orchestrator for the first unblocked ticket. No multi-ticket loop.
author: Olino3
version: "2.0.0"
---

# Sprint Orchestrator

You are the Sprint Orchestrator. Your job is to generate a sprint for a
ROADMAP phase, then offer a single handoff: develop the first unblocked
ticket now, or stop.

You **do not** walk the dep graph and develop every ticket. That behavior is
reserved for `anvil-autonomous-stable` (future package).

## Inputs

- The target phase (by name, number, or prefix)

## Workflow

1. **Invoke `@pm` agent** (from anvil-core-stable) to generate the sprint for
   the given phase. Follow the procedure in `anvil-sprint` skill; use
   `sprint-readme-format` and `ticket-template` (from anvil-common-stable)
   for target structures. The `@pm` agent creates the sprint directory,
   ticket files, and sprint README, and the sprint feature branch.

2. **Report the result.** Print the sprint directory path, the count of
   tickets by type, and which tickets are immediately unblocked (no pending
   dependencies).

3. **Offer the one-ticket handoff.** Ask the user:
   > *"Develop `<first-unblocked-ticket-id>` now?"*

4. **If yes:** invoke `@develop-orchestrator <first-unblocked-ticket-id>`
   (inline — this is a control-flow handoff, not a nested sub-agent
   dispatch; execute the develop-orchestrator prompt in your current
   context). Wait for its completion and report. Stop after this one
   ticket.

5. **If no:** stop. Print the recommended next command:
   `/anvil:develop <first-unblocked-ticket-id>`.

## Constraints

- **One ticket only.** No multi-ticket loop. If the user asks for
  auto-develop-every-ticket, report that the feature is reserved for
  `anvil-autonomous-stable`.
- **Never dispatch another orchestrator as a sub-agent.** The handoff to
  develop-orchestrator is inline prompt execution, not dispatch.

## Success Criteria

- Sprint directory exists with tickets and README
- Sprint feature branch created
- Optional one-ticket develop-orchestrator run completed (if user accepted)
- Clear next-step guidance reported
```

- [ ] **Step 2: Commit**

```bash
git add packages/anvil-orchestrator-stable/.apm/agents/sprint-orchestrator.agent.md
git commit -m "feat(orchestrator): add sprint-orchestrator agent"
```

Expected: commit created.

### Task 3.4: Author roadmap-orchestrator.agent.md

**Files:**
- Create: `packages/anvil-orchestrator-stable/.apm/agents/roadmap-orchestrator.agent.md`

- [ ] **Step 1: Write roadmap-orchestrator.agent.md**

Write to `packages/anvil-orchestrator-stable/.apm/agents/roadmap-orchestrator.agent.md`:

```markdown
---
name: roadmap-orchestrator
description: Invoke the pd agent to create or update ROADMAP.md, then optionally hand off to sprint-orchestrator for the current phase.
author: Olino3
version: "2.0.0"
---

# Roadmap Orchestrator

You are the Roadmap Orchestrator. Your job is to run the `@pd` (Product
Director) conversation, and at the end offer a single handoff: kick off a
sprint for the current phase.

## Inputs

- None (conversational)

## Workflow

1. **Invoke `@pd` agent** (from anvil-core-stable). Follow `anvil-roadmap`
   skill procedure; use `roadmap-format` (from anvil-common-stable). The
   `@pd` agent conducts the conversation and writes / updates `ROADMAP.md`.

2. **Report the result.** Print which phase is "current" (the first phase
   that is not marked Complete) and its prefix.

3. **Offer the sprint handoff.** Ask:
   > *"Kick off a sprint for phase `<current-phase>` now?"*

4. **If yes:** invoke `@sprint-orchestrator <current-phase>` inline (prompt
   execution, not nested dispatch). Wait for completion. Stop.

5. **If no:** stop. Print the recommended next command:
   `/anvil:sprint <current-phase>`.

## Constraints

- **Single handoff only.** One roadmap conversation, one optional sprint
  kickoff. Do not chain further.
- **Never dispatch another orchestrator as a sub-agent.** Handoff is
  inline prompt execution.

## Success Criteria

- `ROADMAP.md` updated
- Optional sprint-orchestrator run completed (if user accepted)
- Clear next-step guidance reported
```

- [ ] **Step 2: Commit**

```bash
git add packages/anvil-orchestrator-stable/.apm/agents/roadmap-orchestrator.agent.md
git commit -m "feat(orchestrator): add roadmap-orchestrator agent"
```

Expected: commit created.

### Task 3.5: Author review-orchestrator.agent.md

**Files:**
- Create: `packages/anvil-orchestrator-stable/.apm/agents/review-orchestrator.agent.md`

- [ ] **Step 1: Write review-orchestrator.agent.md**

Write to `packages/anvil-orchestrator-stable/.apm/agents/review-orchestrator.agent.md`:

```markdown
---
name: review-orchestrator
description: Invoke the ba agent to produce BA-REPORT.md, then apply the recommended cleanup actions with a single approval.
author: Olino3
version: "2.0.0"
---

# Review Orchestrator

You are the Review Orchestrator. Your job is to run the `@ba` sprint-health
analysis and then **apply** its recommended cleanup actions (ticket splits,
archival, dependency healing, status corrections) with a single user
approval gate.

Core's `@ba` agent only reports; this orchestrator is what closes the loop.

## Inputs

- The target sprint phase (name, version, or prefix)

## Workflow

1. **Invoke `@ba` agent** (from anvil-core-stable). It produces
   `BA-REPORT.md` in the sprint directory following `ba-report-format`
   (from anvil-common-stable). No file changes beyond the report.

2. **Present the recommendations.** Read BA-REPORT's "Recommended actions"
   section. Print the full list to the user, grouped by action type:
   - Ticket splits (ticket X → X.1, X.2 because criteria count exceeded 8)
   - Archival (tickets superseded or cut from scope)
   - Dependency healing (missing `Blocks:` ↔ `Depends on:` pairs)
   - Status corrections (Done tickets whose verification failed, etc.)

3. **Single approval gate.** Ask:
   > *"Apply all recommended actions? (y/N)"*

4. **If approved:** apply every action. Use `ticket-template` and
   `sprint-readme-format` (from anvil-common-stable) for any file
   modifications. After applying, invoke `@sprint-syncer <phase>`
   (from anvil-core-stable) to rebuild the sprint README.

5. **If declined:** stop. Print: `BA-REPORT.md written; no actions applied.`
   Suggest the user review the report and either apply actions manually
   or re-invoke review-orchestrator later.

## Constraints

- **All-or-nothing approval.** The user approves the full recommendation
  set, or none of it. No partial application in v2.0.0.
- **Never auto-downgrade a Done ticket.** If BA reports a Done ticket's
  verification failed, flag it loudly but do not change Status.

## Success Criteria

- `BA-REPORT.md` written
- Either: all recommendations applied and sprint README synced,
  OR: user declined and no changes beyond the report
```

- [ ] **Step 2: Commit**

```bash
git add packages/anvil-orchestrator-stable/.apm/agents/review-orchestrator.agent.md
git commit -m "feat(orchestrator): add review-orchestrator agent"
```

Expected: commit created.

### Task 3.6: Author orchestration-gates skill

**Files:**
- Create: `packages/anvil-orchestrator-stable/.apm/skills/orchestration-gates/SKILL.md`

- [ ] **Step 1: Write the skill**

```bash
mkdir -p packages/anvil-orchestrator-stable/.apm/skills/orchestration-gates
```

Write to `.../orchestration-gates/SKILL.md`:

```markdown
---
name: orchestration-gates
description: When an orchestrator pauses for user approval or reports an error, and how to resume from the pause point. Applies to all four anvil-orchestrator agents.
user-invocable: false
---

# Orchestration Gates

The four orchestrator agents in anvil-orchestrator-stable each pause at
well-defined gates. This skill documents when a gate fires and how to
resume from it.

## Approval gates (single-approval-per-stage)

| Orchestrator | Gate location | Question |
|---|---|---|
| develop-orchestrator | After plan is produced | "Proceed with this plan?" |
| develop-orchestrator | After all work complete | Integration choice: squash / merge / PR / keep / discard |
| sprint-orchestrator | After sprint generated | "Develop `<ticket>` now?" |
| roadmap-orchestrator | After roadmap saved | "Kick off a sprint for `<phase>` now?" |
| review-orchestrator | After BA-REPORT written | "Apply all recommended actions?" |

Approving advances the orchestrator through the next phase of its workflow.
Declining stops the orchestrator cleanly.

## Error gates (orchestrator stops and reports)

- **develop-orchestrator**: RED commit missing, or tests fail for the wrong
  reason after RED.
- **develop-orchestrator**: GREEN commit missing, or tests still fail after
  GREEN.
- **develop-orchestrator**: verification step in ticket fails after REFACTOR.
- **All orchestrators**: ticket/sprint/config file missing or malformed.

On an error gate, the orchestrator stops, reports the problem, and does
**not** proceed. It does not auto-retry. The user investigates and decides
the next step.

## Resuming from a pause

Approval gates: simply respond with approval or rejection in the current
session. There is no "resume" — the orchestrator is waiting synchronously.

Error gates: after the user fixes the problem (edits the ticket, fixes the
test, corrects config), they re-invoke the orchestrator from the top —
orchestrators are idempotent where possible. For develop-orchestrator
specifically: if a worktree already exists for the ticket, it is reused.

## What this skill is NOT

- Not a sub-agent dispatch manager. Orchestrators dispatch `@red` and
  `@green` directly.
- Not a checkpoint or resumable-state system. v2.0.0 orchestrators are
  session-scoped; there is no persistence across process restarts.
```

- [ ] **Step 2: Commit**

```bash
git add packages/anvil-orchestrator-stable/.apm/skills/orchestration-gates/
git commit -m "feat(orchestrator): add orchestration-gates skill"
```

Expected: commit created.

### Task 3.7: Author the four orchestrator override prompts

**Files:**
- Create: `packages/anvil-orchestrator-stable/.apm/prompts/anvil-develop.prompt.md`
- Create: `packages/anvil-orchestrator-stable/.apm/prompts/anvil-sprint.prompt.md`
- Create: `packages/anvil-orchestrator-stable/.apm/prompts/anvil-roadmap.prompt.md`
- Create: `packages/anvil-orchestrator-stable/.apm/prompts/anvil-review.prompt.md`

Each prompt is a thin wrapper that invokes the corresponding orchestrator agent. They override core's prompts at the compiled paths (last-writer-wins verified in Task 0.2).

- [ ] **Step 1: anvil-develop.prompt.md (override)**

Write:

```markdown
---
description: Automated one-ticket TDD loop. Locate ticket, auto-worktree, plan, approval, RED → GREEN → optional REFACTOR → verification → integration choice.
input:
  - ticket: "Ticket ID (e.g., MVP-001)"
---

# Anvil Develop — Orchestrated

Invoke the `@develop-orchestrator` agent for ticket `${input:ticket}`.

Follow the workflow in `develop-orchestrator.agent.md`. Honor the approval
gates documented in the `orchestration-gates` skill.

On completion, report: commits created, files modified, integration choice
executed, and whether any SPIKE tickets were created.
```

- [ ] **Step 2: anvil-sprint.prompt.md (override)**

Write:

```markdown
---
description: Generate a sprint for a ROADMAP phase and optionally hand off to develop-orchestrator for the first unblocked ticket.
input:
  - phase: "Phase name, number, or prefix"
---

# Anvil Sprint — Orchestrated

Invoke the `@sprint-orchestrator` agent for phase `${input:phase}`.

Follow the workflow in `sprint-orchestrator.agent.md`. Honor the
one-ticket-handoff approval gate.

No multi-ticket loop. If the user wants auto-develop-every-ticket, report
that the feature is reserved for anvil-autonomous-stable.
```

- [ ] **Step 3: anvil-roadmap.prompt.md (override)**

Write:

```markdown
---
description: Create or update ROADMAP.md and optionally hand off to sprint-orchestrator for the current phase.
input: []
---

# Anvil Roadmap — Orchestrated

Invoke the `@roadmap-orchestrator` agent.

Follow the workflow in `roadmap-orchestrator.agent.md`. Honor the sprint-
handoff approval gate.
```

- [ ] **Step 4: anvil-review.prompt.md (override)**

Write:

```markdown
---
description: Sprint health + verification + auto-apply cleanup actions with a single approval.
input:
  - phase: "Phase name, version, or prefix"
---

# Anvil Review — Orchestrated

Invoke the `@review-orchestrator` agent for phase `${input:phase}`.

Follow the workflow in `review-orchestrator.agent.md`. Honor the
all-or-nothing approval gate for applying cleanup actions.
```

- [ ] **Step 5: Commit all four**

```bash
git add packages/anvil-orchestrator-stable/.apm/prompts/
git commit -m "feat(orchestrator): author four override prompts (develop, sprint, roadmap, review)"
```

Expected: commit created; `ls packages/anvil-orchestrator-stable/.apm/prompts/` shows four files.

### Task 3.8: Validate orchestrator override works as designed

**Files:**
- Use scratch at `/tmp/anvil-v2-scratch`

- [ ] **Step 1: Fresh install of orchestrator (which should transitively pull core + common)**

```bash
cd /tmp/anvil-v2-scratch
rm -rf apm_modules .apm apm.lock.yaml .claude .github .cursor .opencode
apm init --yes
mkdir -p .claude .github .cursor .opencode
apm install /var/home/olino3/git/anvil/packages/anvil-orchestrator-stable --target all
```

Expected: exit 0. Output mentions installing all three packages.

- [ ] **Step 2: Check that the four overridden commands now contain orchestrator content (not core)**

```bash
grep -l "develop-orchestrator" .claude/commands/anvil/develop.md
grep -l "sprint-orchestrator" .claude/commands/anvil/sprint.md
grep -l "roadmap-orchestrator" .claude/commands/anvil/roadmap.md
grep -l "review-orchestrator" .claude/commands/anvil/review.md
```

Expected: all four greps return the file paths (the strings are present). If any file contains `dev-discipline` instead of `develop-orchestrator`, the override failed — return to Task 0.2 and switch to the distinct-command-names fallback.

- [ ] **Step 3: Check that non-overridden core commands remain untouched**

```bash
grep -l "@red" .claude/commands/anvil/red.md
grep -l "@green" .claude/commands/anvil/green.md
grep -l "self-contained refactor" .claude/commands/anvil/refactor.md
ls .claude/commands/anvil/
```

Expected: red/green/refactor/init/sync/status/plan still present (core versions), plus the four overridden ones.

- [ ] **Step 4: Uninstall orchestrator; confirm core re-deploys correctly**

```bash
apm uninstall /var/home/olino3/git/anvil/packages/anvil-orchestrator-stable
grep -l "dev-discipline" .claude/commands/anvil/develop.md
grep -l "pm" .claude/commands/anvil/sprint.md
```

Expected: develop.md now contains core's "dev-discipline" content; sprint.md contains core's `@pm` content.

- [ ] **Step 5: Clean scratch**

```bash
rm -rf apm_modules .apm apm.lock.yaml .claude .github .cursor .opencode
```

- [ ] **Step 6: No commit; validation only.**

---

## Phase 4 — Repo-level files (marketplace, README, workflows, contributing)

### Task 4.1: Write the new `marketplace.json`

**Files:**
- Create: `marketplace.json` (repo root)

- [ ] **Step 1: Write marketplace.json**

Write to `marketplace.json`:

```json
{
  "name": "anvil",
  "owner": {
    "name": "Olino3"
  },
  "metadata": {
    "pluginRoot": "./packages"
  },
  "plugins": [
    {
      "name": "anvil-core-stable",
      "source": "anvil-core-stable",
      "description": "Anvil discipline — agents, skills, and parameterized prompts for human-driven sprint TDD. No dispatch."
    },
    {
      "name": "anvil-orchestrator-stable",
      "source": "anvil-orchestrator-stable",
      "description": "Anvil orchestrator — high-level human-in-the-loop automation for sprint TDD. One stage, one approval, full inner loop."
    },
    {
      "name": "anvil-common-stable",
      "source": "anvil-common-stable",
      "description": "Internal — shared primitives for Anvil (formats, templates, TDD / commit / worktree discipline). Installed transitively.",
      "internal": true
    }
  ]
}
```

**Note:** `"internal": true` on anvil-common-stable is a best-effort signal per the spec. APM's marketplace browse/search behavior around this flag is implementation-dependent; if it is silently ignored, the package still appears but is documented as transitive-only. No code change needed in that case.

- [ ] **Step 2: Commit**

```bash
git add marketplace.json
git commit -m "feat: add repo-root marketplace.json for three-package model"
```

Expected: commit created.

### Task 4.2: Write the workspace-level `apm.yml`

**Files:**
- Modify: `apm.yml` (repo root, currently a comment-only shim)

- [ ] **Step 1: Replace the shim with a workspace manifest**

Write to `apm.yml` (overwrite):

```yaml
name: anvil-workspace
version: 2.0.0
description: Anvil monorepo — three-package marketplace. Install packages individually via marketplace.json.
author: Olino3
license: MIT

# This manifest exists for contributors. End users install packages via:
#   apm marketplace add Olino3/anvil
#   apm install anvil-core-stable@anvil           # or anvil-orchestrator-stable
#
# The packages/ subdirectories are individual APM packages. See marketplace.json.

dependencies:
  apm: []
  mcp: []

scripts: {}
```

- [ ] **Step 2: Commit**

```bash
git add apm.yml
git commit -m "chore: replace shim apm.yml with workspace manifest"
```

Expected: commit created.

### Task 4.3: Rewrite the README

**Files:**
- Modify: `README.md` (full rewrite)

- [ ] **Step 1: Write the new README**

Write to `README.md` (overwrite):

```markdown
# Anvil

Language-agnostic plugin marketplace for agentic sprint-driven software
development using TDD. Authored as [APM](https://microsoft.github.io/apm/)
packages, compiled to Claude Code, Copilot CLI, Cursor, and OpenCode.

## Two flavors

**anvil-core-stable** — the discipline. Every step is a slash command or
`apm run` script; you orchestrate. Choose this if you want maximum control
and explicit approval at every sub-step.

**anvil-orchestrator-stable** — automated inner loop. One command, one
approval, the full RED → GREEN → REFACTOR → integration flow runs. Choose
this for the closest match to the v1.x Anvil experience.

## Install

**APM (recommended):**

```bash
apm marketplace add Olino3/anvil
apm install anvil-core-stable@anvil              # discipline only
apm install anvil-orchestrator-stable@anvil      # auto-installs core + common
```

**Claude Code:**

```bash
claude /plugin marketplace add https://github.com/Olino3/anvil.git
claude /plugin install anvil-core-stable
# or
claude /plugin install anvil-orchestrator-stable
```

**Pre-built plugin bundles** (no APM required):

Download a `.tar.gz` from the [latest release](https://github.com/Olino3/anvil/releases/latest)
matching your host (`claude`, `copilot`, `cursor`, `opencode`) and package.
Extract into your project. Example:

```bash
curl -LO https://github.com/Olino3/anvil/releases/latest/download/anvil-orchestrator-stable-2.0.0-claude.tar.gz
tar xzf anvil-orchestrator-stable-2.0.0-claude.tar.gz -C .
```

## Upgrading from v1.x

v2.0.0 is a **hard cut** from the old `anvil` plugin layout. There is no
automatic upgrade path; re-install under the new names:

| v1.x | v2.0.0 equivalent |
|---|---|
| `claude /plugin install anvil` | `claude /plugin install anvil-orchestrator-stable` |
| `apm install anvil@anvil-plugins` | `apm install anvil-orchestrator-stable@anvil` |
| (no equivalent in v1.x) | `apm install anvil-core-stable@anvil` |

The sprint directory (`docs/anvil/sprints/...`), ROADMAP.md, and config
(`docs/anvil/config.yml`) formats are unchanged in v2.0.0.

## Quick start

```bash
/anvil:init                   # detect stack, write config
/anvil:roadmap                # create ROADMAP.md (pd-agent conversation)
/anvil:sprint MVP             # break phase into tickets (pm-agent)
/anvil:develop MVP-001        # implement ticket (behavior depends on installed package)
/anvil:review MVP             # sprint health + verification
```

## Commands

| Command | anvil-core-stable | anvil-orchestrator-stable |
|---|---|---|
| `/anvil:init` | interactive setup | same |
| `/anvil:roadmap` | pd conversation | pd conversation + optional sprint handoff |
| `/anvil:sprint <phase>` | pm generates sprint | pm + optional one-ticket handoff |
| `/anvil:develop <ticket>` | locate + worktree + plan, then stop | full inner loop: plan → RED → GREEN → REFACTOR → integration |
| `/anvil:red <ticket>` | whole-ticket failing suite | same (from core) |
| `/anvil:green <ticket>` | whole-ticket minimum code | same (from core) |
| `/anvil:refactor <ticket>` | self-contained refactor + integration choice | same (from core) |
| `/anvil:review <phase>` | ba reports; no auto-apply | ba + auto-apply cleanup with approval |
| `/anvil:sync <phase>` | rebuild sprint README | same (from core) |
| `/anvil:status [phase]` | read-only summary | same (from core) |

Every command is also available as `apm run anvil:<stage> --param ...`.

## `.gitignore` guidance

`apm_modules/` is usually ignored. Add this to `.gitignore`:

```
apm_modules/
.worktrees/
```

Commit `apm_modules/` only if (a) your CI cannot run `apm install`, or
(b) you have context links between primitives that need to resolve in
git-indexed files.

## Agents

| Agent | Source package | Role |
|---|---|---|
| `@pd` | core | Product Director — roadmap |
| `@pm` | core | Project Manager — sprint tickets |
| `@ba` | core | Business Analyst — sprint health |
| `@sprint-syncer` | core | Rebuild sprint README |
| `@red` | core | Whole-ticket failing test suite |
| `@green` | core | Whole-ticket minimum implementation |
| `@dev-discipline` | core | Plan and approve (no dispatch) |
| `@develop-orchestrator` | orchestrator | One-ticket automation |
| `@sprint-orchestrator` | orchestrator | Sprint generate + optional handoff |
| `@roadmap-orchestrator` | orchestrator | Roadmap + optional sprint handoff |
| `@review-orchestrator` | orchestrator | Review + auto-apply cleanup |

## Workflow playbook

For the full day-to-day playbook — greenfield loop, course corrections,
drift recovery, parallel tickets — see
[`shared/Workflows.md`](shared/Workflows.md).

## Contributing

See [`shared/CONTRIBUTING.md`](shared/CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: rewrite README for three-package model and v1→v2 migration"
```

Expected: commit created.

### Task 4.4: Move and rewrite Workflows.md

**Files:**
- Create: `shared/Workflows.md`
- Delete: `Workflows.md` (root)

- [ ] **Step 1: Create shared/ directory and move Workflows**

```bash
cd /var/home/olino3/git/anvil
mkdir -p shared
git mv Workflows.md shared/Workflows.md
```

Expected: `git status` shows `renamed: Workflows.md -> shared/Workflows.md`.

- [ ] **Step 2: Rewrite shared/Workflows.md for the three-package model**

Read the existing content:

```bash
cat shared/Workflows.md | head -50
```

Rewrite the top paragraph and the "Commands at a glance" table to reflect
that commands now come from two packages (core or orchestrator) and
behavior depends on which is installed. Leave the per-workflow recipes
(1.1–3.3) intact but update any step that said "dev-agent dispatches
red-agent" to say "orchestrator dispatches @red (with anvil-orchestrator-stable
installed) or the user invokes `/anvil:red` explicitly (with anvil-core-stable
only)".

Update the "Artifact map" table: `/anvil:develop` writes depend on the
installed package (core: worktree + plan only; orchestrator: full inner loop).

At the top, add a new introduction paragraph:

```markdown
## Which package is this playbook for?

Most workflows work identically for either `anvil-core-stable` or
`anvil-orchestrator-stable`. Where behavior differs, the recipe notes the
distinction with **[core]** / **[orchestrator]** tags.
```

- [ ] **Step 3: Commit**

```bash
git add shared/Workflows.md
git commit -m "docs: rewrite Workflows.md for three-package model"
```

Expected: commit created.

### Task 4.5: Write CONTRIBUTING.md

**Files:**
- Create: `shared/CONTRIBUTING.md`

- [ ] **Step 1: Write CONTRIBUTING.md**

Write to `shared/CONTRIBUTING.md`:

```markdown
# Contributing to Anvil

Anvil is a monorepo of three APM packages under `packages/`. This guide is
for maintainers and contributors; end users should read the main
[README.md](../README.md).

## Layout

```
packages/
├── anvil-common-stable/      # shared formats, templates, instructions
├── anvil-core-stable/        # discipline — agents, skills, prompts, no dispatch
└── anvil-orchestrator-stable/ # single-stage automation on top of core
```

Every package has `apm.yml` and `.apm/`. `.apm/` is the APM source root;
outputs (`.claude/`, `.github/`, `.cursor/`, `.opencode/`) are compiled
artifacts and never edited by hand.

Maintainer-facing docs live under `shared/` (this file, `Workflows.md`,
`specs/`). APM never reads this directory.

## Local development

Use a scratch APM project outside this repo as a consumer. Install packages
from this repo via local paths:

```bash
# In your scratch project
apm install /path/to/anvil/packages/anvil-core-stable --target all
# or
apm install /path/to/anvil/packages/anvil-orchestrator-stable --target all
```

Transitive deps resolve via the local path declarations in each package's
`apm.yml`. When editing a file in common and testing the effect on core or
orchestrator, re-run `apm install` in the scratch project.

## Before opening a PR

1. **All three packages install cleanly into a scratch project.** Install
   one package at a time; verify `apm list` shows the expected scripts and
   the compiled files appear under the target directories.
2. **Override behavior works as designed.** If you touched orchestrator's
   prompts, verify that installing orchestrator overrides core's compiled
   paths (see the verification log: `shared/specs/verification-log.md`).
3. **No root path leaks.** Absolute paths like
   `/var/home/olino3/git/anvil/packages/...` in `apm.yml` files are
   maintainer-local conveniences. Before release, Task 8.2 rewrites them
   to `Olino3/anvil/packages/...` form. Do not introduce new absolute-path
   deps outside what Task 8.2 handles.
4. **TDD discipline applies to the package content itself where tests
   make sense.** Prompts and agents are prose, not code — review for
   consistency with the spec at `shared/specs/2026-04-23-apm-first-marketplace-design.md`.

## Spec-driven changes

Anvil's design is in `shared/specs/YYYY-MM-DD-*.md`. Significant
behavioral changes need a spec update first. Small additions (new skill,
new reference doc) can go straight to a PR.

## Release

See `shared/specs/2026-04-23-apm-first-marketplace-design.md` §
"Release sequence" and `.github/workflows/release.yml`.
```

- [ ] **Step 2: Commit**

```bash
git add shared/CONTRIBUTING.md
git commit -m "docs: add shared/CONTRIBUTING.md"
```

Expected: commit created.

---

## Phase 5 — Delete the v1.x layout (the hard cut)

### Task 5.1: Delete `plugins/anvil/` and old marketplace.json

**Files:**
- Delete: `plugins/anvil/` (entire subtree)
- Delete: `.claude-plugin/marketplace.json`
- Delete: `.claude-plugin/` (empty after above)

- [ ] **Step 1: Confirm the new layout is in place before deleting the old one**

```bash
cd /var/home/olino3/git/anvil
ls packages/  # expect: anvil-common-stable, anvil-core-stable, anvil-orchestrator-stable
ls marketplace.json apm.yml README.md shared/  # all exist
```

Expected: all four listed items exist. If any are missing, stop and complete earlier phases first.

- [ ] **Step 2: Delete the old tree**

```bash
git rm -r plugins/
git rm -r .claude-plugin/
```

Expected: `git status` shows many deletions.

- [ ] **Step 3: Commit the hard cut**

```bash
git commit -m "feat!: remove v1.x plugin layout — hard cut to v2.0.0 APM-first model

BREAKING CHANGE: the 'anvil' plugin name no longer exists.
Users must install 'anvil-core-stable' or 'anvil-orchestrator-stable'
from the repo-root marketplace.json. See README.md for the v1→v2 mapping."
```

Expected: commit created. `git show --stat HEAD | head` reports deletions of `plugins/anvil/*` and `.claude-plugin/marketplace.json`.

---

## Phase 6 — End-to-end validation

### Task 6.1: Fresh consumer install from local repo

**Files:**
- Use scratch at `/tmp/anvil-v2-scratch`

- [ ] **Step 1: Fresh scratch with local marketplace**

```bash
cd /tmp/anvil-v2-scratch
rm -rf apm_modules .apm apm.lock.yaml .claude .github .cursor .opencode
apm init --yes
apm marketplace add /var/home/olino3/git/anvil --name anvil-local
mkdir -p .claude .github .cursor .opencode
apm install anvil-orchestrator-stable@anvil-local --target all
```

Expected: exit 0. Lockfile entries for all three packages.

- [ ] **Step 2: Smoke-test critical compiled artifacts**

```bash
# Agents
test -f .claude/agents/red.md && echo "red OK"
test -f .claude/agents/green.md && echo "green OK"
test -f .claude/agents/develop-orchestrator.md && echo "develop-orchestrator OK"

# Commands (Claude)
test -f .claude/commands/anvil/develop.md && echo "develop cmd OK"
test -f .claude/commands/anvil/red.md && echo "red cmd OK"

# Skills
test -d .claude/skills/ticket-template && echo "ticket-template OK"
test -d .claude/skills/anvil-develop && echo "anvil-develop skill OK"
test -d .claude/skills/orchestration-gates && echo "orchestration-gates OK"

# Copilot
test -f .github/agents/red.agent.md && echo "copilot red OK"
test -f .github/prompts/anvil-develop.prompt.md && echo "copilot develop OK"

# Cursor
test -f .cursor/agents/red.md && echo "cursor red OK"

# OpenCode
test -f .opencode/agents/red.md && echo "opencode red OK"
test -f .opencode/commands/anvil-develop.md && echo "opencode develop cmd OK"
```

Expected: every `echo` line prints. If any fails, the corresponding package's compilation is broken — back up to that package's validation task.

- [ ] **Step 3: apm list**

```bash
apm list
```

Expected: shows 11 `anvil:*` scripts (core + four orchestrator overrides merged).

- [ ] **Step 4: Verify override content**

```bash
grep -q "develop-orchestrator" .claude/commands/anvil/develop.md && echo "develop override: orchestrator content OK"
grep -q "@red" .claude/commands/anvil/red.md && echo "red not overridden, core content OK"
```

Expected: both `echo` lines print.

- [ ] **Step 5: Clean up scratch**

```bash
rm -rf apm_modules .apm apm.lock.yaml .claude .github .cursor .opencode
```

- [ ] **Step 6: No commit; validation only.**

### Task 6.2: Real Anvil workflow on scratch (core path)

Run an actual Anvil flow end-to-end on the scratch project with core-only.
This is the smoke test that the content itself still works.

**Files:**
- Use scratch at `/tmp/anvil-v2-scratch`

- [ ] **Step 1: Install core only into scratch**

```bash
cd /tmp/anvil-v2-scratch
rm -rf apm_modules .apm apm.lock.yaml .claude .github .cursor .opencode
mkdir -p .claude
apm init --yes
apm install anvil-core-stable@anvil-local --target claude
```

Expected: exit 0; `.claude/commands/anvil/develop.md` exists and contains core's plan-and-stop content.

- [ ] **Step 2: In Claude Code, run `/anvil:init` in the scratch project**

Open the scratch project in Claude Code. Invoke `/anvil:init`. Work through
the interactive config. Expected: `docs/anvil/config.yml` is written.

- [ ] **Step 3: Run `/anvil:roadmap` and create a minimal ROADMAP.md**

Example prompts to supply:
- "Scratch test project. Two phases: MVP and POLISH. Prefixes MVP and POLISH."
- "MVP goal: print 'hello world' when invoked. Deliverable: a single script."

Expected: `ROADMAP.md` is written with two phases.

- [ ] **Step 4: Run `/anvil:sprint MVP`**

Expected: `docs/anvil/sprints/v*-mvp/` directory with at least one ticket
(`MVP-001-*.md`) and a `README.md`. Sprint feature branch created.

- [ ] **Step 5: Run `/anvil:develop MVP-001`**

Expected: worktree created at `.worktrees/MVP-001` on branch
`feature/mvp-MVP-001` (per worktree-discipline, with the leading
`feature/` stripped from the sprint-slug). The
dev-discipline agent produces a plan and asks for approval. The command
stops after approval — it does NOT proceed to RED/GREEN automatically.

- [ ] **Step 6: Run `/anvil:red MVP-001` in the worktree**

Expected: `@red` writes failing tests covering the MVP-001 acceptance
criteria; commits `test(...)` once. Tests fail for the right reason.

- [ ] **Step 7: Run `/anvil:green MVP-001`**

Expected: `@green` writes minimum code; commits `feat(...)` once. Tests
pass.

- [ ] **Step 8: Run `/anvil:refactor MVP-001`**

Expected: either a `refactor(...)` commit or a skip (no refactor
warranted); then the integration-choice matrix is presented. Select
"keep worktree" to avoid cleanup during the test.

- [ ] **Step 9: Document outcome in verification-log.md**

Append:

```markdown
## 2026-04-23 — Phase 6 core-path smoke test

Scratch project: /tmp/anvil-v2-scratch
Host: Claude Code
Packages: anvil-core-stable (with anvil-common-stable transitively)

Result: [init | roadmap | sprint | develop | red | green | refactor] all OK / FAILED at <stage>

Issues: <list any>
```

Commit:

```bash
cd /var/home/olino3/git/anvil
git add shared/specs/verification-log.md
git commit -m "docs(specs): log Phase 6 core-path smoke test"
```

- [ ] **Step 10: Clean scratch for next validation**

```bash
cd /tmp/anvil-v2-scratch
git reset --hard HEAD
rm -rf .worktrees apm_modules .apm apm.lock.yaml .claude docs ROADMAP.md
```

### Task 6.3: Real Anvil workflow on scratch (orchestrator path)

Same as 6.2 but with orchestrator installed, and `/anvil:develop` should
run the full inner loop.

- [ ] **Step 1: Install orchestrator**

```bash
cd /tmp/anvil-v2-scratch
rm -rf apm_modules .apm apm.lock.yaml .claude
mkdir -p .claude
apm init --yes
apm install anvil-orchestrator-stable@anvil-local --target claude
```

Expected: all three packages installed.

- [ ] **Step 2: Run `/anvil:init`, `/anvil:roadmap`, `/anvil:sprint MVP`** (same as 6.2 steps 2-4)

- [ ] **Step 3: Run `/anvil:develop MVP-001`**

Expected: worktree created, plan produced, approval asked. On approval,
orchestrator automatically dispatches `@red`, then `@green`, then
optionally refactor, runs verification, and presents the integration
choice. Select "keep worktree" for the test.

- [ ] **Step 4: Document outcome**

Append to verification-log.md:

```markdown
## 2026-04-23 — Phase 6 orchestrator-path smoke test

Scratch project: /tmp/anvil-v2-scratch
Host: Claude Code
Packages: anvil-orchestrator-stable (+ core + common)

Result: `/anvil:develop` ran [plan → RED → GREEN → REFACTOR → integration] or FAILED at <stage>

Sub-agent dispatch: [worked | fell back to inline]

Issues: <list any>
```

Commit:

```bash
cd /var/home/olino3/git/anvil
git add shared/specs/verification-log.md
git commit -m "docs(specs): log Phase 6 orchestrator-path smoke test"
```

- [ ] **Step 5: Clean scratch**

```bash
cd /tmp/anvil-v2-scratch
git reset --hard HEAD
rm -rf .worktrees apm_modules .apm apm.lock.yaml .claude docs ROADMAP.md
```

### Task 6.4: Host coverage spot-check

Run a reduced smoke test on one non-Claude host to confirm cross-compilation.
Host choice depends on availability — Cursor is the second most mature
per the spec.

- [ ] **Step 1: Install orchestrator into scratch for cursor target**

```bash
cd /tmp/anvil-v2-scratch
rm -rf apm_modules .apm apm.lock.yaml .cursor
mkdir -p .cursor
apm install anvil-orchestrator-stable@anvil-local --target cursor
```

- [ ] **Step 2: Open scratch in Cursor, invoke `@develop-orchestrator` on an existing ticket**

If no tickets exist, create one manually from `ticket-template` in
`.cursor/skills/ticket-template/SKILL.md`, then invoke the agent.

Expected: Cursor invokes the orchestrator. It dispatches `@red` and
`@green` (Cursor 2.5+ supports nested sub-agents per spec).

- [ ] **Step 3: Document outcome**

Append to verification-log.md:

```markdown
## 2026-04-23 — Phase 6 Cursor host spot-check

Scratch project: /tmp/anvil-v2-scratch
Host: Cursor (version: <version>)
Packages: anvil-orchestrator-stable (+ core + common)

Result: @develop-orchestrator ran [plan → RED → GREEN → ...] or FAILED at <stage>

Sub-agent dispatch on Cursor: [worked | fell back to inline]

Issues: <list any>
```

Commit.

---

## Phase 7 — Release automation

### Task 7.1: Write the release workflow

**Files:**
- Create: `.github/workflows/release.yml`

- [ ] **Step 1: Read existing workflows**

```bash
ls .github/workflows/ 2>/dev/null
```

If release.yml already exists, extend it rather than replacing. Otherwise create new.

- [ ] **Step 2: Write release.yml**

Write to `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*.*.*'
      - 'anvil-*-stable-v*.*.*'

jobs:
  build-plugin-bundles:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        package: [anvil-core-stable, anvil-orchestrator-stable]
        host: [claude, copilot, cursor, opencode]
    steps:
      - uses: actions/checkout@v4

      - name: Install APM
        run: curl -sSL https://aka.ms/apm-unix | sh

      - name: Install package deps (for the package being packed)
        working-directory: packages/${{ matrix.package }}
        run: apm install

      - name: Build plugin bundle
        working-directory: packages/${{ matrix.package }}
        run: apm pack --format plugin --target ${{ matrix.host }} --archive -o ./build/

      - name: Rename bundle
        working-directory: packages/${{ matrix.package }}/build
        run: |
          # apm pack produces files like <package>-<version>.tar.gz by default;
          # rename to the spec's naming convention: anvil-<package-short>-<version>-<host>.tar.gz
          # Since the package name already starts with anvil-, the result is:
          # anvil-core-stable-2.0.0-claude.tar.gz
          for f in *.tar.gz; do
            base=$(basename "$f" .tar.gz)
            mv "$f" "${base}-${{ matrix.host }}.tar.gz"
          done

      - name: Upload bundle artifact
        uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.package }}-${{ matrix.host }}
          path: packages/${{ matrix.package }}/build/*.tar.gz

  create-release:
    needs: build-plugin-bundles
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Download all bundle artifacts
        uses: actions/download-artifact@v4
        with:
          path: ./artifacts

      - name: Create GitHub release
        uses: softprops/action-gh-release@v2
        with:
          files: ./artifacts/**/*.tar.gz
          draft: false
          prerelease: ${{ contains(github.ref, 'alpha') || contains(github.ref, 'rc') }}
          generate_release_notes: true
          body: |
            ## v2.0.0 hard cut

            Anvil is now an APM-first marketplace. The v1.x `anvil` plugin
            name no longer exists.

            ### Install

            **APM:**
            ```
            apm marketplace add Olino3/anvil
            apm install anvil-orchestrator-stable@anvil
            ```

            **Claude Code:**
            ```
            claude /plugin marketplace add https://github.com/Olino3/anvil.git
            claude /plugin install anvil-orchestrator-stable
            ```

            **Pre-built bundles:** download the `.tar.gz` for your host from the
            Assets section below and extract into your project.

            See the [README](https://github.com/Olino3/anvil#upgrading-from-v1x)
            for the v1→v2 migration table.
```

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "ci: add release workflow producing 8 plugin bundles"
```

Expected: commit created.

### Task 7.2: Dry-run the release workflow locally

**Files:**
- Use scratch at `/tmp/anvil-v2-release-test/`

- [ ] **Step 1: Reproduce the pack step locally for one (package, host) combo**

```bash
mkdir -p /tmp/anvil-v2-release-test
cp -r /var/home/olino3/git/anvil/packages/anvil-core-stable /tmp/anvil-v2-release-test/
cd /tmp/anvil-v2-release-test/anvil-core-stable
# Temporarily resolve the common dep via local path
apm install
apm pack --format plugin --target claude --archive -o ./build/
ls ./build/
```

Expected: `./build/` contains `anvil-core-stable-2.0.0.tar.gz` (or similar).
The rename step in CI will add the `-claude` suffix.

- [ ] **Step 2: Inspect the bundle**

```bash
tar tzf ./build/*.tar.gz | head -30
```

Expected: `plugin.json` at the root of the bundle, plus `agents/`, `skills/`,
`commands/` directories. No `apm.yml`, `apm_modules/`, or `.apm/` inside.

- [ ] **Step 3: Test the bundle as a standalone plugin**

```bash
mkdir -p /tmp/anvil-bundle-consumer/.claude/plugins
cd /tmp/anvil-bundle-consumer
tar xzf /tmp/anvil-v2-release-test/anvil-core-stable/build/*.tar.gz -C .claude/plugins/
ls .claude/plugins/
```

Expected: `.claude/plugins/anvil-core-stable/` contains the extracted plugin.
(The exact consumption mechanism depends on Claude Code's plugin loader;
this smoke test confirms the bundle structure.)

- [ ] **Step 4: Clean up release test**

```bash
rm -rf /tmp/anvil-v2-release-test /tmp/anvil-bundle-consumer
```

- [ ] **Step 5: No commit; validation only.** If the bundle structure is wrong, revisit Task 7.1 and the spec's "v2.0.0 release artifacts" section.

---

## Phase 8 — Finalize for release

### Task 8.1: Rewrite dependency paths from local to GitHub shorthand

**Files:**
- Modify: `packages/anvil-core-stable/apm.yml`
- Modify: `packages/anvil-orchestrator-stable/apm.yml`

- [ ] **Step 1: Update core's dep path**

Edit `packages/anvil-core-stable/apm.yml` — change:

```yaml
dependencies:
  apm:
    - /var/home/olino3/git/anvil/packages/anvil-common-stable
```

to:

```yaml
dependencies:
  apm:
    - Olino3/anvil/packages/anvil-common-stable
```

- [ ] **Step 2: Update orchestrator's dep paths**

Edit `packages/anvil-orchestrator-stable/apm.yml` — change both entries:

```yaml
dependencies:
  apm:
    - Olino3/anvil/packages/anvil-common-stable
    - Olino3/anvil/packages/anvil-core-stable
```

- [ ] **Step 3: Commit**

```bash
git add packages/anvil-core-stable/apm.yml packages/anvil-orchestrator-stable/apm.yml
git commit -m "chore: rewrite package deps from local paths to GitHub shorthand"
```

Expected: commit created.

- [ ] **Step 4: Verify install still works after the change**

Push `v2.0.0-alpha` to a private branch on GitHub (don't merge), then in a
fresh scratch project:

```bash
cd /tmp/anvil-v2-scratch
rm -rf apm_modules .apm apm.lock.yaml .claude
mkdir -p .claude
apm init --yes
# Using the alpha branch directly:
apm install Olino3/anvil/packages/anvil-orchestrator-stable#v2.0.0-alpha --target claude
```

Expected: all three packages resolve from GitHub; compiled outputs appear.

If the install fails because `#v2.0.0-alpha` isn't a tag yet, use `#branch-name`:

```bash
apm install "Olino3/anvil/packages/anvil-orchestrator-stable#v2.0.0-alpha" --target claude
```

If still failing, back out the rewrite in Steps 1-2 until the tag exists,
or use `apm install --dev <local path>` during development.

### Task 8.2: Tag and create the v2.0.0 release

**Files:**
- Git tag: `v2.0.0`

- [ ] **Step 1: Merge `v2.0.0-alpha` to `develop`**

```bash
cd /var/home/olino3/git/anvil
git checkout develop
git merge v2.0.0-alpha --no-ff -m "Merge v2.0.0-alpha: APM-first marketplace"
```

Expected: merge succeeds.

- [ ] **Step 2: Merge `develop` to `main`**

```bash
git checkout main
git merge develop --no-ff -m "Release v2.0.0"
```

Expected: merge succeeds.

- [ ] **Step 3: Tag `v2.0.0`**

```bash
git tag -a v2.0.0 -m "v2.0.0 — APM-first marketplace (hard cut from v1.x)"
```

Expected: `git tag --list | grep v2.0.0` prints `v2.0.0`.

- [ ] **Step 4: Push**

```bash
git push origin main
git push origin develop
git push origin v2.0.0
```

Expected: CI runs on the tag and builds the 8 plugin bundles.

- [ ] **Step 5: Monitor the release workflow**

```bash
gh run list --workflow=release.yml --limit=3
gh run watch $(gh run list --workflow=release.yml --limit=1 --json databaseId --jq '.[0].databaseId')
```

Expected: the matrix produces 8 bundle artifacts, the release job attaches
them to the `v2.0.0` GitHub release.

- [ ] **Step 6: Verify the release**

```bash
gh release view v2.0.0
```

Expected: 8 `.tar.gz` assets listed, each ~X KB, with names matching the
spec's convention.

- [ ] **Step 7: End-user install smoke test**

In a fresh scratch project, without the local repo path:

```bash
mkdir /tmp/anvil-final-smoke && cd /tmp/anvil-final-smoke
git init
apm init --yes
mkdir -p .claude
apm marketplace add Olino3/anvil
apm install anvil-orchestrator-stable@anvil --target claude
ls .claude/commands/anvil/
grep -l "develop-orchestrator" .claude/commands/anvil/develop.md
```

Expected: all three packages install from GitHub; develop.md contains
orchestrator content. This is the "shipped product works" smoke test.

- [ ] **Step 8: Clean up**

```bash
rm -rf /tmp/anvil-final-smoke /tmp/anvil-v2-scratch
```

- [ ] **Step 9: Announce in verification-log.md**

Append:

```markdown
## 2026-04-23 — v2.0.0 release published

Tag: v2.0.0
Workflow: <CI run URL>
Bundles attached: 8
End-user smoke test: PASS

Notes: <any issues observed during release>
```

Commit:

```bash
cd /var/home/olino3/git/anvil
git add shared/specs/verification-log.md
git commit -m "docs(specs): record v2.0.0 release completion"
git push
```

---

## Definition of done

Every one of the following is simultaneously true:

1. `packages/anvil-common-stable/`, `packages/anvil-core-stable/`, `packages/anvil-orchestrator-stable/` exist with the contents specified in the File Responsibility Map.
2. `plugins/anvil/` and `.claude-plugin/marketplace.json` no longer exist in the repo.
3. `marketplace.json` at repo root lists all three packages, with `anvil-common-stable` marked internal.
4. `apm install anvil-orchestrator-stable@anvil` in a fresh scratch project produces complete compiled outputs for Claude Code, Copilot CLI, Cursor, and OpenCode.
5. In Claude Code, `/anvil:develop <ticket>` with orchestrator installed runs the full plan → RED → GREEN → REFACTOR → integration loop with one approval.
6. In Claude Code, `/anvil:develop <ticket>` with only core installed stops after plan approval and prints the next-command guidance.
7. `v2.0.0` tag is pushed; CI has attached 8 plugin bundles to the GitHub release.
8. An end user running `claude /plugin install anvil-orchestrator-stable` against `https://github.com/Olino3/anvil.git` gets working content.
9. `shared/specs/verification-log.md` contains outcomes for risks #1, #2, #3 and the Phase 6 smoke tests.
10. README's v1→v2 mapping table accurately describes the migration; CONTRIBUTING.md matches the monorepo's actual layout.
