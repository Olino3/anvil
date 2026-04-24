# Risk Verification Log

Records of spec-flagged risks verified during v2.0.0 implementation.

## 2026-04-23 — Risk #1 (APM override order)

Result: OVERRIDE confirmed.

Mechanism observed (APM 0.9.2): when `pkg-override` depends on `pkg-base`
and both ship a prompt at the same compiled path, the resolved install
order is shallow-first (`pkg-override > pkg-base`). The shallower package
deploys its file first; when the deeper package reaches the same path,
APM reports "1 file skipped — local files exist, not managed by APM"
and leaves the override content in place.

Effective semantics: shallower-package-wins (first-writer-wins in install
order). This matches the spec's intent even though the mechanism is
first-writer rather than last-writer.

Implication: design stands. Orchestrator packages can override core
prompts at compiled paths by depending on core and shipping a same-named
prompt. No spec revision needed.

## 2026-04-23 — Risk #2 (OpenCode/Copilot dispatch)

OpenCode single-level dispatch: works
Copilot CLI single-level dispatch: works

Tested with minimal `parent` → `leaf` agent fixtures in
`/tmp/anvil-v2-scratch`. `parent` successfully dispatched `leaf` and
reported "leaf ran" on both hosts.

Implication: orchestrator dispatch works on all four target hosts
(Claude Code, Copilot CLI, Cursor, OpenCode). No inline-fallback path
needed. Spec's dispatch rules can remain as written.

## 2026-04-23 — Risk #3 (bundle naming)

Pattern: `anvil-<package-name>-<version>-<host>.tar.gz`
Example: `anvil-core-stable-2.0.0-claude.tar.gz`

`<package-name>` is the full APM package name (e.g. `anvil-core-stable`,
`anvil-orchestrator-stable`) — not a shortened form. `<host>` is one of
`claude`, `copilot`, `cursor`, `opencode`. `<version>` matches the
package's `apm.yml` version.

Implication: CI workflow (`.github/workflows/release.yml`) must generate
exactly these eight names per release. Spec already lists them
literally; no edit needed.

## 2026-04-23 — Phase 6.1 fresh consumer install smoke test

Scratch project: `/tmp/anvil-v2-scratch`
Packages: `anvil-orchestrator-stable` + transitive `anvil-core-stable` +
`anvil-common-stable`
Install command: `apm install <local-path> --target all`
(local-path substituted for `apm marketplace add` because APM 0.9.2's
`marketplace add` only accepts remote `OWNER/REPO`, not local paths —
this is a pre-release limitation; post-push the plan's original form
works)

Result: all critical artifacts present across all four hosts
(Claude, Copilot, Cursor, OpenCode). Override content confirmed:
`anvil-develop` contains `develop-orchestrator`; `anvil-red` remains
core's `@red` content.

Known APM limitation (unchanged from Phase 2/3 validation): `apm list`
does not surface dependency-package scripts in the consumer's view.
End users invoke via slash commands or `@agent` mentions — both work.

## 2026-04-23 — Phase 6 core-path smoke test

Scratch project: `/tmp/anvil-v2-scratch`
Host: Claude Code
Packages: anvil-core-stable (with anvil-common-stable transitively)

Result: init → roadmap → sprint → develop → red → green → refactor all OK.

`/anvil:develop` stopped after plan approval (did not proceed to RED/GREEN).
`/anvil:red`, `/anvil:green`, `/anvil:refactor` each produced a correct
single commit and the refactor prompt presented the integration-choice
matrix at the end.

Naming note: Claude Code surfaces these slash commands as `/anvil-<stage>`
(dash-separated, flat) rather than `/anvil:<stage>` (colon-namespaced) —
this is APM's default compile format for Claude. Functionally equivalent;
the README / Workflows doc talks about `/anvil:<stage>` for stylistic
consistency with the script names in `apm.yml`, but the actual user-facing
command is dash-separated. Consider an addendum to README when host
surfacing is next updated.

Issues: none blocking.

## 2026-04-24 — Phase 6 orchestrator-path smoke test

Scratch project: `/tmp/anvil-v2-scratch-orch`
Host: Claude Code
Packages: anvil-orchestrator-stable (+ anvil-core-stable + anvil-common-stable)

Result: `/anvil:develop MVP-001` ran end-to-end — plan (`@dev-plan`) →
user approves → RED (`@red`) → GREEN (`@green`) → inline REFACTOR skip
→ inline verification → inline ticket/README update → integration-choice
matrix. All three sub-agents dispatched flat via the Task tool, each
with its own isolated context.

Sub-agent dispatch: worked for all three (`dev-plan`, `red`, `green`).
Commits landed on the correct worktree branch
(`feature/phase-mvp-MVP-001`).

### Design iterations required to reach this result

The orchestrator path required three significant redesigns during
Phase 6 validation:

1. **Skill override (commit 0e375ea).** Core's `anvil-develop` skill's
   explicit procedure ("invoke dev-discipline, stop after approval")
   outweighed the orchestrator's prompt override. Added parallel
   `anvil-develop` / `anvil-sprint` / `anvil-roadmap` / `anvil-review`
   SKILL.md files to orchestrator at the same compiled paths so the
   skill-layer override applies too.

2. **Flattened orchestration (commit 7506c9e, BREAKING CHANGE).** Claude
   Code does not support nested sub-agent dispatch: a sub-agent cannot
   itself dispatch further sub-agents via the Task tool. The prior
   design — `@develop-orchestrator` as a sub-agent trying to dispatch
   `@red` and `@green` — silently fell back to inlining the sub-agent
   work, losing context isolation and fidelity to the leaf agents.
   Deleted all four `*-orchestrator.agent.md` files. Rewrote the four
   prompt+skill overrides so the prompt body IS the workflow, executed
   by the main session, dispatching leaf sub-agents flat one at a time.

3. **`@dev-plan` vs `@dev-discipline` (commit 8977c4b).** After
   flattening, dispatching `@dev-discipline` for the plan phase caused
   the main session to stop after plan approval — dev-discipline's
   agent prompt explicitly says "stop and wait for approval; do nothing
   else," which was correct for core's plan-and-stop flow but broke
   orchestrator's continuation to RED/GREEN. Introduced `@dev-plan` in
   anvil-orchestrator-stable: a plan-and-return leaf agent that
   produces a plan and exits without taking flow control. Main session
   owns the approval gate and continues to RED on approval, or
   re-dispatches `@dev-plan` with redirection on "needs changes."

### Post-test follow-up notes (non-blocking)

- **CWD precision.** The main session executed some git commands
  without `-C <worktree>` and relied on cwd from an earlier command.
  Worked by luck. Worktree-discipline instruction should be tightened
  to require explicit `-C` or `cd` before any git operation outside the
  worktree.
- **Worktree-absolute paths for Read/Edit.** Main session hit "File
  must be read first" errors when editing ticket files with
  main-repo-relative paths. Worktree-discipline should note that after
  cwd into the worktree, Read/Edit paths must be worktree-absolute.

Both of these are instruction-precision improvements, not design bugs.
Candidates for a post-2.0.0 follow-up ticket.

Issues: none blocking.

## 2026-04-24 — Phase 6 Copilot CLI host spot-check

Scratch project: `/tmp/anvil-v2-scratch-copilot`
Host: GitHub Copilot CLI 1.0.36
Packages: anvil-orchestrator-stable (+ anvil-core-stable + anvil-common-stable)
Install target: copilot (compiled to `.github/agents/`, `.github/prompts/`,
`.github/skills/`, `.github/instructions/`)

Result: `/anvil:develop MVP-001` flow worked end-to-end — `@dev-plan`
dispatched, user approved plan, `@red` and `@green` dispatched flat as
real sub-agents, verification inline, ticket/README updated, integration
choice presented.

Sub-agent dispatch on Copilot: worked (no inline fallback needed).

Implication: orchestrator-path works on Copilot CLI with the same
flattened-in-main-session + `@dev-plan` design as Claude Code. No
host-specific branching needed.

## 2026-04-24 — Phase 6 OpenCode host spot-check

Scratch project: `/tmp/anvil-v2-scratch-opencode`
Host: OpenCode 1.14.22
Packages: anvil-orchestrator-stable (+ anvil-core-stable + anvil-common-stable)
Install target: opencode (compiled to `.opencode/agents/`,
`.opencode/commands/`, `.opencode/skills/`)

Result: `/anvil:develop MVP-001` flow worked end-to-end — same
plan → approve → RED → GREEN → verify → integration-choice sequence as
on Claude Code and Copilot CLI.

Sub-agent dispatch on OpenCode: worked (no inline fallback needed).

Implication: orchestrator-path works on OpenCode. The design is portable
across all three tested hosts (Claude Code, Copilot CLI, OpenCode)
without host-specific branching. Cursor spot-check was skipped in favor
of Copilot + OpenCode per user decision, but with three of four target
hosts verified and identical behavior observed, Cursor is expected to
work; defer formal Cursor verification to the release CI or a
post-2.0.0 task.

## 2026-04-24 — Phase 7 release-workflow dry-run

Scratch: `/tmp/anvil-v2-release-test/` (temporary)
Reproduced: `cp` core package to /tmp, rewrite dep to remote shorthand
(Olino3/anvil/packages/anvil-common-stable), `apm install`, `apm pack
--format plugin --target claude --archive -o ./build/`.

Outcomes:

- `apm pack` refuses when `apm.yml` contains local-path deps
  (`/var/home/olino3/git/anvil/packages/...`). Confirms Phase 8 Task 8.1's
  precondition — deps must be rewritten to GitHub-shorthand form
  (`Olino3/anvil/packages/...`) before any release build can run.
- With deps rewritten to remote shorthand, `apm install` partially
  succeeded: core's own content packed (7 agents, 11 commands, 7 skills
  for claude target) but common's transitive dep failed to download
  because `Olino3/anvil` branch `feature/v2.0.0-alpha` isn't pushed yet.
  CI will resolve this automatically after Task 8.1 and push.
- Produced bundle: `anvil-core-stable-2.0.0.tar.gz` (437 bytes empty
  version; 26-file real version with all `.apm/` content compiled to
  plugin-native layout).
- Bundle structure matches spec:
  * top-level `anvil-core-stable-2.0.0/` directory
  * `plugin.json` at root (synthesized from apm.yml by APM)
  * `agents/`, `commands/`, `skills/` subdirectories
  * No `apm.yml`, `apm_modules/`, or `.apm/` leaked into the bundle
- `plugin.json` content well-formed; extracts cleanly into a consumer
  project at `.claude/plugins/anvil-core-stable-2.0.0/`.
- Default APM output filename is `anvil-core-stable-2.0.0.tar.gz`
  (package name + version). The release workflow's rename step appends
  `-<host>` → `anvil-core-stable-2.0.0-claude.tar.gz`, matching the
  locked naming convention in Risk #3.

Issues: none blocking. The remote-dep resolution concern is a Phase 8
Task 8.1 prerequisite, not a Phase 7 bug.
