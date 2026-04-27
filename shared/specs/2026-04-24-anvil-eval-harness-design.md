# Anvil Eval Harness Design

**Date:** 2026-04-24
**Status:** Approved for implementation planning
**Target release:** v2.1.0 (lands after v2.0.0 ships; independent of the three
Anvil packages)

## Summary

Build an in-repo eval harness at `shared/evals/` that exercises Anvil's
prompts across a curated (case × model) matrix using GitHub Agentic
Workflows (gh-aw) as the model-invocation layer and Microsoft APM as the
package-install layer. v1 grades every run with golden (dataset-driven)
and heuristic (executable) graders, derives pairwise comparisons across
models at gather time, and ships the trace-capture plumbing needed for
future context-retrieval and LLM-as-judge graders without re-running
workers.

The harness is maintainer-only infrastructure. It never ships to end
users via `apm install`. It provides three audiences three distinct
surfaces: a per-PR comment (regression signal on every PR), a nightly
dashboard (matrix-over-time drift and flake signal), and per-worker
artifacts (drill-down for debugging any single cell).

## Motivation

Anvil is becoming a cross-host, cross-model product. The v2.0.0 design
moves authoring into `.apm/` and compiles to Claude / Copilot / Cursor /
OpenCode targets. Three axes of change now ship in the same repo:

1. **Prompt changes.** Every edit to `.apm/prompts/*.prompt.md` is a
   behavioral change to an agent visible to users.
2. **Model changes.** Users run Anvil on whichever frontier model their
   host exposes. Opus 4.7 today, something else next quarter.
3. **Package changes.** `anvil-orchestrator-stable` overrides core's
   slash commands; their interaction only shows up when both are
   installed.

Without an eval harness, every such change ships on vibes. The harness
gives us a reproducible regression signal (did my PR break `anvil-red`
on opus-4.7?), a model-drift signal (did gemini-3.1-pro suddenly start
generating malformed sprint READMEs?), and a release-readiness signal
(what percentage of cases pass across the full matrix for v2.1.0?).

## Out of scope (v1 of the harness)

- **LLM-as-judge grader.** Stub file + grader interface ships; no
  implementation. Promoted to v2 once baseline golden+heuristic signal
  is stable and we know what LLM-judging adds on top.
- **Context-retrieval / precision eval.** The raw `Trace` data is
  captured on every run, so v2 can add this grader without re-running
  workers. Not wired in v1.
- **Agent-level and workflow-level units.** v1 is prompt-level only.
  Scaffolding that forces agent or end-to-end-workflow units to fit the
  prompt-level harness is not added.
- **Auto-alerting, auto-filing issues, release-blocker automation.**
  A broken PR check is loud on its own; nightly regressions surface on
  the dashboard the next morning. Escalation rules are deferred until
  we have baseline data about what is noise.
- **Cross-repo / published-package eval.** The harness tests Anvil-as-
  sources in this repo. "Run evals against `apm install Olino3/anvil`
  in a sibling repo" is a future state, not v1.
- **Local full-matrix runs.** The harness's authoring loop (render one
  case, inspect one trace) runs locally. The full matrix only runs in
  gh-aw.
- **Test-retry / flake handling.** A failing worker is a fail. If flake
  becomes a real problem, we add retry later with data.

## Architecture

### Four concerns, four directories

```
shared/evals/
├── cases/                   # authored test cases (data)
├── workflows/               # gh-aw agentic workflows (model invocation)
├── graders/                 # grader implementations (pure functions)
├── runner/                  # local orchestration helpers
└── README.md                # how to author a case; how to run locally
```

Case authors only touch `cases/`. Grader authors only touch
`graders/`. Workflow authors only touch `workflows/`. The `runner/`
directory is the single integration surface. Graders consume a
normalized `CaseResult` struct, not raw `/tmp/gh-aw/` paths.

### Unit under test: prompt

One test case targets one `.apm/prompts/<name>.prompt.md`. Fast,
deterministic, and the natural shape for golden + heuristic + pairwise
grading. Agent-level and workflow-level units are out of scope.

### Fixture representation

Inline per-case: each case bundles its own minimal fixture tree under
`cases/<prompt>/<case-id>/fixture/`. The worker workflow inlines
fixture content into the rendered prompt body — the agent sees the
fixture as prompt context, not as filesystem state. Migration to
shared fixture repos is a file move, not a rewrite, when duplication
becomes the dominant cost.

Exception: prompts whose output must be *executed* to grade
(`anvil-red`, `anvil-green`, `anvil-refactor`) declare
`needs_filesystem: true`. Their workers materialize the fixture to a
real workspace before the agent runs, so `heuristic.py` can execute
generated code against the project's test command.

### Engine & model matrix

Two gh-aw engines, six models:

| Engine    | Models                                                           |
|-----------|------------------------------------------------------------------|
| `claude`  | `claude-opus-4.7`, `claude-opus-4.6`, `claude-sonnet-4.6`        |
| `copilot` | `gpt-5.4`, `gpt-5.3-codex`, `gemini-3.1-pro`                     |

`copilot` engine owns all non-Anthropic models — including Gemini,
which Copilot CLI exposes as a selectable backend. This keeps the
harness aligned with what a Copilot-using Anvil user actually runs.
The v2.0.0 package-level decision to not compile to Gemini native is
unaffected: workers invoke Anvil via Copilot's compiled output, not
via a Gemini native compile target.

### Trigger cadence

- **PR path-filter.** Runs when `packages/**/.apm/prompts/**`,
  `packages/**/.apm/agents/**`, `shared/evals/cases/**`, or
  `shared/evals/prompts/**` change. Evals only the cases whose prompt
  changed, full 6-model matrix. Synchronous (`call-workflow`) so the
  dispatcher can post a single results comment on return.
- **Nightly cron, 07:00 UTC.** Full matrix: every case × every model.
  Asynchronous (`dispatch-workflow`). Gatherer fires when workers
  complete; publishes dashboard.
- **`workflow_dispatch`** on the dispatcher for manual overrides
  (select specific prompts, specific models). Cheap escape hatch.

### Grading: per-prompt declared, v1 = golden + heuristic + pairwise

A case's grading rules come from two sources:

1. **Prompt-level defaults** in `shared/evals/prompts/<name>.yml` —
   declares `default_graders`, `needs_filesystem`, and the JSON schema
   the golden grader validates against.
2. **Per-case overrides** in `case.yml`'s `grading.overrides` — for
   narrow cases that need to drop or add a grader.

Three graders ship in v1:

- **`golden.py`** — validates structured output against a schema plus
  content assertions from `case.yml`'s `golden:` block.
- **`heuristic.py`** — executes generated code (sandbox mode) or
  parses agent-produced files (file mode) to assert behavioral
  invariants.
- **`pairwise.py`** — derived at gather time. Compares two
  `CaseResult`s for the same case across different models; emits
  win/tie/loss + diff score.

A fourth file `llm_judge.py` ships as a stub with the grader
interface and `NotImplementedError`. It is not wired to any case or
prompt default. Its presence locks the interface; enabling it in v2
is a config flip, not a refactor.

## Workflow wiring

Four gh-aw workflow files.

### `eval-dispatcher.md` — nightly (async)

Fires on cron or `workflow_dispatch`. Enumerates the (case × model)
matrix. Uses `safe-outputs.dispatch-workflow` to fan out to the
engine-matched worker per pair. Workers run asynchronously.

Frontmatter essentials:

```yaml
on:
  schedule:
    - cron: "0 7 * * *"
  workflow_dispatch:
    inputs:
      prompts: { default: "all" }
      models:  { default: "all" }

engine: claude
model: claude-haiku-4-5

safe-outputs:
  dispatch-workflow:
    workflows: [eval-worker-claude, eval-worker-copilot]
    max: 200
```

### `eval-dispatcher-pr.md` — PR (sync)

Fires on PR path-filter. Enumerates only cases whose prompt or case
file changed. Uses `safe-outputs.call-workflow` — synchronous, blocks
until every worker returns, grades inline, posts one PR comment.

```yaml
on:
  pull_request:
    paths:
      - "packages/**/.apm/prompts/**"
      - "packages/**/.apm/agents/**"
      - "shared/evals/cases/**"
      - "shared/evals/prompts/**"

engine: claude
model: claude-haiku-4-5

permissions:
  contents: read
  pull-requests: write

safe-outputs:
  call-workflow:
    workflows: [eval-worker-claude, eval-worker-copilot]
    max: 20
```

### `eval-worker-claude.md` / `eval-worker-copilot.md`

Accept `workflow_call` (for PR sync path) and `workflow_dispatch`
(for nightly async path) with inputs `{case_id, model,
rendered_prompt, needs_filesystem}`. The worker imports Anvil via
`shared/apm.md` per Microsoft's gh-aw/APM integration, then renders
the case's prompt body as the workflow body.

```yaml
on:
  workflow_call: { inputs: { case_id, model, rendered_prompt, needs_filesystem } }
  workflow_dispatch: { inputs: { case_id, model, rendered_prompt, needs_filesystem } }

engine: claude                    # or copilot in the other file
model: ${{ inputs.model }}

imports:
  - uses: shared/apm.md
    with:
      packages:
        - Olino3/anvil/packages/anvil-common-stable
        - Olino3/anvil/packages/anvil-core-stable
        - Olino3/anvil/packages/anvil-orchestrator-stable

steps:
  - uses: actions/checkout@v4
  - if: ${{ inputs.needs_filesystem }}
    run: python shared/evals/runner/materialize_fixture.py --case "${{ inputs.case_id }}"
  - if: always()
    run: python shared/evals/runner/emit_case_result.py --case "${{ inputs.case_id }}" --model "${{ inputs.model }}" --engine <claude|copilot> > case-result.json
    # engine is the literal matching this worker file's `engine:` frontmatter
  - uses: actions/upload-artifact@v4
    with:
      name: case-result-${{ inputs.case_id }}-${{ inputs.model }}
      path: case-result.json
```

The workflow body is `${{ inputs.rendered_prompt }}` — the full
rendered case prompt including inlined fixture content.

### `eval-gatherer.md` — nightly aggregator

Triggered on `workflow_run: completed` for the two worker workflows.
Waits for a quiet period (no sibling worker started in 10 min),
downloads every `case-result-*` artifact from the matrix run, passes
to `graders/`, publishes the dashboard to `gh-pages`.

```yaml
on:
  workflow_run:
    workflows: [eval-worker-claude, eval-worker-copilot]
    types: [completed]

engine: claude
model: claude-haiku-4-5

permissions:
  contents: write        # to push to gh-pages
  actions: read          # to download artifacts

steps:
  - uses: actions/checkout@v4
  - run: python shared/evals/runner/wait_quiet.py --minutes 10
  - run: python shared/evals/runner/collect_results.py --since 24h > /tmp/results.json
  - run: python shared/evals/runner/grade.py /tmp/results.json > /tmp/report.md
  - run: python shared/evals/runner/publish_dashboard.py /tmp/report.md
```

## Case format

```
shared/evals/cases/<prompt-name>/<case-id>/
├── case.yml
└── fixture/
    └── <inline repo state>
```

`case.yml`:

```yaml
id: anvil-sprint/mvp-phase-happy
prompt: anvil-sprint
description: Happy path — MVP phase with three deliverables generates an ordered sprint.

inputs:
  phase: MVP

skip:
  models: []
  reason: ""

grading:
  overrides: []

golden:
  sprint_readme_must_contain_tickets_for:
    - "user login"
    - "user profile"
    - "password reset"
  ticket_count:
    min: 6
    max: 12
  dep_graph:
    must_be_acyclic: true
    first_ticket_must_have_no_deps: true

heuristic:
  sprint_readme_parses: true
  all_referenced_tickets_exist_as_files: true
```

Prompt-level defaults live at `shared/evals/prompts/<name>.yml`:

```yaml
prompt: anvil-sprint
default_graders: [golden, heuristic, pairwise]
needs_filesystem: false
golden_schema: graders/schemas/anvil-sprint.schema.json
```

## Grader contracts

Every grader is a pure function: `(case, run) → GraderResult`.

```python
@dataclass
class CaseResult:
    case_id: str
    prompt: str
    model: str
    engine: str
    workflow_run_id: int
    inputs: dict
    outputs: dict        # { files: {path: content}, response: str | None }
    trace: Trace
    timing: Timing
    status: Literal["ok", "agent_error", "infra_error"]

@dataclass
class Trace:
    prompt_text: str     # /tmp/gh-aw/aw-prompts/prompt.txt
    agent_stdio: str     # /tmp/gh-aw/agent-stdio.log
    safe_outputs: dict   # /tmp/gh-aw/safeoutputs/agent_output.json
    firewall_log: str    # /tmp/gh-aw/firewall-logs/
    files_touched: list[FileOp]

@dataclass
class GraderResult:
    grader: str
    passed: bool
    score: float         # 0.0-1.0
    details: dict
    error: str | None
```

The runner extracts `outputs.files` from agent tool calls logged in
`agent-stdio.log` and from the worker's workspace at end of run.
Graders never parse raw gh-aw artifact paths.

### `golden.py`

- Validates `outputs.files[expected_path]` against the prompt's JSON
  schema (`graders/schemas/<prompt>.schema.json`).
- Evaluates every assertion in `case.yml`'s `golden:` block (content
  fuzzy-match, structural invariants, count bounds).
- Passes iff every assertion passes. Per-assertion failure detail in
  `GraderResult.details`.

### `heuristic.py`

Two sub-modes, chosen by prompt-level `needs_filesystem`:

- **File mode** (default). Parses agent-produced files via Anvil's
  format validators or regex/AST checks. No sandbox. Covers
  `anvil-sprint`, `anvil-roadmap`, `anvil-plan-ticket`, etc.
- **Sandbox mode.** For `anvil-red`, `anvil-green`, `anvil-refactor`.
  The worker commits the agent's file edits to a scratch branch;
  `heuristic.py` pulls the artifact, runs the project's test command,
  asserts:
  - `anvil-red`: test command exits non-zero and the failing tests
    are newly authored (not pre-existing).
  - `anvil-green`: test command exits zero and no pre-existing tests
    are weakened, skipped, or deleted.
  - `anvil-refactor`: test command exits zero, diff is non-trivial,
    no test modifications.

If gh-aw's native code-exec sandbox is unsuitable, fallback is a
plain `.github/workflows/eval-heuristic-sandbox.yml` regular GitHub
Action dispatched by the gatherer. (Risk #2, below.)

### `pairwise.py`

Runs at gather time, not per-worker. Compares two `CaseResult`s for
the same `case_id` **within the same matrix run** — across different
models. Emits:

- Diff score (semantic diff over structured `outputs`).
- Win / tie / loss — if both passed golden+heuristic, "tie"; if only
  one passed, that one wins.

All pairwise signal is derived from other graders' results. No
authored pairwise data in cases. Pairwise does *not* compare current
run vs prior release — that is a time-series concern served by the
`history.html` page on the dashboard, which reads the same
per-(prompt × model) pass-rate data golden and heuristic emit.

### `llm_judge.py`

Stub. Grader interface + `NotImplementedError`. Not registered as any
case or prompt default. Ships in v1 to lock the interface for v2.

## Reporting

Three surfaces:

1. **PR comment** (per PR run). Single compact table: cases × models,
   cells marked ✅ / ⚠️ / ❌ / 🔥. Lists regressions vs base branch,
   failures with artifact links, warnings (pairwise deltas). Updated
   in place on subsequent pushes to the PR.
2. **Nightly dashboard** (`gh-pages`). Static HTML, two pages:
   `index.html` — current-state heatmap; `history.html` — 30-day
   per-(prompt × model) pass-rate charts. Generated by
   `publish_dashboard.py`; zero runtime JS beyond Chart.js for
   history.
3. **Per-worker artifacts**. gh-aw writes `/tmp/gh-aw/{prompt.txt,
   agent_output.json, agent-stdio.log, firewall-logs/}` on every run.
   Workers additionally upload `case-result.json` (the normalized
   `CaseResult`) as an artifact. The gatherer reads these.

No Slack, email, release-blocker automation, or auto-filed issues in
v1. `workflow_dispatch` on the dispatcher is the manual override.

## Risks

Three to verify during implementation before trusting the harness.

1. **Dynamic `model:` in worker frontmatter.** `engine:` is a literal
   in gh-aw frontmatter; whether `model: ${{ inputs.model }}` (an
   expression) is accepted is unconfirmed in the docs reviewed.
   Fallback if not: one static worker file per (engine, model) — 6
   files auto-generated from a template at author time. Spike early.
2. **Sandbox execution for heuristic grading.** `needs_filesystem`
   cases must execute generated code. gh-aw's code-exec story for
   agentic workflows is under-documented for this use case. Fallback:
   dispatch a plain `.github/workflows/eval-heuristic-sandbox.yml`
   regular GitHub Action from the gatherer, which runs generated code
   in a container and attaches results to the `CaseResult`. Adds one
   file, not a rewrite.
3. **"Matrix run completed" signal for the gatherer.** Nightly
   fan-out produces N workers; `workflow_run: completed` fires
   per-worker but we want to aggregate once. The spec proposes "10
   minutes of quiet after last worker" as a heuristic. Better
   alternatives (dispatcher emits a sentinel artifact carrying
   expected-count; gatherer polls until the count is reached) are
   fallbacks. Decide at implementation time after observing real
   matrix wall-times.

## Open questions (non-blocking)

- **Location of `case-result.json` inside the worker.**
  `$GITHUB_WORKSPACE/case-result.json` is the default; subject to
  gh-aw's workspace model for agentic workflows (agent may run in a
  separate sandbox from `steps:`). Verify at implementation time.
- **Dispatcher-as-agent vs dispatcher-as-steps.** The nightly
  dispatcher can either use an agent that emits dispatch-workflow
  safe-outputs, or a pure `steps:` block that invokes
  dispatch-workflow directly. Both work; agentic is more idiomatic,
  steps-based is cheaper and more deterministic. Pick at
  implementation time.
- **Initial case inventory.** v1 ships with ~10-20 cases. Specific
  cases, prompts covered, and authoring order belong in the
  implementation plan, not this spec.
- **Cost ceiling per nightly run.** 6 models × ~20 cases = 120
  workers per night. Back-of-envelope cost estimate + a monthly
  ceiling belong in the implementation plan before the cron is
  turned on.

## Versioning & compatibility

- The harness lives under `shared/evals/` — maintainer-only, never
  published via APM, no semver.
- Cases and prompts evolve together. The PR path-filter includes both
  `packages/**/.apm/prompts/**` and `shared/evals/cases/**` so either
  side re-runs the matrix. A PR that changes a prompt's contract
  updates its cases in the same commit; reviewable diff.
- Baselines are not blessed snapshots in git — they are the per-case
  assertions in `case.yml`'s `golden:` block. Changes are
  hand-authored, not captured from a previous run.

## References

- Microsoft APM documentation: https://github.com/microsoft/apm
- gh-aw documentation: https://github.github.com/gh-aw/
- gh-aw orchestration patterns:
  https://github.github.com/gh-aw/patterns/orchestration/
- gh-aw/APM integration:
  https://microsoft.github.io/apm/integrations/gh-aw/
- gh-aw debugging artifacts:
  https://github.github.com/gh-aw/troubleshooting/debugging/
- gh-aw CLI and logs:
  https://github.github.com/gh-aw/setup/cli/
- v2.0.0 package design:
  shared/specs/2026-04-23-apm-first-marketplace-design.md
