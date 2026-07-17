#!/usr/bin/env bash
# Plain Bash test runner (not bats). Per the decision recorded in the issue
# resolution comment at https://github.com/syunar/agent-skills/issues/7#issuecomment-5002767213
# the plan chose a dependency-free bash runner — bats is not required.
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)
config_script="$repo_root/skills/supervisor/scripts/lib/config.sh"
plan_script="$repo_root/skills/to-plan-with-supervisor/scripts/request-plan.sh"
review_script="$repo_root/skills/code-review-with-supervisor/scripts/request-review.sh"

for required_command in bash jq mktemp; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'Error: required test command not found: %s\n' "$required_command" >&2
    exit 1
  fi
done

bash_bin=$(command -v bash)
jq_bin=$(command -v jq)
temporary_root=$(mktemp -d)
trap 'rm -rf "$temporary_root"' EXIT

pass_count=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  pass_count=$((pass_count + 1))
  printf 'PASS: %s\n' "$1"
}

assert_equal() {
  local expected=$1
  local actual=$2
  local message=$3

  if [[ $actual != "$expected" ]]; then
    printf 'Expected:\n%s\nActual:\n%s\n' "$expected" "$actual" >&2
    fail "$message"
  fi
}

assert_contains() {
  local value=$1
  local expected_fragment=$2
  local message=$3

  if [[ $value != *"$expected_fragment"* ]]; then
    printf 'Missing fragment: %s\nValue:\n%s\n' "$expected_fragment" "$value" >&2
    fail "$message"
  fi
}

assert_not_contains() {
  local value=$1
  local forbidden_fragment=$2
  local message=$3

  if [[ $value == *"$forbidden_fragment"* ]]; then
    printf 'Forbidden fragment: %s\nValue:\n%s\n' "$forbidden_fragment" "$value" >&2
    fail "$message"
  fi
}

write_config() {
  local output_path=$1
  local base_url=$2
  local api_key=$3
  local model=$4

  jq -n \
    --arg base_url "$base_url" \
    --arg api_key "$api_key" \
    --arg model "$model" \
    '{
      provider: {
        supervisor: {
          options: {
            baseUrl: $base_url,
            apiKey: $api_key,
            model: $model
          }
        }
      }
    }' >"$output_path"
}

make_opencode_mock() {
  local mock_bin=$1

  mkdir -p "$mock_bin"
  cat >"$mock_bin/opencode" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 || $1 != "debug" || $2 != "config" ]]; then
  printf 'Unexpected opencode arguments: %s\n' "$*" >&2
  exit 64
fi

if [[ ${MOCK_OPENCODE_FAIL:-0} == 1 ]]; then
  exit 17
fi

printf '%s\n' "$(<"$MOCK_OPENCODE_CONFIG")"
EOF
  chmod +x "$mock_bin/opencode"
}

run_loader_with_cli() {
  local config_fixture=$1
  local xdg_config_home=${2:-"$temporary_root/unused-xdg"}
  local fail_mode=${3:-0}
  local mock_bin="$temporary_root/opencode-bin"

  make_opencode_mock "$mock_bin"

  PATH="$mock_bin:$PATH" \
  XDG_CONFIG_HOME="$xdg_config_home" \
  MOCK_OPENCODE_CONFIG="$config_fixture" \
  MOCK_OPENCODE_FAIL="$fail_mode" \
    "$bash_bin" -c '
      set -e
      source "$1"
      printf "%s\n%s\n%s\n" \
        "$SUPERVISOR_API_URL" \
        "$SUPERVISOR_API_KEY" \
        "$SUPERVISOR_MODEL"
    ' _ "$config_script"
}

run_loader_without_cli() {
  local xdg_config_home=$1
  local isolated_bin="$temporary_root/no-opencode-bin"

  mkdir -p "$isolated_bin"
  ln -sf "$jq_bin" "$isolated_bin/jq"

  PATH="$isolated_bin" \
  XDG_CONFIG_HOME="$xdg_config_home" \
  HOME="$temporary_root/home" \
    "$bash_bin" -c '
      set -e
      source "$1"
      printf "%s\n%s\n%s\n" \
        "$SUPERVISOR_API_URL" \
        "$SUPERVISOR_API_KEY" \
        "$SUPERVISOR_MODEL"
    ' _ "$config_script"
}

test_valid_cli_config() {
  local fixture="$temporary_root/valid.json"
  local output

  write_config \
    "$fixture" \
    "http://supervisor.test:9000" \
    "test-api-key" \
    "test-model"

  output=$(run_loader_with_cli "$fixture")

  assert_equal \
    $'http://supervisor.test:9000/v1/chat/completions\ntest-api-key\ntest-model' \
    "$output" \
    "valid merged configuration should load"

  pass "loads all values from opencode debug config"
}

test_trailing_slash_normalization() {
  local fixture="$temporary_root/trailing-slash.json"
  local output

  write_config \
    "$fixture" \
    "http://supervisor.test:9000/" \
    "test-api-key" \
    "test-model"

  output=$(run_loader_with_cli "$fixture")

  assert_equal \
    $'http://supervisor.test:9000/v1/chat/completions\ntest-api-key\ntest-model' \
    "$output" \
    "one trailing slash should be removed before appending the endpoint"

  pass "normalizes a trailing baseURL slash"
}

test_multiple_trailing_slashes_normalization() {
  local fixture="$temporary_root/double-slash.json"
  local output

  write_config \
    "$fixture" \
    "http://supervisor.test:9000//" \
    "test-api-key" \
    "test-model"

  output=$(run_loader_with_cli "$fixture")

  assert_equal \
    $'http://supervisor.test:9000/v1/chat/completions\ntest-api-key\ntest-model' \
    "$output" \
    "multiple trailing slashes should all be removed"

  pass "normalizes multiple trailing slashes"
}

test_missing_config_block() {
  local fixture="$temporary_root/missing-block.json"
  local output

  printf '{}\n' >"$fixture"

  if output=$(run_loader_with_cli "$fixture" 2>&1); then
    fail "missing supervisor block should fail"
  fi

  assert_contains \
    "$output" \
    "supervisor config is missing at provider.supervisor.options" \
    "missing block should identify the required path"

  pass "rejects a missing supervisor configuration block"
}

test_missing_field() {
  local field_name=$1
  local jq_path=$2
  local expected_display=$3
  local fixture="$temporary_root/missing-${field_name}.json"
  local complete_fixture="$temporary_root/complete-${field_name}.json"
  local output

  write_config \
    "$complete_fixture" \
    "http://supervisor.test:9000" \
    "test-api-key" \
    "test-model"

  jq "del(${jq_path})" "$complete_fixture" >"$fixture"

  if output=$(run_loader_with_cli "$fixture" 2>&1); then
    fail "missing ${field_name} should fail"
  fi

  assert_contains \
    "$output" \
    "supervisor config field ${expected_display} is required" \
    "missing ${field_name} should identify its exact path"

  pass "rejects missing ${field_name}"
}

test_invalid_merged_json() {
  local fixture="$temporary_root/invalid.json"
  local output

  printf '{not-json\n' >"$fixture"

  if output=$(run_loader_with_cli "$fixture" 2>&1); then
    fail "invalid merged configuration should fail"
  fi

  assert_contains \
    "$output" \
    "merged OpenCode configuration is not valid JSON" \
    "invalid JSON should produce a descriptive error"

  pass "rejects invalid merged JSON"
}

test_merged_config_precedes_global_file() {
  local global_home="$temporary_root/conflicting-xdg"
  local global_config="$global_home/opencode/opencode.json"
  local merged_fixture="$temporary_root/project-override.json"
  local output

  mkdir -p "$(dirname "$global_config")"

  write_config \
    "$global_config" \
    "http://global.test:8000" \
    "global-key" \
    "global-model"

  write_config \
    "$merged_fixture" \
    "http://project.test:8100" \
    "project-key" \
    "project-model"

  output=$(run_loader_with_cli "$merged_fixture" "$global_home")

  assert_equal \
    $'http://project.test:8100/v1/chat/completions\nproject-key\nproject-model' \
    "$output" \
    "merged CLI output should win over the direct global file"

  pass "uses merged project-over-global configuration"
}

test_direct_global_file_fallback() {
  local xdg_home="$temporary_root/fallback-xdg"
  local config_path="$xdg_home/opencode/opencode.json"
  local output

  mkdir -p "$(dirname "$config_path")"

  write_config \
    "$config_path" \
    "http://fallback.test:8200" \
    "fallback-key" \
    "fallback-model"

  output=$(run_loader_without_cli "$xdg_home")

  assert_equal \
    $'http://fallback.test:8200/v1/chat/completions\nfallback-key\nfallback-model' \
    "$output" \
    "global JSON file should be used only when opencode is unavailable"

  pass "falls back to the global JSON file without opencode"
}

test_opencode_failure_does_not_hide_with_file_fallback() {
  local fixture="$temporary_root/opencode-failure.json"
  local xdg_home="$temporary_root/opencode-failure-xdg"
  local global_config="$xdg_home/opencode/opencode.json"
  local output

  mkdir -p "$(dirname "$global_config")"

  write_config \
    "$fixture" \
    "http://merged.test:8300" \
    "merged-key" \
    "merged-model"

  write_config \
    "$global_config" \
    "http://global.test:8400" \
    "global-key" \
    "global-model"

  if output=$(run_loader_with_cli "$fixture" "$xdg_home" 1 2>&1); then
    fail "a failing available opencode command should fail"
  fi

  assert_contains \
    "$output" \
    "could not read merged OpenCode config with: opencode debug config" \
    "a failing CLI should not silently bypass merged layering"

  pass "reports an opencode debug config failure"
}

make_helper_mock_bin() {
  local mock_bin=$1

  mkdir -p "$mock_bin"

  cat >"$mock_bin/opencode" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 || $1 != "debug" || $2 != "config" ]]; then
  printf 'Unexpected opencode arguments: %s\n' "$*" >&2
  exit 64
fi

printf '%s\n' "$(<"$MOCK_OPENCODE_CONFIG")"
EOF

  cat >"$mock_bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ $1 == "issue" && $2 == "view" ]]; then
  printf '%s\n' "${MOCK_GH_TITLE:?}"
  exit 0
fi

if [[ $1 == "pr" && $2 == "view" ]]; then
  printf '%s\n' "${MOCK_PR_TITLE:-Mock PR Title}"
  exit 0
fi

if [[ $1 == "pr" && $2 == "review" ]]; then
  body_capture="${MOCK_PR_REVIEW_BODY_CAPTURE:-}"
  if [[ -n $body_capture ]]; then
    shift 3
    while [[ $# -gt 0 ]]; do
      if [[ $1 == "--body" && $# -ge 2 ]]; then
        printf '%s\n' "$2" >"$body_capture"
        break
      fi
      shift
    done
  fi
  exit 0
fi

printf 'Unexpected gh arguments: %s\n' "$*" >&2
exit 64
EOF

  cat >"$mock_bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$@" >"${MOCK_CURL_CAPTURE:?}"

if [[ ${MOCK_CURL_FAIL:-0} == 1 ]]; then
  exit 22
fi

printf '%s\n' "${MOCK_CURL_RESPONSE:?}"
EOF

  chmod +x \
    "$mock_bin/opencode" \
    "$mock_bin/gh" \
    "$mock_bin/curl"
}

test_plan_helper_uses_shared_config() {
  local fixture="$temporary_root/helper-plan-config.json"
  local mock_bin="$temporary_root/helper-plan-bin"
  local worktree="$temporary_root/helper-plan-worktree"
  local curl_capture="$temporary_root/helper-plan-curl.txt"
  local output
  local curl_arguments
  local plan_path

  write_config \
    "$fixture" \
    "http://supervisor.test:9000" \
    "test-api-key" \
    "test-model"

  make_helper_mock_bin "$mock_bin"
  mkdir -p "$worktree"

  output=$(
    cd "$worktree"
    PATH="$mock_bin:$PATH" \
    MOCK_OPENCODE_CONFIG="$fixture" \
    MOCK_GH_TITLE="Example Ticket" \
    MOCK_CURL_CAPTURE="$curl_capture" \
    MOCK_CURL_RESPONSE='{"choices":[{"message":{"content":"# Implementation Plan\n\nGenerated plan"}}]}' \
      "$bash_bin" "$plan_script" \
        "https://github.com/acme/example/issues/42"
  )

  plan_path="$worktree/.scratch/example-ticket/plans/42-example-ticket.md"
  curl_arguments=$(<"$curl_capture")

  assert_contains \
    "$output" \
    ".scratch/example-ticket/plans/42-example-ticket.md" \
    "plan helper should print its artifact path"

  assert_contains \
    "$output" \
    "/implement .scratch/example-ticket/plans/42-example-ticket.md" \
    "plan helper should preserve the implementation handoff"

  if [[ ! -f $plan_path ]]; then
    fail "plan helper should write the generated plan"
  fi

  assert_equal \
    $'# Implementation Plan\n\nGenerated plan' \
    "$(<"$plan_path")" \
    "plan helper should preserve response extraction"

  assert_contains \
    "$curl_arguments" \
    "http://supervisor.test:9000/v1/chat/completions" \
    "plan helper should use the configured request URL"

  assert_contains \
    "$curl_arguments" \
    "Authorization: Bearer test-api-key" \
    "plan helper should use the configured API key"

  assert_contains \
    "$curl_arguments" \
    '"model": "test-model"' \
    "plan helper should use the configured model"

  pass "plan helper uses shared supervisor configuration"
}

test_plan_helper_without_heading() {
  local fixture="$temporary_root/helper-plan-noheading-config.json"
  local mock_bin="$temporary_root/helper-plan-noheading-bin"
  local worktree="$temporary_root/helper-plan-noheading-worktree"
  local curl_capture="$temporary_root/helper-plan-noheading-curl.txt"
  local output
  local plan_path

  write_config \
    "$fixture" \
    "http://supervisor.test:9000" \
    "test-api-key" \
    "test-model"

  make_helper_mock_bin "$mock_bin"
  mkdir -p "$worktree"

  output=$(
    cd "$worktree"
    PATH="$mock_bin:$PATH" \
    MOCK_OPENCODE_CONFIG="$fixture" \
    MOCK_GH_TITLE="No Heading Ticket" \
    MOCK_CURL_CAPTURE="$curl_capture" \
    MOCK_CURL_RESPONSE='{"choices":[{"message":{"content":"Just freeform content without a heading."}}]}' \
      "$bash_bin" "$plan_script" \
        "https://github.com/acme/example/issues/99"
  )

  plan_path="$worktree/.scratch/no-heading-ticket/plans/99-no-heading-ticket.md"

  assert_contains \
    "$output" \
    ".scratch/no-heading-ticket/plans/99-no-heading-ticket.md" \
    "plan helper should succeed without a heading"

  if [[ ! -f $plan_path ]]; then
    fail "plan helper should write the file even without a heading"
  fi

  assert_equal \
    "Just freeform content without a heading." \
    "$(<"$plan_path")" \
    "plan helper should save content verbatim without heading"

  pass "plan helper succeeds without an Implementation Plan heading"
}

test_review_helper_uses_shared_config() {
  local fixture="$temporary_root/helper-review-config.json"
  local mock_bin="$temporary_root/helper-review-bin"
  local worktree="$temporary_root/helper-review-worktree"
  local curl_capture="$temporary_root/helper-review-curl.txt"
  local output
  local curl_arguments
  local review_path

  write_config \
    "$fixture" \
    "http://review-supervisor.test:9100/" \
    "review-api-key" \
    "review-model"

  make_helper_mock_bin "$mock_bin"
  mkdir -p "$worktree"

  output=$(
    cd "$worktree"
    PATH="$mock_bin:$PATH" \
    MOCK_OPENCODE_CONFIG="$fixture" \
    MOCK_GH_TITLE="Review Ticket" \
    MOCK_PR_TITLE="Mock PR Title" \
    MOCK_CURL_CAPTURE="$curl_capture" \
    MOCK_CURL_RESPONSE='{"choices":[{"message":{"content":"# Code Review\n\nNo findings."}}]}' \
      "$bash_bin" "$review_script" \
        "https://github.com/acme/example/issues/43" \
        "https://github.com/acme/example/pull/9"
  )

  review_path="$worktree/.scratch/mock-pr-title/reviews/pr-9-code-review.md"
  curl_arguments=$(<"$curl_capture")

  assert_contains \
    "$output" \
    ".scratch/mock-pr-title/reviews/pr-9-code-review.md" \
    "review helper should print its artifact path"

  if [[ ! -f $review_path ]]; then
    fail "review helper should write the generated review"
  fi

  assert_equal \
    $'# Code Review\n\nNo findings.' \
    "$(<"$review_path")" \
    "review helper should preserve response extraction"

  assert_contains \
    "$curl_arguments" \
    "http://review-supervisor.test:9100/v1/chat/completions" \
    "review helper should use the configured request URL"

  assert_contains \
    "$curl_arguments" \
    "Authorization: Bearer review-api-key" \
    "review helper should use the configured API key"

  assert_contains \
    "$curl_arguments" \
    '"model": "review-model"' \
    "review helper should use the configured model"

  pass "review helper uses shared supervisor configuration"
}

test_review_helper_preserves_whitespace() {
  local fixture="$temporary_root/helper-review-ws-config.json"
  local mock_bin="$temporary_root/helper-review-ws-bin"
  local worktree="$temporary_root/helper-review-ws-worktree"
  local curl_capture="$temporary_root/helper-review-ws-curl.txt"
  local body_capture="$temporary_root/helper-review-ws-body.txt"
  local output
  local review_path

  write_config \
    "$fixture" \
    "http://review-supervisor.test:9100/" \
    "review-api-key" \
    "review-model"

  make_helper_mock_bin "$mock_bin"
  mkdir -p "$worktree"

  output=$(
    cd "$worktree"
    PATH="$mock_bin:$PATH" \
    MOCK_OPENCODE_CONFIG="$fixture" \
    MOCK_GH_TITLE="Whitespace Review" \
    MOCK_PR_TITLE="Whitespace Review PR" \
    MOCK_PR_REVIEW_BODY_CAPTURE="$body_capture" \
    MOCK_CURL_CAPTURE="$curl_capture" \
    MOCK_CURL_RESPONSE='{"choices":[{"message":{"content":"  \n  # Code Review\n  \nNo findings.  \n  "}}]}' \
      "$bash_bin" "$review_script" \
        "https://github.com/acme/example/issues/98" \
        "https://github.com/acme/example/pull/99"
  )

  review_path="$worktree/.scratch/whitespace-review-pr/reviews/pr-99-code-review.md"

  if [[ ! -f $review_path ]]; then
    fail "review helper should write the file with whitespace content"
  fi

  assert_equal \
    $'  \n  # Code Review\n  \nNo findings.  \n  ' \
    "$(<"$review_path")" \
    "review helper should preserve leading and trailing whitespace in file"

  if [[ ! -f $body_capture ]]; then
    fail "review helper should have posted a review"
  fi

  assert_contains \
    "$(<"$body_capture")" \
    $'  \n  # Code Review\n  \nNo findings.  \n  ' \
    "posted review should contain the whitespace-preserved content"

  assert_contains \
    "$(<"$body_capture")" \
    "*Full review saved to:" \
    "posted review should contain the artifact-path footer"

  pass "review helper preserves whitespace-wrapped content and posts it correctly"
}

test_request_failure_diagnostic_is_useful_and_secret_safe() {
  local fixture="$temporary_root/helper-failure-config.json"
  local mock_bin="$temporary_root/helper-failure-bin"
  local worktree="$temporary_root/helper-failure-worktree"
  local curl_capture="$temporary_root/helper-failure-curl.txt"
  local output

  write_config \
    "$fixture" \
    "http://failure-supervisor.test:9200" \
    "secret-test-key" \
    "failure-model"

  make_helper_mock_bin "$mock_bin"
  mkdir -p "$worktree"

  if output=$(
    cd "$worktree"
    PATH="$mock_bin:$PATH" \
    MOCK_OPENCODE_CONFIG="$fixture" \
    MOCK_GH_TITLE="Failure Ticket" \
    MOCK_CURL_CAPTURE="$curl_capture" \
    MOCK_CURL_FAIL=1 \
    MOCK_CURL_RESPONSE='{}' \
      "$bash_bin" "$plan_script" \
        "https://github.com/acme/example/issues/44" \
        2>&1
  ); then
    fail "failed supervisor request should return non-zero"
  fi

  assert_contains \
    "$output" \
    "url=http://failure-supervisor.test:9200/v1/chat/completions" \
    "request failure should include the configured URL"

  assert_contains \
    "$output" \
    "model=failure-model" \
    "request failure should include the configured model"

  assert_not_contains \
    "$output" \
    "secret-test-key" \
    "request failure must not include the API key"

  pass "request failure includes URL and model without API key"
}

test_invalid_response_redacts_api_key() {
  local fixture="$temporary_root/redaction-config.json"
  local mock_bin="$temporary_root/redaction-bin"
  local worktree="$temporary_root/redaction-worktree"
  local curl_capture="$temporary_root/redaction-curl.txt"
  local output

  write_config \
    "$fixture" \
    "http://redact-supervisor.test:9300" \
    "my-secret-key-123" \
    "redact-model"

  make_helper_mock_bin "$mock_bin"
  mkdir -p "$worktree"

  if output=$(
    cd "$worktree"
    PATH="$mock_bin:$PATH" \
    MOCK_OPENCODE_CONFIG="$fixture" \
    MOCK_GH_TITLE="Redaction Ticket" \
    MOCK_CURL_CAPTURE="$curl_capture" \
    MOCK_CURL_FAIL=0 \
    MOCK_CURL_RESPONSE='{"error":{"message":"invalid API key: my-secret-key-123"}}' \
      "$bash_bin" "$plan_script" \
        "https://github.com/acme/example/issues/45" \
        2>&1
  ); then
    fail "invalid response should return non-zero"
  fi

  assert_contains \
    "$output" \
    "url=http://redact-supervisor.test:9300/v1/chat/completions" \
    "invalid response should include the configured URL"

  assert_contains \
    "$output" \
    "model=redact-model" \
    "invalid response should include the configured model"

  assert_not_contains \
    "$output" \
    "my-secret-key-123" \
    "invalid response must redact the API key from the error message"

  assert_contains \
    "$output" \
    "invalid API key: ***" \
    "invalid response should show redacted error message with ***"

  pass "invalid response redacts API key from error message"
}

main() {
  test_valid_cli_config
  test_trailing_slash_normalization
  test_multiple_trailing_slashes_normalization
  test_missing_config_block
  test_missing_field \
    "baseUrl" \
    ".provider.supervisor.options.baseUrl" \
    "provider.supervisor.options.baseUrl"
  test_missing_field \
    "apiKey" \
    ".provider.supervisor.options.apiKey" \
    "provider.supervisor.options.apiKey"
  test_missing_field \
    "model" \
    ".provider.supervisor.options.model" \
    "provider.supervisor.options.model"
  test_invalid_merged_json
  test_merged_config_precedes_global_file
  test_direct_global_file_fallback
  test_opencode_failure_does_not_hide_with_file_fallback
  test_plan_helper_uses_shared_config
  test_plan_helper_without_heading
  test_review_helper_uses_shared_config
  test_review_helper_preserves_whitespace
  test_request_failure_diagnostic_is_useful_and_secret_safe
  test_invalid_response_redacts_api_key

  printf 'PASS: %d tests\n' "$pass_count"
}

main "$@"
