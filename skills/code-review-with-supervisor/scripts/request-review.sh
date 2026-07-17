#!/usr/bin/env bash
set -euo pipefail

readonly API_URL="http://127.0.0.1:8000/v1/chat/completions"
readonly API_KEY="local-dev-key"
readonly MODEL="gpt-5-6-thinking-extended"

if [[ $# -ne 2 ]]; then
  printf 'Usage: %s <github-issue-url> <github-pull-request-url>\n' "$0" >&2
  exit 2
fi

issue_url=${1%/}
pull_request_url=${2%/}

if [[ ! $issue_url =~ ^https://github\.com/([^/]+)/([^/]+)/issues/([0-9]+)$ ]]; then
  printf 'Error: expected issue URL https://github.com/<owner>/<repo>/issues/<number>\n' >&2
  exit 2
fi
issue_owner=${BASH_REMATCH[1]}
issue_repo=${BASH_REMATCH[2]}
ticket_number=${BASH_REMATCH[3]}
issue_repo_url="https://github.com/${issue_owner}/${issue_repo}"

if [[ ! $pull_request_url =~ ^https://github\.com/([^/]+)/([^/]+)/pull/([0-9]+)$ ]]; then
  printf 'Error: expected pull request URL https://github.com/<owner>/<repo>/pull/<number>\n' >&2
  exit 2
fi
pr_owner=${BASH_REMATCH[1]}
pr_repo=${BASH_REMATCH[2]}
pr_number=${BASH_REMATCH[3]}
pr_repo_url="https://github.com/${pr_owner}/${pr_repo}"

for command in curl gh jq; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'Error: required command not found: %s\n' "$command" >&2
    exit 1
  fi
done

ticket_title=$(gh issue view "$issue_url" --json title --jq .title)
ticket_slug=$(printf '%s' "$ticket_title" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')

if [[ -z $ticket_slug ]]; then
  printf 'Error: could not derive an artifact slug from issue title: %s\n' "$ticket_title" >&2
  exit 1
fi

review_path=".scratch/${ticket_slug}/reviews/${ticket_number}-pr-${pr_number}-code-review.md"
if [[ -e $review_path ]]; then
  printf 'Error: review already exists: %s\n' "$review_path" >&2
  exit 1
fi

prompt=$(cat <<EOF
@github @review.md

Use the review skill to review this pull request against its originating ticket.

Originating ticket:
${issue_url}

Pull request:
${pull_request_url}

Inspect the repositories, current code, complete pull-request diff, discussion, checks, ticket body, and ticket comments:
${issue_repo_url}
${pr_repo_url}

The caller will save the result to:
${review_path}

Return only the final code-review Markdown as text, ready to copy directly to disk. Lead with findings ordered by severity and include exact file and line references. If there are no findings, state that explicitly and identify residual risks or testing gaps. Do not create files, narrate your work, add a preamble, wrap the review in a Markdown code fence, or emit file-citation markers.
EOF
)

request=$(jq -n \
  --arg model "$MODEL" \
  --arg prompt "$prompt" \
  '{model: $model, messages: [{role: "user", content: $prompt}], stream: false, metadata: {"chatgpt_temporary_chat": false}}')

if ! response=$(curl -sS --fail-with-body \
  --connect-timeout 15 \
  --max-time 1800 \
  -X POST "$API_URL" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H 'Content-Type: application/json' \
  -d "$request"); then
  printf 'Error: supervisor request failed\n' >&2
  exit 1
fi

if ! review=$(jq -er '.choices[0].message.content | select(type == "string" and length > 0)' <<<"$response"); then
  api_error=$(jq -r '.error.message // "missing choices[0].message.content"' <<<"$response" 2>/dev/null || true)
  printf 'Error: invalid supervisor response: %s\n' "$api_error" >&2
  exit 1
fi

mkdir -p "$(dirname "$review_path")"
temporary_path=$(mktemp "${review_path}.tmp.XXXXXX")
trap 'rm -f "$temporary_path"' EXIT
printf '%s\n' "$review" >"$temporary_path"
mv "$temporary_path" "$review_path"
trap - EXIT

printf '%s\n' "$review_path"
