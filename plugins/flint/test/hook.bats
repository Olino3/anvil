#!/usr/bin/env bats

setup() {
  export TEST_TMP="$(mktemp -d)"
  export FLINT_VAULT="$TEST_TMP/vault"
  mkdir -p "$FLINT_VAULT/.flint"
  HOOK="$BATS_TEST_DIRNAME/../hooks/user-prompt-submit.sh"
}

teardown() {
  rm -rf "$TEST_TMP"
}

@test "appends JSONL line with prompt, timestamp, cwd" {
  echo '{"prompt":"hello world"}' | "$HOOK"
  run cat "$FLINT_VAULT/.flint/prompts.log"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"prompt":"hello world"'* ]]
  [[ "$output" == *'"ts":'* ]]
  [[ "$output" == *'"cwd":'* ]]
}

@test "exits 0 when FLINT_VAULT is unset (best-effort)" {
  unset FLINT_VAULT
  run bash -c 'echo "{}" | "$0"' "$HOOK"
  [ "$status" -eq 0 ]
}

@test "exits 0 when vault dir does not exist (best-effort)" {
  export FLINT_VAULT="$TEST_TMP/does-not-exist"
  run bash -c 'echo "{}" | "$0"' "$HOOK"
  [ "$status" -eq 0 ]
}

@test "creates .flint dir if vault exists but .flint does not" {
  rm -rf "$FLINT_VAULT/.flint"
  echo '{"prompt":"x"}' | "$HOOK"
  [ -f "$FLINT_VAULT/.flint/prompts.log" ]
}

@test "skips malformed JSON input silently" {
  log="$FLINT_VAULT/.flint/prompts.log"
  run bash -c 'echo "not json" | "$0"' "$HOOK"
  [ "$status" -eq 0 ]
  # prompts.log must not be created (no entry written for malformed input)
  [ ! -f "$log" ]
}
