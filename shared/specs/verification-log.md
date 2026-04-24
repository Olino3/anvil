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
