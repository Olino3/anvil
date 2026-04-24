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
