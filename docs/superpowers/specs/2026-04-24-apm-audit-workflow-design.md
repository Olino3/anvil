# Design Spec: APM Audit GitHub Workflow

**Date:** 2026-04-24
**Status:** Approved

---

## Context

Anvil's three packages (`anvil-common-stable`, `anvil-core-stable`, `anvil-orchestrator-stable`) contain `.apm/` instruction files in four categories: agents (`*.agent.md`), prompts (`*.prompt.md`), skills (`SKILL.md`), and instructions (`*.instructions.md`). These files are consumed by multiple AI models (Claude, GPT). Quality and compatibility varies across models.

We have a proven local workflow: use `copilot --model <id> --allow-all -p "<audit prompt>"` to produce structured audit reports (Clarity/Length/Tone/Action scores 1–10) for each file. This design automates that workflow in GitHub Actions CI.

---

## Goals

- On every PR touching any `.apm/**` file: audit only changed files across all models, post a single score-matrix comment on the PR
- On every release tag: audit ALL `.apm/**` files across all models, post a full compatibility matrix as a release comment
- Adding a new model requires editing exactly one line in one file

---

## Files to Create

```
.github/workflows/
  _apm-audit.yml       # reusable workflow — all logic lives here
  pr-audit.yml         # PR caller
  release-audit.yml    # release tag caller
```

---

## Model Registry

In `_apm-audit.yml`, a single top-level `env` var holds the model list as a JSON array:

```yaml
env:
  AUDIT_MODELS: '["gpt-5.4","gpt-5.5","claude-opus-4.7","claude-sonnet-4.6","claude-haiku-4.5"]'
```

Adding a model = append one string to this array. Nothing else changes.

---

## `_apm-audit.yml` — Reusable Workflow

### Inputs

| Input | Type | Required | Description |
|---|---|---|---|
| `trigger` | string | yes | `pr` or `release` |
| `pr_number` | string | no | PR number (for comment posting) |
| `base_ref` | string | no | Base ref for diff (PR base or previous tag) |
| `head_ref` | string | no | Head ref for diff (PR head or current tag) |

### Job 1: `detect`

- Checks out repo with full history (`fetch-depth: 0`)
- Runs `git diff --name-only ${{ inputs.base_ref }} ${{ inputs.head_ref }}` filtered to `packages/**/.apm/**`
- If trigger=`release` and no changed files found: falls back to `find packages -path '*/.apm/*' -type f` (all .apm files)
- Builds JSON matrix: cross-product of `changed_files × AUDIT_MODELS`
- Outputs: `matrix` (JSON), `changed_files` (newline list), `file_count` (int)
- If `file_count == 0`: sets `skip=true` output, downstream jobs check this and exit early

### Job 2: `audit`

- `needs: detect`
- `if: needs.detect.outputs.skip != 'true'`
- `strategy: matrix: include: ${{ fromJson(needs.detect.outputs.matrix) }}`
  - Each matrix cell has: `file` (relative path), `model` (model id)
- Each cell:
  1. Checks out repo
  2. Reads the target file
  3. Constructs the audit prompt (inline heredoc) with file content injected
  4. Runs: `copilot --model "${{ matrix.model }}" --allow-all -p "$PROMPT"`
  5. Parses stdout for `Clarity:`, `Length:`, `Tone:`, `Action:` scores using `grep -oP`
  6. Writes scores to step output: `echo "scores=$FILE|$MODEL|$C|$L|$T|$A" >> $GITHUB_OUTPUT`
- `fail-fast: false` so one model failure doesn't cancel the rest

### Job 3: `report`

- `needs: [detect, audit]`
- `if: always() && needs.detect.outputs.skip != 'true'`
- Collects all matrix job outputs via the `needs.audit.outputs` map
- Renders a markdown report:

```markdown
## APM Audit Report

| File | Model | Clarity | Length | Tone | Action | Avg |
|---|---|---|---|---|---|---|
| `anvil-develop/SKILL.md` | claude-opus-4.7 | 8 | 7 | 9 | 6 | 7.5 |
| `anvil-develop/SKILL.md` | gpt-5.5 | 7 | 8 | 8 | 6 | 7.3 |
...

### Lowest Action Scores (priority fixes)
- `orchestration-gates/SKILL.md` — avg Action: 5.4
```

- Posts/updates PR comment using `gh pr comment` with `--edit-last` flag (idempotent re-runs)
- For release trigger: posts as a new comment on the release via `gh release view` + `gh api`

---

## `pr-audit.yml` — PR Caller

```yaml
on:
  pull_request:
    paths:
      - 'packages/**/.apm/**'

jobs:
  audit:
    uses: ./.github/workflows/_apm-audit.yml
    with:
      trigger: pr
      pr_number: ${{ github.event.pull_request.number }}
      base_ref: ${{ github.event.pull_request.base.sha }}
      head_ref: ${{ github.event.pull_request.head.sha }}
    permissions:
      contents: read
      pull-requests: write
```

---

## `release-audit.yml` — Release Tag Caller

```yaml
on:
  push:
    tags:
      - 'v*.*.*'
      - 'anvil-*-stable-v*.*.*'

jobs:
  audit:
    uses: ./.github/workflows/_apm-audit.yml
    with:
      trigger: release
      base_ref: ${{ github.event.before }}
      head_ref: ${{ github.sha }}
    permissions:
      contents: read
      pull-requests: write
```

---

## Error Handling

- `fail-fast: false` on audit matrix — partial results are still reported
- If a model invocation returns no parseable scores, the cell shows `N/A`
- If all cells fail, report job still posts a comment noting the failure
- If `copilot` binary is not on PATH, the step fails fast with a clear error message

---

## Adding a New Model (Operator Runbook)

1. Open `.github/workflows/_apm-audit.yml`
2. Find `AUDIT_MODELS` in the top-level `env` block
3. Append the new model ID string to the JSON array
4. Commit. Next PR or release tag will include the new model automatically.

---

## Out of Scope

- Storing audit results as committed files (PR comment only)
- Blocking merge on score thresholds
- Auditing non-.apm files
