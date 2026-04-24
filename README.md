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
| `@dev-discipline` | core | Plan and approve (no dispatch) |

## Workflow playbook

For the full day-to-day playbook — greenfield loop, course corrections,
drift recovery, parallel tickets — see
[`shared/Workflows.md`](shared/Workflows.md).

## Contributing

See [`shared/CONTRIBUTING.md`](shared/CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
