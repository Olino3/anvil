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
