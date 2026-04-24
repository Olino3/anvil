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
