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

Use a scratch APM project outside this repo as a consumer. The published
`apm.yml` files declare transitive deps in GitHub-shorthand form
(`Olino3/anvil/packages/anvil-common-stable`), so a plain `apm install`
against a local path resolves the package's own content from your
checkout but pulls transitive deps from GitHub. Two ways to develop:

**Single-package edits (most common):** edit one package and install it
directly from your local path. Transitive deps fetch from GitHub —
fine when you aren't also editing them in the same change.

```bash
# In your scratch project
apm install /path/to/anvil/packages/anvil-core-stable --target all
# or
apm install /path/to/anvil/packages/anvil-orchestrator-stable --target all
```

**Cross-package edits:** when you're editing common (or core) AND a
downstream package together, push your branch and point the downstream
`apm.yml` at it temporarily, e.g.:

```yaml
dependencies:
  apm:
    - Olino3/anvil/packages/anvil-common-stable#your-branch
```

Revert that change before opening the PR — the dep on `main`-tracking
shorthand is what release builds expect.

## Before opening a PR

1. **All three packages install cleanly into a scratch project.** Install
   one package at a time; verify `apm list` shows the expected scripts and
   the compiled files appear under the target directories.
2. **Override behavior works as designed.** If you touched orchestrator's
   prompts or skills, verify that installing orchestrator overrides core's
   compiled paths. The skill-layer override matters too — see
   `shared/specs/verification-log.md` § "Phase 6 orchestrator-path smoke
   test" for the design iterations that surfaced this.
3. **Deps stay in GitHub-shorthand form.** Each package's `apm.yml`
   declares transitive deps as `Olino3/anvil/packages/<name>` (no absolute
   paths, no `file:` URIs). `apm pack --format plugin` refuses absolute
   paths, so a local-path dep will break the release workflow. If you
   needed a branch-pinned shorthand for cross-package development, revert
   to the unpinned form before requesting review.
4. **TDD discipline applies to the package content itself where tests
   make sense.** Prompts and agents are prose, not code — review for
   consistency with the spec at `shared/specs/2026-04-23-apm-first-marketplace-design.md`.

## Spec-driven changes

Anvil's design is in `shared/specs/YYYY-MM-DD-*.md`. Significant
behavioral changes need a spec update first. Small additions (new skill,
new reference doc) can go straight to a PR.

## Release

`.github/workflows/release.yml` triggers on tags matching `v*.*.*` (whole
marketplace) or `anvil-*-stable-v*.*.*` (single package bump). It builds
the matrix of `{anvil-core-stable, anvil-orchestrator-stable} × {claude,
copilot, cursor, opencode}` — eight `.tar.gz` plugin bundles — and
attaches them to the GitHub release. `anvil-common-stable` is internal
and not bundled directly; it ships transitively inside the other two.

To cut a release:

1. Bump `version:` in the affected package's `apm.yml` (or in all three
   for a synchronized whole-marketplace bump).
2. Merge to `main`.
3. Push the tag — `v<x.y.z>` for whole-marketplace, or
   `anvil-<package>-stable-v<x.y.z>` for a single-package bump.
4. CI builds the eight bundles and creates the release; the workflow's
   `body:` is the release-notes template.

Bundle naming is the locked pattern from
`shared/specs/verification-log.md` § "Risk #3":
`anvil-<package-name>-<version>-<host>.tar.gz`. The release workflow's
rename step enforces it.

For the original sequencing rationale, see
`shared/specs/2026-04-23-apm-first-marketplace-design.md` §
"Release sequence".
