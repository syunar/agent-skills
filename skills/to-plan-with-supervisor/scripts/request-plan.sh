#!/usr/bin/env bash
set -euo pipefail

readonly API_URL="http://127.0.0.1:8000/v1/chat/completions"
readonly API_KEY="local-dev-key"
readonly MODEL="gpt-5-6-thinking-extended"

printf 'Start time: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')" >&2

if [[ $# -ne 1 ]]; then
  printf 'Usage: %s <github-issue-url>\n' "$0" >&2
  exit 2
fi

ticket_url=${1%/}
if [[ ! $ticket_url =~ ^https://github\.com/([^/]+)/([^/]+)/issues/([0-9]+)$ ]]; then
  printf 'Error: expected https://github.com/<owner>/<repo>/issues/<number>\n' >&2
  exit 2
fi

owner=${BASH_REMATCH[1]}
repo=${BASH_REMATCH[2]}
ticket_number=${BASH_REMATCH[3]}
repo_url="https://github.com/${owner}/${repo}"

for command in curl gh jq; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'Error: required command not found: %s\n' "$command" >&2
    exit 1
  fi
done

ticket_title=$(gh issue view "$ticket_url" --json title --jq .title)
ticket_slug=$(printf '%s' "$ticket_title" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')

if [[ -z $ticket_slug ]]; then
  printf 'Error: could not derive a plan slug from issue title: %s\n' "$ticket_title" >&2
  exit 1
fi

plan_directory=".scratch/${ticket_slug}/plans"
mkdir -p "$plan_directory"
plan_path="${plan_directory}/${ticket_number}-${ticket_slug}.md"
run_number=2
while ! (set -o noclobber; : >"$plan_path") 2>/dev/null; do
  plan_path="${plan_directory}/${ticket_number}-${ticket_slug}-${run_number}.md"
  ((run_number += 1))
done
trap 'rm -f "$plan_path"' EXIT

prompt=$(cat <<EOF
@github @to-plan.md

Use the to-plan skill to create one executable implementation plan for this ticket:
${ticket_url}

Inspect its repository and current code:
${repo_url}

The caller will save the result to:
${plan_path}

Fetch the complete ticket and comments, follow its Parent reference and fetch that spec and comments, then inspect the current repository before planning. Return only the final implementation-plan Markdown, beginning with a level-one "Implementation Plan" heading. Include complete mechanically applicable edits and exact verified commands as required by the skill. The Implementation handoff must be exactly:

Run \`/implement ${plan_path}\`.

Do not create files, narrate your work, add a preamble, wrap the plan in a Markdown code fence, or emit file-citation markers. The response is copied directly to disk.
EOF
)

request=$(jq -n \
  --arg model "$MODEL" \
  --arg prompt "$prompt" \
  '{model: $model, messages: [{role: "user", content: $prompt}], stream: false, metadata: {"chatgpt_temporary_chat": false}}')

printf 'API URL: %s\nAPI key: ****\nModel: %s\nOutput: %s\nInput prompt:\n%s\n\n' \
  "$API_URL" "$MODEL" "$plan_path" "$prompt" >&2

request_started_at=$SECONDS
if ! response=$(curl -sS --fail-with-body \
  --connect-timeout 15 \
  --max-time 1800 \
  -X POST "$API_URL" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H 'Content-Type: application/json' \
  -d "$request"); then
  printf 'Request time: %ss\nError: supervisor request failed\n' "$((SECONDS - request_started_at))" >&2
  exit 1
fi
printf 'Request time: %ss\n' "$((SECONDS - request_started_at))" >&2

if ! content=$(jq -er '.choices[0].message.content | select(type == "string" and length > 0)' <<<"$response"); then
  api_error=$(jq -r '.error.message // "missing choices[0].message.content"' <<<"$response" 2>/dev/null || true)
  printf 'Error: invalid supervisor response: %s\n' "$api_error" >&2
  exit 1
fi

plan=$(awk 'found || /^# .*Implementation Plan$/ { found = 1; print }' <<<"$content")
if [[ -z $plan ]]; then
  printf 'Error: supervisor response did not contain an Implementation Plan heading\n' >&2
  exit 1
fi

temporary_path=$(mktemp "${plan_path}.tmp.XXXXXX")
trap 'rm -f "$temporary_path" "$plan_path"' EXIT
printf '%s\n' "$plan" >"$temporary_path"
mv "$temporary_path" "$plan_path"
trap - EXIT

printf '%s\n' "$plan_path"
printf '/implement %s\n' "$plan_path"
