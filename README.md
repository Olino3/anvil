# Anvil

A language-agnostic Claude Code plugin for agentic sprint-driven software development using TDD.

## Overview

Anvil provides a structured workflow for software development driven by AI agents:

**pd-agent** creates ROADMAP → **pm-agent** creates sprint → **dev-agent** completes tickets via TDD using **red-agent** and **green-agent** → **ba-agent** reviews sprint health

## Quick Start

```bash
# Install the plugin
claude plugin install anvil

# Set up your project
/anvil:init

# Create a project roadmap
/anvil:roadmap

# Generate a sprint from a roadmap phase
/anvil:sprint MVP

# Implement a ticket
/anvil:develop MVP-001

# Review sprint health
/anvil:review MVP
```

## Commands

| Command | Purpose |
|---|---|
| `/anvil:init` | Interactive project setup — detect stack, write config |
| `/anvil:roadmap` | Create or update ROADMAP.md |
| `/anvil:sprint <phase>` | Break a ROADMAP phase into sprint tickets |
| `/anvil:develop <ticket>` | Implement a ticket using TDD |
| `/anvil:review <phase>` | Sprint health analysis and verification |
| `/anvil:sync <phase>` | Fix README drift from ticket state |
| `/anvil:status [phase]` | Quick read-only status summary |

## Workflow

```
init → roadmap → sprint → develop (repeat per ticket) → review → iterate
```

1. **Init** — Configure your project's components, test commands, and git conventions
2. **Roadmap** — Define phased milestones with goals and deliverables
3. **Sprint** — Break a phase into granular, dependency-ordered tickets
4. **Develop** — Implement tickets one at a time with TDD (RED → GREEN → REFACTOR)
5. **Review** — Verify completed work, check ROADMAP coverage, sync artifacts

## Agents

| Agent | Role |
|---|---|
| pd-agent | Product Director — creates/updates ROADMAP.md |
| pm-agent | Project Manager — breaks phases into sprint tickets |
| dev-agent | Developer — implements tickets via TDD sub-agents |
| red-agent | RED — writes failing tests |
| green-agent | GREEN — minimum code to pass tests |
| ba-agent | Business Analyst — sprint health and verification |
| sprint-syncer | Syncs README status from ticket metadata |

## Project Artifacts

Anvil creates these files in your project:

```
project-root/
├── ROADMAP.md                    # Project roadmap (phases, milestones)
└── docs/anvil/
    ├── config.yml                # Project config (components, commands)
    └── sprints/
        └── v1.0.0-mvp/           # Sprint directory
            ├── README.md         # Ticket table, dependencies, progress
            ├── MVP-001-*.md      # Tickets
            ├── SPIKE-001-*.md    # Follow-up tickets
            └── BA-REPORT.md      # Health report
```

## Language Support

Anvil is language-agnostic. It discovers your tech stack during `/anvil:init` and reads test/build commands from `docs/anvil/config.yml` at runtime. Works with any language that has a test runner.

## TDD Enforcement

Every ticket is implemented through the RED/GREEN/REFACTOR cycle:

1. **RED** — `red-agent` writes failing tests → commit
2. **GREEN** — `green-agent` writes minimum code to pass → commit
3. **REFACTOR** — clean up if needed → commit

Run `/anvil:tdd` for the full discipline reference.
