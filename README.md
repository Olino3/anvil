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

## Migrating from anvil-core-stable to anvil-orchestrator-stable

Both packages publish four overlapping commands and skills (`anvil-develop`,
`anvil-sprint`, `anvil-roadmap`, `anvil-review`). The orchestrator is
designed to override core's plan-only versions when both are present — see
[How dependencies are installed](#how-dependencies-are-installed) below for
the mechanism.

If you installed `anvil-core-stable` first and now want to switch to
`anvil-orchestrator-stable`, **do not just `apm install` orchestrator on
top of core**. APM will refuse to overwrite core's already-deployed files
(it treats them as locally-authored) and you will end up running core's
plan-only `/anvil-develop` even though orchestrator is in your manifest.

Clean migration:

```bash
apm uninstall Olino3/anvil/packages/anvil-core-stable
apm prune
apm install Olino3/anvil/packages/anvil-orchestrator-stable
```

`apm prune` removes the transitive `anvil-common-stable` and any deployed
files left behind. After this sequence the orchestrator install lays down
its overrides on a clean tree and `/anvil-develop` will run the automated
inner loop. Verify with:

```bash
head -2 .claude/commands/anvil-develop.md
# expect: description: Automated one-ticket TDD loop (flattened)...
```

The reverse migration (orchestrator → core) is symmetric: `apm uninstall`
orchestrator, `apm prune`, then install core.

## How dependencies are installed

`anvil-orchestrator-stable` depends on `anvil-core-stable`, which depends
on `anvil-common-stable`. APM resolves the tree shallow-first:
**orchestrator deploys first, then common, then core**. When two packages
publish a file at the same compiled path (e.g. both ship
`anvil-develop.prompt.md`), the **first writer wins** — the deeper
package hits an existing file and APM logs it in the install diagnostics:

```
-- Diagnostics --
  [!] 8 files skipped -- local files exist, not managed by APM
    Use 'apm install --force' to overwrite
      +- .claude/commands/anvil-develop.md
      +- .claude/commands/anvil-review.md
      +- .claude/commands/anvil-roadmap.md
      +- .claude/commands/anvil-sprint.md
    [anvil-core-stable]
      +- .claude/skills/anvil-develop
      ...
```

This is the **intended** behavior, not a bug — orchestrator's overrides
win because they deploy before core. The four "skipped" files and four
"skipped" skill directories from core are exactly what the orchestrator
replaces. A clean orchestrator install always emits this 8-file skip
block.

Implications:

- A clean install of orchestrator from a fresh project produces
  orchestrator's `/anvil-develop` automatically. No flags or hand-edits
  needed.
- The override applies at both the prompt layer (`.claude/commands/`) and
  the skill layer (`.claude/skills/<name>/SKILL.md`). Skill overrides are
  necessary because the host's skill loader can otherwise re-trigger
  core's plan-and-stop flow even when the prompt is overridden.
- If you ever see core's plan-only `/anvil-develop` while orchestrator is
  the declared dep, the cause is install **history**: an earlier state
  where core's files landed first. See troubleshooting below.
- Pass `--force` to `apm install` only if you are intentionally replacing
  hand-edited files; it is not normally needed.

## Troubleshooting

### `/anvil-develop` runs the plan-only flow even though I installed `anvil-orchestrator-stable`

**Symptom.** `/anvil-develop <ticket>` produces a plan, asks for approval,
and stops — instead of continuing into RED → GREEN → REFACTOR
automatically.

**Diagnosis.** Read the first two lines of
`.claude/commands/anvil-develop.md`. If the description starts with
`Plan implementation of a single sprint ticket...`, you have core's
version installed. Orchestrator's description starts with
`Automated one-ticket TDD loop (flattened)...`.

**Cause.** Almost always install history: core was installed first (or a
previous install left core's files in `.claude/`), so when orchestrator
was added APM saw core's files as locally-authored and refused to
overwrite. Hand-patching the files works once but is overwritten or
re-skipped on the next `apm install`, and `apm.lock.yaml` ends up
inconsistent with what's on disk.

**Fix.** Fully clean the install state, then reinstall orchestrator from
scratch:

```bash
# from your consumer project root
apm uninstall Olino3/anvil/packages/anvil-orchestrator-stable
apm uninstall Olino3/anvil/packages/anvil-core-stable   # if present in apm.yml
apm prune                                               # removes orphaned transitives
apm install Olino3/anvil/packages/anvil-orchestrator-stable#<ref>
```

Verify the install log emits the expected 8-file skip block (see
[How dependencies are installed](#how-dependencies-are-installed)) and
confirm the description on `.claude/commands/anvil-develop.md`.

### `apm install --dry-run` shows files would be removed from packages "no longer in apm.yml"

That's a sign your lock file references a package URL that doesn't match
the current `apm.yml` (e.g. you switched between `Olino3/anvil` and
`Olino3/anvil/packages/<name>` shorthand). Run the clean migration
sequence above; it regenerates `apm.lock.yaml` from the current
manifest.

### Reproducing an install in isolation

To rule out consumer-local state when diagnosing override or precedence
issues, reproduce the install in a scratch directory pointing at the
remote branch:

```bash
mkdir /tmp/anvil-test && cd /tmp/anvil-test
apm init -y
apm install -t claude -v 'Olino3/anvil/packages/anvil-orchestrator-stable#feature/v2.0.0-alpha'
head -2 .claude/commands/anvil-develop.md
```

The verbose log's `-- Diagnostics --` section is the ground truth on
which package's content won which path.

## Quick start

```bash
/anvil-init                   # detect stack, write config
/anvil-roadmap                # create ROADMAP.md (pd-agent conversation)
/anvil-sprint MVP             # break phase into tickets (pm-agent)
/anvil-develop MVP-001        # implement ticket (behavior depends on installed package)
/anvil-review MVP             # sprint health + verification
```

## Commands

| Command | anvil-core-stable | anvil-orchestrator-stable |
|---|---|---|
| `/anvil-init` | interactive setup | same |
| `/anvil-roadmap` | pd conversation | pd conversation + optional sprint handoff |
| `/anvil-sprint <phase>` | pm generates sprint | pm + optional one-ticket handoff |
| `/anvil-develop <ticket>` | locate + worktree + plan, then stop | full inner loop: plan → RED → GREEN → REFACTOR → integration |
| `/anvil-red <ticket>` | whole-ticket failing suite | same (from core) |
| `/anvil-green <ticket>` | whole-ticket minimum code | same (from core) |
| `/anvil-refactor <ticket>` | self-contained refactor + integration choice | same (from core) |
| `/anvil-review <phase>` | ba reports; no auto-apply | ba + auto-apply cleanup with approval |
| `/anvil-sync <phase>` | rebuild sprint README | same (from core) |
| `/anvil-status [phase]` | read-only summary | same (from core) |

Slash commands compile from the `anvil-<stage>` script keys in each
package's `apm.yml`. Hosts (Claude Code, Copilot CLI, Cursor, OpenCode)
surface them with a dash separator — `/anvil-<stage>` — because their
slash-command grammar doesn't accept colons. The same scripts are also
runnable via APM directly: `apm run anvil-<stage> --param ...`.

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

All Anvil agents are leaf sub-agents dispatched from the main session.
There are no orchestrator agents — with `anvil-orchestrator-stable`
installed, the orchestration runs in the main session itself (Claude
Code does not support nested sub-agent dispatch, so the orchestration is
flattened).

| Agent | Source package | Role |
|---|---|---|
| `@pd` | core | Product Director — roadmap |
| `@pm` | core | Project Manager — sprint tickets |
| `@ba` | core | Business Analyst — sprint health |
| `@sprint-syncer` | core | Rebuild sprint README |
| `@red` | core | Whole-ticket failing test suite |
| `@green` | core | Whole-ticket minimum implementation |
| `@dev-discipline` | core | Plan and stop (waits for approval; never continues to RED/GREEN) |
| `@dev-plan` | orchestrator | Plan and return (no flow control; main session owns the approval gate and continues to RED on approval) |

## Workflow playbook

For the full day-to-day playbook — greenfield loop, course corrections,
drift recovery, parallel tickets — see
[`shared/Workflows.md`](shared/Workflows.md).

## Contributing

See [`shared/CONTRIBUTING.md`](shared/CONTRIBUTING.md).

## License

GPL-3.0 — see [LICENSE](LICENSE).
