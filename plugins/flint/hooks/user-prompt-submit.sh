#!/usr/bin/env bash
# UserPromptSubmit hook for flint.
# Appends a JSONL line to <vault>/.flint/prompts.log. Best-effort: never fails.

set -u
input="$(cat || true)"

# Require jq for safe JSON handling; bail silently if unavailable.
if ! command -v jq >/dev/null 2>&1; then exit 0; fi

# Extract .prompt; skip logging if input is malformed or prompt is empty.
prompt="$(printf '%s' "$input" | jq -er '.prompt // empty' 2>/dev/null)" || exit 0
if [ -z "$prompt" ]; then exit 0; fi

# Resolve vault root: prefer $FLINT_VAULT, fall back to ~/.config/flint/vault-path.
vault="${FLINT_VAULT:-}"
if [ -z "$vault" ] && [ -f "${HOME}/.config/flint/vault-path" ]; then
  vault="$(cat "${HOME}/.config/flint/vault-path")"
fi
if [ -z "$vault" ] || [ ! -d "$vault" ]; then exit 0; fi

mkdir -p "$vault/.flint" 2>/dev/null || exit 0
log="$vault/.flint/prompts.log"

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cwd="$(pwd)"

# Emit a single JSONL line using jq so all JSON string escaping is correct.
jq -nc --arg ts "$ts" --arg cwd "$cwd" --arg prompt "$prompt" \
  '{ts:$ts,cwd:$cwd,prompt:$prompt}' >> "$log" 2>/dev/null || true

exit 0
