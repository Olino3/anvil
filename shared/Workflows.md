# Anvil Workflows

## How to read this doc

This is the **playbook** for Anvil — the day-to-day recipes for using the commands together, not a reference for what each command does in isolation. Each workflow below is a numbered sequence with example prompts you can adapt and an "Artifacts touched" note so you know what's about to change on disk.

Assumed reader: you've installed one of the Anvil packages (`anvil-core-stable` or `anvil-orchestrator-stable`) and know the slash commands it provides. If not, see [README.md](../README.md) first.

For artifact **formats** (what a ROADMAP.md, sprint README, ticket, or BA report should look like), see the reference skills in `anvil-common-stable` under [`packages/anvil-common-stable/.apm/skills/`](../packages/anvil-common-stable/.apm/skills/). This doc links to them rather than duplicating.

## Which package is this playbook for?

Most workflows work identically for either `anvil-core-stable` or
`anvil-orchestrator-stable`. Where behavior differs, the recipe notes the
distinction with **[core]** / **[orchestrator]** tags.

---

## Commands at a glance

Commands are the same names across packages, but **[core]** stops at human-in-the-loop steps while **[orchestrator]** drives the full inner loop:

| Command | [core] behavior | [orchestrator] behavior |
|---|---|---|
| `/anvil:init` | Detect stack, write project config | same |
| `/anvil:roadmap` | Invoke `@pd` for roadmap conversation | `@pd` + optional sprint handoff |
| `/anvil:sprint <phase>` | Invoke `@pm` to generate sprint | `@pm` + optional one-ticket handoff to `@develop-orchestrator` |
| `/anvil:develop <ticket>` | Locate + worktree + plan, then stop | Full loop: plan → `@red` → `@green` → optional REFACTOR → verification → integration choice |
| `/anvil:red <ticket>` | `@red` writes whole-ticket failing suite | same (from core) |
| `/anvil:green <ticket>` | `@green` writes minimum production code | same (from core) |
| `/anvil:refactor <ticket>` | Self-contained refactor + integration choice | same (from core) |
| `/anvil:review <phase>` | `@ba` writes BA-REPORT; recommendations not applied | `@ba` + all-or-nothing approval to apply cleanup |
| `/anvil:sync <phase>` | `@sprint-syncer` rebuilds sprint README | same (from core) |
| `/anvil:status [phase]` | Read-only summary | same (from core) |

Every command is also available as `apm run anvil:<stage> --param ...`.

## Artifact map

What each command touches. Rows marked **[orchestrator]** describe effects that only happen when `anvil-orchestrator-stable` is installed; under **[core]**, `/anvil:develop` stops after the worktree + plan and the user drives `/anvil:red`, `/anvil:green`, `/anvil:refactor` explicitly:

| Command | Writes / modifies |
|---|---|
| `/anvil:init` | `docs/anvil/config.yml` |
| `/anvil:roadmap` | `ROADMAP.md` |
| `/anvil:sprint` | `docs/anvil/sprints/{version}-{slug}/` (directory + ticket files + `README.md`); creates sprint feature branch |
| `/anvil:develop` **[core]** | `.worktrees/{ticket-id}/` on branch `feature/{sprint-slug}-{ticket-id}`; plan output only (no code, no test commits) |
| `/anvil:develop` **[orchestrator]** | Worktree as above; the ticket file; the sprint `README.md`; RED/GREEN/REFACTOR commits; integration-choice action (squash/merge/PR/keep/discard) |
| `/anvil:red` | Failing test file(s); `test(scope): ...` commit |
| `/anvil:green` | Production code file(s); `feat(scope): ...` or `fix(scope): ...` commit |
| `/anvil:refactor` | Optional `refactor(scope): ...` commit; ticket status → Done; sprint README updated; integration choice executed |
| `/anvil:review` **[core]** | `BA-REPORT.md` in the sprint directory (recommendations only) |
| `/anvil:review` **[orchestrator]** | `BA-REPORT.md` + (with approval) ticket corrections (status, dependencies, splits, archival) + sprint `README.md` rebuild |
| `/anvil:sync` | Sprint `README.md` only |
| `/anvil:status` | Nothing — read-only |

---

# Part 1 — Core Loop

The canonical greenfield playbook, from empty repo to a completed phase and on to the next.

## 1.1 — Onboarding (first run on a new project)

**When:** brand-new project, or the first time using Anvil on an existing repo.

**Recipe:**

1. `/anvil:init` — Anvil conversationally detects your stack and writes `docs/anvil/config.yml` with per-component test/build/lint commands.
2. `/anvil:roadmap` — invokes the `@pd` (Product Director) agent to converse with you about phases, goals, deliverables, and prefixes.
3. Skim the generated `ROADMAP.md`. Confirm each phase has: a **prefix** (3–5 uppercase chars, e.g. `MVP`, `AUTH`), a **theme**, at least one measurable **goal**, and a **Deliverables** checklist.

**Example prompts to `@pd`:**

- "This is a greenfield CLI tool for batch image conversion. Break it into 3–4 phases, MVP first, then polish."
- "Use prefixes `MVP`, `FMT`, `CLI`, `POLISH`. Phase 1 ships the core convert command only."
- "For the MVP phase, add a goal: 'Convert PNG→JPEG with at least 95% size reduction on 100 sample images.'"

**Artifacts touched:** `docs/anvil/config.yml`, `ROADMAP.md`.

**Next:** Workflow 1.2 to pick a phase and start building.

---

## 1.2 — Greenfield main loop (the `/anvil:develop` inner loop)

**When:** you have a `ROADMAP.md` and want to ship a phase.

**Recipe:**

1. `/anvil:sprint <phase>` — `@pm` explores the codebase and generates 4–8 main tickets plus any SPIKE tickets, writes the sprint `README.md`, and creates the feature branch (e.g. `feature/mvp`). **[orchestrator]** additionally offers a one-ticket handoff to `@develop-orchestrator` for the first unblocked ticket.

   Example: `/anvil:sprint MVP` or `/anvil:sprint 2`.

2. For each ticket, in dependency order (the sprint `README.md`'s dependency graph shows the order):

   a. `/anvil:develop <TICKET-ID>` — auto-creates the worktree at `.worktrees/{TICKET-ID}` on branch `feature/{sprint-slug}-{TICKET-ID}` (e.g. `feature/mvp-MVP-001`).

   b. `@dev-discipline` presents a step-by-step implementation plan and **waits for your approval**. Approve or steer:

      > "Proceed." — accept the plan as-is.
      >
      > "Adjust — step 3 duplicates work already done in MVP-002. Drop it and proceed with the rest."

   c. Run RED → GREEN (→ REFACTOR):
      - **[orchestrator]** On approval, `@develop-orchestrator` dispatches `@red` and `@green`, optionally runs `/anvil:refactor`, verifies, and presents the integration choice automatically.
      - **[core]** The user runs, in order: `/anvil:red <TICKET-ID>`, `/anvil:green <TICKET-ID>`, then optionally `/anvil:refactor <TICKET-ID>`. The refactor prompt (or green, if no refactor) presents the integration choice at its end.

      Each cycle produces commits: `test(scope): ...`, `feat(scope): ...` (or `fix(...)`), optionally `refactor(...)`.

   d. When the ticket is Done, you are presented with the integration-choice matrix. See [3.1.3 Integration choice](#313--integration-choice-after-a-ticket-finishes) for the decision matrix.

3. `/anvil:review <phase>` — `@ba` runs health check, executes every Done ticket's Verification Steps, does gap analysis against the ROADMAP, and writes `BA-REPORT.md` ending with a **Recommended actions** section. **[orchestrator]** additionally offers an all-or-nothing approval to apply the recommended cleanup.

4. Read `BA-REPORT.md`. Address any recommendations:
   - Verification failures on Done tickets → investigate; `@ba` does **not** auto-downgrade status.
   - Missing ROADMAP deliverable coverage → add a ticket manually or re-run `/anvil:sprint <phase>` with guidance.
   - Scope-creep tickets flagged → decide whether to keep as SPIKEs or archive.

**Example prompts / decision points:**

- Plan approval: *"Proceed"* or *"Skip step 3, already covered by MVP-002"*.
- Integration choice: **Squash** for clean sprint-branch history, **PR** for team review, **Keep** to park work in progress.

**Artifacts touched:** sprint directory (new), ticket files, `.worktrees/`, RED/GREEN/REFACTOR commits, `BA-REPORT.md`.

---

## 1.3 — Completing a sprint, advancing the roadmap

**When:** all main tickets in the current phase are Done and verified.

**Recipe:**

1. `/anvil:review <phase>` — confirm everything is Done, verification passes, and no coverage gaps remain.
2. `/anvil:roadmap` — re-enter the `@pd` conversation to mark the phase complete and shape the next one based on what you just learned.

   Example prompt:
   > "MVP is done — mark the phase complete, add a short retro note, and let's refine Phase 2. Based on what shipped, I want to cut the offline mode deliverable and add plugin discovery instead."

3. `/anvil:sprint <next-phase>` — generate the next sprint from the updated roadmap.
4. Back to [Workflow 1.2](#12--greenfield-main-loop-the-anvildevelop-inner-loop) for the new sprint.

**Artifacts touched:** `ROADMAP.md` (phase status + possibly next-phase updates), new sprint directory.

---

# Part 2 — Course Corrections

When reality diverges from the plan — new requirements land, progress stalls, or a phase's scope shifts.

## 2.1 — Sprint-level course correction (socratic review)

**When:** the sprint feels off-track, new requirements have landed mid-sprint, or progress is stalling on the wrong things.

**Recipe:**

1. `/anvil:review <phase>` — establish a baseline. Read `BA-REPORT.md` to see gap analysis, scope-creep flags, and unverified Done work.
2. **Continue the conversation** in the same Claude Code session. Anvil's commands dispatch sub-agents that terminate after producing their artifact, but the main context remains — you can drive the socratic session directly:

   > "Now let's do a socratic session. Walk me through where this sprint has diverged from the Phase 2 goals in ROADMAP.md. Focus on tickets that aren't mapped to a deliverable. Don't change files yet — just ask me questions one at a time."

3. Based on the discussion, **edit the affected ticket files manually** (change status, rewrite acceptance criteria, delete tickets, or add new SPIKEs for in-scope-but-uncovered work).
4. `/anvil:sync <phase>` — rebuild the sprint `README.md` from the updated ticket files so the status table, dependency graph, and counts match reality.
5. `/anvil:status <phase>` — visual confirmation the board is clean.

**Example prompts for the socratic session:**

- "What tickets no longer serve the phase goal?"
- "Where are we building for hypothetical needs instead of roadmap deliverables?"
- "If we cut 2 tickets to take on <new requirement>, which 2?"
- "Which of the remaining Open tickets is the highest-leverage to tackle next?"

**Artifacts touched:** ticket files (manual edits), sprint `README.md` (via `/anvil:sync`).

---

## 2.2 — Roadmap-level course correction (re-plan a phase)

**When:** a phase's goals or scope have shifted enough that the sprint's tickets are no longer the right decomposition.

**Recipe:**

1. `/anvil:roadmap` — enter the `@pd` conversation.

   Example prompt:
   > "Let's replan Phase 3. Goals have shifted — we're no longer building a web UI, we need a CLI-first approach. Walk me through the brainstorm socratically: what are the new deliverables, what carries over from the old Phase 3, what should go into a new 'Avoid deepening' note?"

2. Confirm `ROADMAP.md` reflects the new phase definition (goals, deliverables, avoid-deepening, prefix unchanged).
3. If a sprint already exists for this phase, regenerate or adjust it:

   ```
   /anvil:sprint <phase>
   ```

   `@pm` will detect the existing sprint and ask whether to regenerate. Guide it:
   > "Phase goals changed. Preserve tickets still relevant (list: UI-001, UI-003). Archive the rest. Add new tickets covering the CLI-first deliverables."

4. `/anvil:review <phase>` — verify the new decomposition matches the updated phase. Read `BA-REPORT.md` for any coverage gaps or orphaned tickets.

**Artifacts touched:** `ROADMAP.md`, sprint tickets (regenerated or updated), sprint `README.md`, `BA-REPORT.md`.

---

# Part 3 — Specialized Flows

Tactical workflows for the moments inside a sprint that don't fit the core loop.

## 3.1 — TDD granular flows

### 3.1.1 — RED passes unexpectedly (test isn't actually failing)

**Symptom:** `@red` reports the failing test passed on first run.

**Diagnosis:** the test isn't exercising the missing behavior. Common causes:
- A mocked-out dependency short-circuits the assertion.
- Wrong import path — the test is testing stub code, not the real module.
- Assertion is too weak (e.g. `assert result is not None` when the stub returns `None`).

**Recipe:** before moving to GREEN, push back:

> "The test passed on first run — the feature clearly doesn't exist yet, so the test must not be exercising the real code path. Find what's mocking or short-circuiting and fix the test so it fails for the right reason."

---

### 3.1.2 — SPIKE discovery during ticket work

**Symptom:** mid-implementation, `@green` or `@develop-orchestrator` hits work that's needed but outside the current ticket's scope (e.g. a missing config loader, a refactor to an unrelated module).

**Recipe:** this is automatic. The agent will:

1. Create a new `SPIKE-NNN-{slug}.md` ticket file in the sprint directory using the [ticket template](../packages/anvil-common-stable/.apm/skills/ticket-template/SKILL.md).
2. Add it to the sprint `README.md`'s tickets table.
3. Note the SPIKE in the current ticket's Notes section.
4. Continue the current ticket without expanding its scope.

You can also prompt this explicitly when approving the plan:
> "If you hit anything beyond this ticket's acceptance criteria, create a SPIKE and keep going — don't expand this ticket."

---

### 3.1.3 — Integration choice after a ticket finishes

After the ticket is marked Done (by `@develop-orchestrator` under **[orchestrator]**, or by `/anvil:refactor` / `/anvil:green` under **[core]**), the worktree-discipline integration-choice matrix is presented. Five options:

| Option | When to use |
|---|---|
| **1. Squash merge** | Default for clean sprint-branch history — collapses RED/GREEN/REFACTOR into one commit. |
| **2. Merge** | When the RED/GREEN commit sequence tells an instructive story you want to preserve. |
| **3. Create PR** | Team review gate, or the sprint branch feeds CI/CD before merging. Worktree is kept; `gh pr create` runs automatically. |
| **4. Keep worktree** | You plan to iterate more on the same ticket before integrating. Nothing merges; worktree stays. |
| **5. Discard** | Implementation was wrong; start over. Requires explicit confirmation; removes the worktree and deletes the dev branch. |

After options 1, 2, and 5, the worktree and dev branch are removed automatically. After option 3 or 4, the sprint branch does **not** yet reflect the completed ticket — the sprint `README.md` on the sprint branch won't show it as Done until the eventual merge.

---

### 3.1.4 — Parallel ticket development

**When:** two tickets have no dependency relationship and you have a second Claude Code session available.

**Recipe:**

1. Confirm the two tickets don't depend on each other (check `Depends on:` / `Blocks:` in both files; also check the dependency graph in the sprint `README.md`).
2. In two separate Claude Code sessions on the same repo, run `/anvil:develop <TICKET-A>` in one and `/anvil:develop <TICKET-B>` in the other.
3. Each gets its own isolated worktree: `.worktrees/TICKET-A` and `.worktrees/TICKET-B` on branches `feature/{sprint-slug}-TICKET-A` and `feature/{sprint-slug}-TICKET-B`.
4. Integrate each independently via its own integration step. If both squash-merge, the sprint branch gets two clean commits.

**Guardrails:**
- Don't parallelize tickets that touch the same files — even without formal dependencies, merge conflicts will block integration.
- Avoid parallelizing SPIKE tickets generated during `/anvil:develop` on one of the two in-flight tickets; the SPIKE's scope is discovered mid-flight and may overlap.

---

## 3.2 — Drift & recovery flows

### 3.2.1 — Sprint README drift (tickets edited manually, README is stale)

**Symptom:** you (or the socratic session from 2.1) edited ticket files directly; the sprint `README.md` tickets table, dependency graph, or status counts are now inconsistent.

**Recipe:**

1. `/anvil:sync <phase>` — `@sprint-syncer` rebuilds the `README.md` from the ticket files as the source of truth.
2. `/anvil:status <phase>` — visual confirmation.

**When to prefer `/anvil:sync` over `/anvil:review`:** `/anvil:sync` is fast and README-only (no verification runs, no `BA-REPORT.md`). Use it for pure bookkeeping. Use `/anvil:review` when you also want verification + gap analysis.

---

### 3.2.2 — Quick situational awareness

**When:** you're about to start work and want to see the board without changing anything.

**Recipe:** `/anvil:status [phase]` — read-only, no writes, no agent dispatched. Shows ticket counts, in-progress work, blocked tickets, and recent activity. Omit `[phase]` to see all sprints.

Run this before `/anvil:develop` to confirm the right ticket to pick up next.

---

### 3.2.3 — Ticket splitting (`/anvil:review` found oversized tickets)

**Symptom:** `BA-REPORT.md` reports a ticket has more than ~8 acceptance criteria and recommends a split.

**Recipe:**

- **[orchestrator]** — `/anvil:review <phase>` offers a single approval to apply all recommended actions. On approval, `@review-orchestrator` splits the ticket (next available sequential numbers in the sprint's prefix), preserves context and notes across children, rewires `Depends on` / `Blocks`, and then invokes `@sprint-syncer` to rebuild the sprint `README.md`.
- **[core]** — `/anvil:review <phase>` writes the BA-REPORT but does not apply changes. Either perform the splits manually (copy the ticket, renumber, re-point dependencies, archive the original), or install `anvil-orchestrator-stable` and re-run `/anvil:review` to apply automatically. Finish with `/anvil:sync <phase>` to refresh the README.

Read `BA-REPORT.md` for the split record, then continue with `/anvil:develop` on one of the new smaller tickets.

---

### 3.2.4 — Unblocking a blocked ticket

**Symptom:** `/anvil:develop TICKET-Y` refuses because `Depends on: TICKET-X` isn't Done.

**Recipe:**

1. `/anvil:status <phase>` — confirm `TICKET-X`'s actual state.
2. If `TICKET-X` is genuinely not Done: `/anvil:develop TICKET-X` first, then retry Y.
3. If `TICKET-X` is actually done but still marked otherwise: `/anvil:review <phase>` — `@ba` checks every Done ticket's verification and flags mismatches in `BA-REPORT.md`. Under **[orchestrator]**, approving the recommended actions applies the status correction. Under **[core]**, edit the ticket's Status manually and run `/anvil:sync <phase>`.
4. If verification is actually failing: edit `TICKET-X`'s Status field manually, then `/anvil:sync <phase>` to propagate to the sprint `README.md`.

---

## 3.3 — Phase lifecycle flows

### 3.3.1 — Cleanly closing out a phase

See [Workflow 1.3](#13--completing-a-sprint-advancing-the-roadmap). Named separately here for discoverability.

---

### 3.3.2 — Archiving stale tickets

**When:** a ticket is Open, has no blockers, and is clearly superseded by other completed work or cut from scope.

**Automatic path [orchestrator]:** `/anvil:review <phase>` — `@review-orchestrator` applies the BA-REPORT's archival recommendations on approval (renames stale tickets to `ARCHIVED-{PREFIX}-{NNN}-{slug}.md` and rebuilds the `README.md` via `@sprint-syncer`).

**Automatic path [core]:** `/anvil:review <phase>` records the recommendation in `BA-REPORT.md` but does not apply it. Proceed with the manual path below, or install `anvil-orchestrator-stable`.

**Manual path:** rename the ticket file to `ARCHIVED-{PREFIX}-{NNN}-{slug}.md`, then `/anvil:sync <phase>` to refresh the `README.md`.

---

### 3.3.3 — Hotfix outside the current sprint

**When:** something breaks in production (or in `main`) that can't wait for the sprint to complete.

Anvil is sprint-centric; hotfixes live outside it. Recommended pattern:

1. Commit the hotfix directly — checkout `main` (or a `hotfix/*` branch off `main`), make the fix, commit, open a PR through your normal process. Do **not** route this through `/anvil:develop`.
2. Once the hotfix is merged, return to the sprint branch (`git checkout {sprint-branch}`) and resume the normal sprint loop.
3. If the hotfix revealed missing sprint coverage (e.g. a class of bug the sprint should have caught), add a SPIKE: either via `/anvil:roadmap` → conversation with `@pd` about adding a deliverable, followed by `/anvil:sprint` to regenerate; or more quickly, create the SPIKE ticket file directly in the sprint directory and run `/anvil:sync`.

---

## Tips & gotchas

- **Worktrees live under `.worktrees/`**, which is added to `.gitignore` automatically the first time `/anvil:develop` runs.
- **Never commit directly to the sprint branch.** Always go through `/anvil:develop`'s worktree (branch `feature/{sprint-slug}-{ticket-id}`). If you bypass it, the integration options won't apply and the sprint branch's history loses the TDD structure.
- **Every ticket's `Component:` field must match a key in `docs/anvil/config.yml`.** If it doesn't, neither `/anvil:develop` nor `@red`/`@green` will know which test/build commands to run. Update either the ticket or `config.yml` so they match.
- **`/anvil:roadmap` has no arguments.** Intent is expressed by talking to `@pd` *after* the dispatch. Same for `/anvil:init`.
- **`/anvil:review` does not auto-downgrade a Done ticket whose verification fails.** It flags the failure in `BA-REPORT.md` and leaves the status alone. You decide whether to reopen.
- **Bidirectional dependencies** — if ticket A lists `Depends on: B`, then B must list `Blocks: A`. If you edit one side manually, `/anvil:review` will flag the gap; under **[orchestrator]** the recommended action applies the fix, under **[core]** `/anvil:sync` will heal it on the next run.
- **SPIKE tickets are first-class.** They carry a `SPIKE-NNN` ID (instead of the phase prefix), show up in the sprint README, and are picked up by `/anvil:develop` like any other ticket.

---

## Cross-references

Artifact formats and conventions live in `anvil-common-stable`:

- [Roadmap format](../packages/anvil-common-stable/.apm/skills/roadmap-format/SKILL.md) — structure of `ROADMAP.md`.
- [Sprint README format](../packages/anvil-common-stable/.apm/skills/sprint-readme-format/SKILL.md) — structure of `docs/anvil/sprints/*/README.md`.
- [Ticket template](../packages/anvil-common-stable/.apm/skills/ticket-template/SKILL.md) — required fields and sections.
- [BA report format](../packages/anvil-common-stable/.apm/skills/ba-report-format/SKILL.md) — structure of `BA-REPORT.md`.
- [Anvil config schema](../packages/anvil-common-stable/.apm/skills/anvil-config-schema/SKILL.md) — structure of `docs/anvil/config.yml`.

Always-applied instructions (compiled into every host):

- [Commit conventions](../packages/anvil-common-stable/.apm/instructions/commit-conventions.instructions.md) — scope, type, and message style.
- [TDD discipline](../packages/anvil-common-stable/.apm/instructions/tdd-discipline.instructions.md) — the RED/GREEN/REFACTOR cycle.
- [Worktree discipline](../packages/anvil-common-stable/.apm/instructions/worktree-discipline.instructions.md) — worktree creation + integration choice matrix.
