# APM-First Marketplace Design

**Date:** 2026-04-23
**Status:** Approved for implementation planning
**Target release:** v2.0.0

## Summary

Transition Anvil from a Claude-Code-first plugin marketplace to an APM-first
(Microsoft Agent Package Manager) marketplace. Restructure the repo as a
monorepo of three APM packages authored in the `.apm/` scaffold, compiled to
native host formats via `apm install` / `apm pack`, with support for Claude
Code, Copilot CLI, Cursor, and OpenCode. Gemini is explicitly unsupported.

The goal is a single source of truth that is tool-, vendor-, and
model-agnostic; leverages APM's primitives (skills, agents, instructions,
prompts, parameterized `apm run` scripts, `apm pack`, marketplaces); and
ships a consistent discipline across hosts while offering orchestration where
host capabilities allow.

v2.0.0 is a **hard cut** — no shim preserving the v1.x `anvil` plugin name.

## Motivation

Today's Anvil is:
- Claude-Code-first: canonical layout under `plugins/anvil/`, with
  `.claude-plugin/marketplace.json` at the root. The root `apm.yml` is a
  comment-only shim telling APM users "no `.apm/` mirror needed."
- Orchestration-dependent on Claude Code's Task-dispatch runtime:
  `dev-agent` dispatches `red-agent` and `green-agent` as nested sub-agents
  in the same session. That nesting works on Claude and on Cursor (2.5+) but
  is undocumented on OpenCode and Copilot CLI, and explicitly forbidden on
  Gemini CLI. The result is a "full experience on Claude, degraded manual
  experience everywhere else" story.

APM-first authoring inverts that. APM was built for exactly this: one
`.apm/` tree, compiled outward to every host's native directory (`.claude/`,
`.github/`, `.cursor/`, `.opencode/`). Prompts are parameterized, runnable
via `apm run`, and interchangeable with slash commands on hosts that
support them. Marketplaces, plugin bundles, transitive deps, lockfiles, and
security scanning all come free.

## Out of scope (v2.0.0)

- `anvil-autonomous-stable` — reserved name, not designed or shipped.
- Model-specific package editions (e.g. `anvil-core-opus-4-7`). The
  architecture supports them as sibling packages; only `-stable` editions
  ship in v2.0.0.
- Multi-ticket auto-develop loop (walk the sprint dep graph, develop every
  ticket). Reserved for `anvil-autonomous-stable`.
- Gemini CLI support. No compile target.

## Architecture

### Three packages, clean dependency graph

```
marketplace.json  (lists anvil-core-stable, anvil-orchestrator-stable;
                   anvil-common-stable flagged internal)
        │
        ├─ anvil-common-stable ◄────── anvil-core-stable
        │       (internal;                   (discipline;
        │        formats, templates,          human orchestrates
        │        TDD/commit/worktree          each step)
        │        instructions)                     ▲
        │                                          │
        │                                          │ depends on
        │                                          │
        └─◄──── anvil-orchestrator-stable ─────────┘
                (high-level human-in-the-loop;
                 single-stage automation;
                 overrides core commands)
```

- **anvil-common-stable** — shared primitives. Formats (roadmap, sprint
  README, ticket template, BA report, config schema), and instructions
  (commit conventions, TDD discipline, worktree discipline) every other
  package inherits. Internal — flagged in `marketplace.json` as
  transitive-only; browseable but not a first-class user install.
- **anvil-core-stable** — the discipline. Every discrete disciplined action
  is a prompt runnable via `apm run` or a slash command. No dispatch. The
  human is the orchestrator of every step.
- **anvil-orchestrator-stable** — single-stage automation. Wraps core's
  prompts and agents with stage-level approval gates; uses single-level
  sub-agent dispatch (never nested) for stages that benefit from it
  (develop's RED → GREEN). Overrides the four stage-entry commands
  (`develop`, `sprint`, `roadmap`, `review`) while leaving the rest of
  core's commands untouched.

### Install UX

```bash
# One-time marketplace registration
apm marketplace add Olino3/anvil

# Pick the flavor
apm install anvil-core-stable@anvil           # discipline only
apm install anvil-orchestrator-stable@anvil   # auto-installs core + common
```

Claude Code users retain the familiar path:
```bash
claude /plugin marketplace add https://github.com/Olino3/anvil.git
claude /plugin install anvil-orchestrator-stable
```

### Repo layout

```
Olino3/anvil/
├── marketplace.json
├── apm.yml                                   # workspace metadata for contributors
├── packages/
│   ├── anvil-common-stable/
│   │   ├── apm.yml
│   │   └── .apm/
│   │       ├── instructions/                 # commit-conventions, tdd, worktree
│   │       └── skills/                       # format / template skills
│   ├── anvil-core-stable/
│   │   ├── apm.yml                           # depends on: anvil-common-stable
│   │   └── .apm/
│   │       ├── agents/                       # red, green, dev-discipline, pd, pm, ba, sprint-syncer
│   │       ├── skills/                       # per-stage discipline skills
│   │       └── prompts/                      # one prompt per user-visible action; compiles to slash commands on Claude/OpenCode, runnable via apm run everywhere
│   └── anvil-orchestrator-stable/
│       ├── apm.yml                           # depends on: anvil-common-stable, anvil-core-stable
│       └── .apm/
│           ├── agents/                       # develop-orchestrator, sprint-orchestrator, roadmap-orchestrator, review-orchestrator
│           ├── skills/                       # orchestration-gates
│           └── prompts/                      # override: anvil-develop, anvil-sprint, anvil-roadmap, anvil-review
├── shared/                                   # maintainer-facing docs; APM never reads this
│   ├── Workflows.md
│   ├── CONTRIBUTING.md
│   └── specs/
├── README.md
└── LICENSE
```

## Package: anvil-common-stable

Internal shared package. Never ships a runnable prompt or dispatch-capable
agent. Pure reference + always-loaded instructions.

### Contents

```
.apm/
├── instructions/
│   ├── commit-conventions.instructions.md
│   ├── tdd-discipline.instructions.md
│   └── worktree-discipline.instructions.md
└── skills/
    ├── roadmap-format/SKILL.md
    ├── sprint-readme-format/SKILL.md
    ├── ticket-template/SKILL.md
    ├── ba-report-format/SKILL.md
    └── anvil-config-schema/SKILL.md
```

### Why these three are instructions (not skills)

APM instructions are auto-loaded into agent context when their `applyTo`
glob matches. Skills are explicitly invoked. TDD, commit conventions, and
worktree discipline need to apply *pervasively* to every disciplined agent
in core and orchestrator — instructions fit that contract. The format/
template skills are reference material consulted when working on one
specific artifact, so they stay as skills with tight descriptions.

### Worktree-discipline instruction

Extracted from today's `dev-agent.agent.md` (Phase 0) and
`commands/develop.md`. Covers:

- Worktree path: `.worktrees/{ticket-id}` relative to git root
- Branch name: `{sprint-branch}/dev/{ticket-id}`
- `.worktrees/` added to `.gitignore` on first create
- Detect "already in worktree" by branch matching `*/dev/*` + path
  containing `.worktrees/`
- Creation command:
  `git worktree add .worktrees/{ticket-id} -b {sprint-branch}/dev/{ticket-id}`
- Never commit directly to the sprint branch — always through a worktree
- Integration-choice matrix at ticket completion: squash merge / merge / PR /
  keep worktree / discard — and what each does to the worktree + dev branch
- Cleanup: worktree + dev branch removed after squash/merge/discard; kept
  after PR/keep

`applyTo: "**/*"` with an opening-line gate ("When implementing a sprint
ticket or about to start/finish ticket work") so it doesn't spuriously fire.

### `apm.yml`

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

## Package: anvil-core-stable

The discipline package. Every disciplined action is a prompt runnable as
a slash command or `apm run`. No sub-agent dispatch — the human drives each
step.

### Contents

```
.apm/
├── agents/
│   ├── red.agent.md                      # whole-ticket failing tests
│   ├── green.agent.md                    # minimum code to pass whole suite
│   ├── dev-discipline.agent.md           # plan-and-approve only, no dispatch
│   ├── pd.agent.md                       # roadmap author
│   ├── pm.agent.md                       # sprint generator
│   ├── ba.agent.md                       # sprint health / verification
│   └── sprint-syncer.agent.md            # README rebuilder
├── skills/
│   ├── anvil-init/
│   ├── anvil-roadmap/
│   ├── anvil-sprint/
│   ├── anvil-develop/
│   ├── anvil-review/
│   ├── anvil-sync/
│   └── anvil-status/
└── prompts/
    ├── anvil-init.prompt.md              # /anvil:init     | apm run anvil:init
    ├── anvil-roadmap.prompt.md           # /anvil:roadmap  | apm run anvil:roadmap
    ├── anvil-sprint.prompt.md            # /anvil:sprint   | input: phase
    ├── anvil-develop.prompt.md           # /anvil:develop  | input: ticket — locate, verify deps, auto-worktree, plan, stop
    ├── anvil-plan-ticket.prompt.md       # /anvil:plan     | input: ticket — internal; also standalone
    ├── anvil-red.prompt.md               # /anvil:red      | input: ticket — whole-ticket failing suite
    ├── anvil-green.prompt.md             # /anvil:green    | input: ticket — whole-ticket minimum code
    ├── anvil-refactor.prompt.md          # /anvil:refactor | input: ticket — self-contained refactor discipline; no dedicated agent
    ├── anvil-review.prompt.md            # /anvil:review   | input: phase
    ├── anvil-sync.prompt.md              # /anvil:sync     | input: phase
    └── anvil-status.prompt.md            # /anvil:status   | input: phase (optional)
```

**Note:** No `.apm/commands/` directory. Slash commands and `apm run` scripts
are both served by the same `.apm/prompts/*.prompt.md` source files. APM's
compiler generates `.claude/commands/anvil/<name>.md` and
`.opencode/commands/<name>.md` from prompts automatically (file rename, no
content change). Copilot CLI users invoke via `apm run anvil:<name>` or the
compiled `.github/prompts/*.prompt.md`. Cursor users invoke via `@<agent>`
or `apm run`. One source, every invocation path.

### Behavior of /anvil:develop in core

1. Locate ticket under `docs/anvil/sprints/**/<ticket-id>*.md`
2. Verify all `Depends on:` tickets are Done; refuse otherwise
3. Auto-create worktree per `worktree-discipline.instructions.md` (Phase 0)
4. Invoke `dev-discipline.agent` for plan + approval gate
5. On approval: stop. Report the three follow-up commands to run:
   `/anvil:red <ticket>`, `/anvil:green <ticket>`, `/anvil:refactor <ticket>`

### Whole-ticket RED and GREEN

- `/anvil:red <ticket>` / `apm run anvil:red --param ticket=<id>`: reads the
  ticket, enumerates every acceptance criterion, writes a complete failing
  test suite covering happy path + edge cases per criterion. Single commit:
  `test(scope): add failing tests for <ticket> acceptance criteria`.
- `/anvil:green <ticket>` / `apm run anvil:green --param ticket=<id>`:
  reads the same ticket, writes minimum production code to make the full
  suite pass. Single commit: `feat(scope): implement <ticket>`.

### Integration choice at ticket completion

Happens at the end of `/anvil:refactor` (or `/anvil:green` if no refactor
was warranted). Same five-option matrix as today's `Workflows.md` 3.1.3:

| Option | Effect |
|---|---|
| 1. Squash merge | Collapses RED/GREEN/REFACTOR into one commit on sprint branch; worktree + dev branch removed |
| 2. Merge | Preserves RED/GREEN/REFACTOR history; worktree + dev branch removed |
| 3. Create PR | `gh pr create` runs; worktree kept |
| 4. Keep worktree | No merge; worktree + dev branch kept |
| 5. Discard | Requires confirmation; worktree + dev branch removed |

### `apm.yml`

```yaml
name: anvil-core-stable
version: 2.0.0
description: Anvil discipline — agents, skills, and parameterized prompts for human-driven sprint TDD. No dispatch.
author: Olino3
license: MIT
dependencies:
  apm:
    - Olino3/anvil/packages/anvil-common-stable
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

## Package: anvil-orchestrator-stable

Single-stage automation. Wraps core's prompts and agents with a stage-level
approval gate; where a stage benefits from dispatch (develop's RED → GREEN),
uses single-level sub-agent dispatch only. Never dispatches an orchestrator
from another orchestrator. Closest match to today's Anvil UX.

### Contents

```
.apm/
├── agents/
│   ├── develop-orchestrator.agent.md       # plan → RED → GREEN → REFACTOR → integration
│   ├── sprint-orchestrator.agent.md        # generate sprint → optional one-ticket kickoff
│   ├── roadmap-orchestrator.agent.md       # roadmap edit → optional sprint kickoff
│   └── review-orchestrator.agent.md        # run BA → auto-apply cleanup
├── skills/
│   └── orchestration-gates/SKILL.md        # when to stop for approval, how to resume
└── prompts/
    ├── anvil-develop.prompt.md             # OVERRIDES core equivalent
    ├── anvil-sprint.prompt.md              # OVERRIDES
    ├── anvil-roadmap.prompt.md             # OVERRIDES
    └── anvil-review.prompt.md              # OVERRIDES
```

**No `.apm/commands/` directory.** Same rule as core: the four prompt files
compile to slash commands on Claude/OpenCode automatically and override
core's compiled outputs by last-writer-wins at the compiled path (e.g.
`.claude/commands/anvil/develop.md`).

Orchestrator does **not** ship `red.agent`, `green.agent`, or their prompts —
those come from core unchanged.

### Unit of automation per orchestrator

| Agent | Unit | What it automates beyond core |
|---|---|---|
| `develop-orchestrator` | One ticket | 4+ manual command invocations → one approval |
| `sprint-orchestrator` | One sprint generation + optional one-ticket kickoff | Removes "manually invoke develop after sprint" friction |
| `review-orchestrator` | One review + auto-apply cleanup | "Read BA-REPORT, manually apply recommendations" → one approval |
| `roadmap-orchestrator` | One roadmap edit + optional sprint kickoff | Removes "manually invoke sprint after roadmap" friction |

### develop-orchestrator flow

1. Execute core's `anvil-develop.prompt.md` logic for Phase 0 (locate, verify
   deps, worktree, plan, approval). Stop as core does.
2. On approval — additional steps beyond core:
   - Dispatch `@red <ticket>` (core's `red.agent`); wait for completion;
     inspect commit
   - Dispatch `@green <ticket>` (core's `green.agent`); wait; inspect commit
   - If refactor warranted, invoke core's `anvil-refactor.prompt.md` inline
     (no dedicated refactor agent — the prompt is self-contained discipline)
3. Run verification steps from the ticket. On failure: stop and report; do
   not auto-loop.
4. Present the five-option integration-choice matrix.
5. Execute the chosen option (worktree cleanup / `gh pr create` / keep).

### sprint-orchestrator flow (v2.0.0 scope)

1. Invoke `pm.agent` to generate the sprint (same as core's
   `/anvil:sprint`).
2. Prompt: *"Develop the first unblocked ticket now?"*
3. If yes: hand off to `develop-orchestrator` for that single ticket. When
   that ticket completes, stop.
4. If no: stop immediately.

**No multi-ticket loop.** Walking the dep graph and developing every ticket
is reserved for `anvil-autonomous-stable`.

### review-orchestrator flow

1. Invoke `ba.agent` to produce `BA-REPORT.md` (same as core's
   `/anvil:review`).
2. Present BA's cleanup recommendations (splits, archival, dependency
   healing, status corrections).
3. Single approval gate. On approval: auto-apply all recommended cleanup
   actions. Rebuild sprint `README.md` via `sprint-syncer.agent`.

### roadmap-orchestrator flow

1. Invoke `pd.agent` conversation (same as core's `/anvil:roadmap`).
2. When the conversation ends and the roadmap is saved, prompt:
   *"Kick off a sprint for the current phase?"*
3. If yes: hand off to `sprint-orchestrator`. Stop after one sprint kickoff.

### Dispatch rules

- Single-level only. The four orchestrator agents are parents; `red.agent`
  and `green.agent` are leaves.
- An orchestrator never dispatches another orchestrator. Roadmap → sprint and
  sprint → develop handoffs are control-flow handoffs in the orchestrator
  logic, not nested sub-agent dispatches. The orchestrator "hands off" by
  invoking the next orchestrator's *prompt* inline — effectively chaining
  prompts, not nesting contexts.
- Host-conditional dispatch is APM's responsibility at compile time: Claude
  compiles to Task-tool dispatch; Cursor to `@agent-name` via its 2.5+
  nested sub-agent model; OpenCode to `mode: subagent` + Task; Copilot to
  `/fleet` or `@agent-name`.
- Fallback: if a host cannot dispatch, the orchestrator inlines the
  `red.prompt.md` / `green.prompt.md` body into its own session. Documented
  degradation; user still gets the ticket completed, loses the sub-agent's
  isolated context window.

### `apm.yml`

```yaml
name: anvil-orchestrator-stable
version: 2.0.0
description: Anvil orchestrator — high-level human-in-the-loop automation for sprint TDD. One stage, one approval, full inner loop.
author: Olino3
license: MIT
dependencies:
  apm:
    - Olino3/anvil/packages/anvil-common-stable
    - Olino3/anvil/packages/anvil-core-stable
  mcp: []
scripts:
  anvil:develop: anvil-develop.prompt.md
  anvil:sprint: anvil-sprint.prompt.md
  anvil:roadmap: anvil-roadmap.prompt.md
  anvil:review: anvil-review.prompt.md
```

## Compilation & host behavior

### What lands where when orchestrator is installed

For a user project with all four hosts set up:

| Source | Claude Code | Copilot CLI | Cursor | OpenCode |
|---|---|---|---|---|
| `agents/*.agent.md` | `.claude/agents/*.md` | `.github/agents/*.agent.md` | `.cursor/agents/*.md` | `.opencode/agents/*.md` |
| `prompts/*.prompt.md` | `.claude/commands/anvil/*.md` (renamed; is the slash command) | `.github/prompts/*.prompt.md` | runnable via `apm run` only (Cursor lacks a slash command concept) | `.opencode/commands/*.md` (renamed; is the slash command) |
| `skills/*/SKILL.md` | `.claude/skills/*/SKILL.md` | `.github/skills/*/SKILL.md` | `.cursor/skills/*/SKILL.md` | `.opencode/skills/*/SKILL.md` |
| `instructions/*.instructions.md` (from common) | compiled into agent preambles | `.github/instructions/*.instructions.md` | `.cursor/rules/*.mdc` | depends on OpenCode instruction support |

Every host additionally gets `apm run anvil:<script>` working for the
auto-discovered prompts.

### Override mechanics

1. APM resolves dependencies in topological order — deepest first. In
   practice: `anvil-common-stable` → `anvil-core-stable` →
   `anvil-orchestrator-stable`.
2. Each package deploys its `.apm/prompts/*.prompt.md` to the compiled path
   (e.g. `.claude/commands/anvil/develop.md`) in that order.
3. When orchestrator's prompt compiles to the same path as core's, APM's
   last-writer-wins collision rule overwrites core's file with
   orchestrator's.
4. Lockfile records per-file provenance. `apm uninstall
   anvil-orchestrator-stable` removes the orchestrator version and
   re-deploys core's version via stale-file cleanup + remaining-deps
   re-integration.

### User-visible result

Same slash command name (`/anvil:develop`) does different things based on
which packages are installed. Core-only: plan-and-stop. Orchestrator
installed: full inner loop. No parallel command namespaces for the user to
learn.

### Gemini

No compile target. No Gemini-shaped files generated. Gemini users would
either author their own files manually or wait for a future package that
inlines the discipline into single prompts with no dispatch.

## Pack & distribute

APM's `apm pack` produces self-contained artifacts:

- `apm pack --format apm` — standard APM bundle; useful for CI caching.
- `apm pack --format plugin --target <host>` — standalone plugin directory
  consumable by the host directly, no APM required.

### v2.0.0 release artifacts

Eight pre-built plugin bundles attached to the GitHub release:

```
anvil-core-stable-2.0.0-claude.tar.gz
anvil-core-stable-2.0.0-copilot.tar.gz
anvil-core-stable-2.0.0-cursor.tar.gz
anvil-core-stable-2.0.0-opencode.tar.gz
anvil-orchestrator-stable-2.0.0-claude.tar.gz
anvil-orchestrator-stable-2.0.0-copilot.tar.gz
anvil-orchestrator-stable-2.0.0-cursor.tar.gz
anvil-orchestrator-stable-2.0.0-opencode.tar.gz
```

Built by CI via `apm pack --format plugin --target <host>` per package per
host. Zero authoring cost; removes the "install APM first" prerequisite for
host-native users.

### Recommended `.gitignore` for end-user projects

`apm_modules/` is usually ignored — APM docs note it's optional to commit.
Commit it only when (a) CI cannot run `apm install`, or (b) context links
between primitives need to resolve directly in git-indexed files. The
Anvil README will spell this out in the install section.

## Migration & release

v2.0.0 is a hard cut. No shim preserving the v1.x `anvil` plugin name.

### What's removed

- `plugins/anvil/` directory in full
- `.claude-plugin/marketplace.json` (moves to repo root as
  `marketplace.json`)
- Root `apm.yml` as a comment-only shim (replaced with a workspace
  `apm.yml`)
- `Workflows.md` as it stands today (rewritten for the three-package model)

### What arrives

- `marketplace.json` at repo root, listing the three packages with
  `anvil-common-stable` flagged internal
- `packages/anvil-common-stable/`, `packages/anvil-core-stable/`,
  `packages/anvil-orchestrator-stable/`
- `shared/` directory for maintainer docs (`Workflows.md`, `CONTRIBUTING.md`,
  `specs/`)
- Workspace `apm.yml` at repo root for contributor-local dev (optional)

### v1 → v2 user mapping

| v1.x | v2.0.0 equivalent |
|---|---|
| `claude /plugin install anvil` | `claude /plugin install anvil-orchestrator-stable` |
| `apm install anvil@anvil-plugins` | `apm install anvil-orchestrator-stable@anvil` |
| (no equivalent today — manual steps) | `claude /plugin install anvil-core-stable` |

README leads with this table in a "v1.x users: here's the mapping" section.

### Release sequence

1. Branch `v2.0.0-alpha` off `develop`. Keep `main` on v1.4.0 for the
   duration.
2. Build the three packages under `packages/`. Author directly in the new
   `.apm/` layout.
3. Validate locally — in a scratch project, `apm marketplace add ./`
   (local path), install each package into each of the four hosts, walk
   through the user-facing flows.
4. Author the new `marketplace.json`.
5. Delete `plugins/anvil/`, the old `.claude-plugin/marketplace.json`, and
   the shim root `apm.yml`. One commit — clean cut.
6. Rewrite `README.md` and `shared/Workflows.md`.
7. Build 8 plugin bundles in CI via `apm pack --format plugin --target
   <host>`.
8. Tag `v2.0.0`, push, create GitHub release with bundles attached. Release
   notes lead with the hard-cut notice and the v1→v2 mapping.
9. Merge `v2.0.0-alpha` → `develop` → `main`.

### Versioning post-v2.0.0

- Each package carries its own `version:` in `apm.yml`.
- Common bumps freely; core/orchestrator pin it via lockfile.
- Core and orchestrator bump together only when the override contract
  changes (new command moving between packages). Otherwise independent.
- Repo-level tags: `v2.0.0` marks the state where all three hit 2.0.0.
  Later individual bumps get prefixed tags like
  `anvil-core-stable-v2.1.0`. APM resolves
  `Olino3/anvil/packages/anvil-core-stable#v2.1.0` against those.

## Risks

Three to verify during implementation before trusting the design:

1. **APM's override-by-install-order rule.** "Last writer wins" is stated
   in APM's docs; the exact ordering rule (alphabetical? manifest order?
   resolution order?) is under-documented. Must be verified with a spike
   before the orchestrator override flow is trusted. If ambiguous,
   fallback is distinct command names (`/anvil:develop` core,
   `/anvil:auto-develop` orchestrator) and the override model is dropped.
2. **OpenCode and Copilot sub-agent dispatch.** Cursor has nested dispatch
   explicitly since 2.5; Claude has it. OpenCode and Copilot single-level
   dispatch is *assumed* to work but is thinly documented. v2.0.0
   implementation must test this early on both; if dispatch fails, fall
   back to inlining the agent body (documented degradation).
3. **Plugin-bundle naming collisions.** Eight artifacts per release; the
   naming convention
   `anvil-<package>-<version>-<host>.tar.gz` must be locked before the
   first release so CI and humans find the right asset.

## Open questions (non-blocking)

- **Script namespace style.** `anvil:red` (colon, APM doc style) vs.
  `anvil-red` (dash). Spec currently uses colon; trivially changeable.
- **OpenCode instruction support.** If OpenCode doesn't have a first-class
  instructions home yet, common's instructions compile into agent
  preambles for OpenCode targets (same treatment Claude gets). To verify
  at implementation time.
- **Workspace-level `apm.yml` content.** Whether the repo-root `apm.yml`
  needs dev-only dependencies for maintainer tooling, or can be a bare
  metadata stub. Decide at implementation time.
