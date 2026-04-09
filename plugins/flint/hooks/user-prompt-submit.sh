#!/usr/bin/env bash
# UserPromptSubmit hook for flint.
# Appends a JSONL line to <vault>/.flint/prompts.log. Best-effort: never fails.

set -u
input="$(cat || true)"

# Best-effort: bail silently if vault unset or missing.
if [ -z "${FLINT_VAULT:-}" ]; then exit 0; fi
if [ ! -d "$FLINT_VAULT" ]; then exit 0; fi

mkdir -p "$FLINT_VAULT/.flint" 2>/dev/null || exit 0
log="$FLINT_VAULT/.flint/prompts.log"

# Extract .prompt from input JSON if possible; otherwise empty.
prompt=""
if command -v jq >/dev/null 2>&1; then
  prompt="$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null || true)"
fi

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cwd="$(pwd)"

# Emit a single JSONL line. Escape quotes and backslashes in prompt/cwd.
esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
printf '{"ts":"%s","cwd":"%s","prompt":"%s"}\n' \
  "$ts" "$(esc "$cwd")" "$(esc "$prompt")" >> "$log" 2>/dev/null || true

exit 0
