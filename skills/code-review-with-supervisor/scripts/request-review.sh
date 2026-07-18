#!/usr/bin/env bash
set -euo pipefail

printf 'Start time: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')" >&2

no_post=false
additional_context=
while [[ ${1:-} == --* ]]; do
  case $1 in
    --no-post)
      if [[ $no_post == true ]]; then
        printf 'Usage: %s [--no-post] [--additional-context <text>] [<github-issue-url>] <github-pull-request-url>\n' "$0" >&2
        exit 2
      fi
      no_post=true
      shift
      ;;
    --additional-context)
      if [[ -n $additional_context || $# -lt 2 || -z $2 || $2 == --* ]]; then
        printf 'Usage: %s [--no-post] [--additional-context <text>] [<github-issue-url>] <github-pull-request-url>\n' "$0" >&2
        exit 2
      fi
      additional_context=$2
      shift 2
      ;;
    *)
      printf 'Usage: %s [--no-post] [--additional-context <text>] [<github-issue-url>] <github-pull-request-url>\n' "$0" >&2
      exit 2
      ;;
  esac
done

case $# in
  1)
    pull_request_url=${1%/}
    issue_url=
    ;;
  2)
    issue_url=${1%/}
    pull_request_url=${2%/}
    if [[ ! $issue_url =~ ^https://github\.com/([^/]+)/([^/]+)/issues/([0-9]+)$ ]]; then
      printf 'Error: expected issue URL https://github.com/<owner>/<repo>/issues/<number>\n' >&2
      exit 2
    fi
    ;;
  *)
    printf 'Usage: %s [--no-post] [--additional-context <text>] [<github-issue-url>] <github-pull-request-url>\n' "$0" >&2
    exit 2
    ;;
esac

if [[ ! $pull_request_url =~ ^https://github\.com/([^/]+)/([^/]+)/pull/([0-9]+)$ ]]; then
  printf 'Error: expected pull request URL https://github.com/<owner>/<repo>/pull/<number>\n' >&2
  exit 2
fi
pr_owner=${BASH_REMATCH[1]}
pr_repo=${BASH_REMATCH[2]}
pr_number=${BASH_REMATCH[3]}

for command in curl jq; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'Error: required command not found: %s\n' "$command" >&2
    exit 1
  fi
done

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_bootstrap="${script_dir}/../../supervisor/scripts/lib/config.sh"
if [[ ! -f $config_bootstrap ]]; then
  printf 'Error: supervisor config bootstrap not found at %s\n' "$config_bootstrap" >&2
  printf 'Install the "supervisor" skill alongside this skill:\n' >&2
  printf '  npx skills@latest add syunar/agent-skills --skill supervisor --skill code-review-with-supervisor\n' >&2
  exit 1
fi
source "$config_bootstrap"

gh_available=false
if command -v gh >/dev/null 2>&1; then
  gh_available=true
fi

review_slug="${pr_owner}-${pr_repo}-pr-${pr_number}"

if [[ $gh_available == true ]]; then
  if pr_title=$(gh pr view "$pull_request_url" --json title --jq .title 2>/dev/null); then
    title_slug=$(printf '%s' "$pr_title" \
      | tr '[:upper:]' '[:lower:]' \
      | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')

    if [[ -n $title_slug ]]; then
      review_slug=$title_slug
    else
      printf 'Warning: could not derive an artifact slug from PR title; using URL-derived slug: %s\n' \
        "$review_slug" >&2
    fi
  else
    printf 'Warning: could not resolve PR title with gh; using URL-derived slug: %s\n' \
      "$review_slug" >&2
  fi
else
  printf 'Warning: gh is not installed; using URL-derived artifact slug: %s\n' \
    "$review_slug" >&2
fi

review_directory=".scratch/${review_slug}/reviews"
mkdir -p "$review_directory"
review_path="${review_directory}/pr-${pr_number}-code-review.md"
run_number=2
while ! (set -o noclobber; : >"$review_path") 2>/dev/null; do
  review_path="${review_directory}/pr-${pr_number}-code-review-${run_number}.md"
  ((run_number += 1))
done
trap 'rm -f "$review_path"' EXIT

if [[ -n $issue_url ]]; then
  prompt=$(cat <<EOF
@review.md

Use the GitHub plugin to review this pull request against its originating ticket.

Repository: ${pr_owner}/${pr_repo}
Originating ticket: ${issue_url}
Pull request: ${pull_request_url}

Use the GitHub plugin to inspect the repositories, current code, complete pull-request diff, discussion, checks, ticket body, and ticket comments.

The caller will save the result to:
${review_path}

Return only the final code-review as plain Markdown text without any JSON, YAML, HTML, code fences, structured data, or non-Markdown content. Lead with findings ordered by severity and include exact file and line references. If there are no findings, state that explicitly and identify residual risks or testing gaps. Do not create files, narrate your work, add a preamble, wrap the review in a Markdown code fence, or emit file-citation markers.
EOF
)
else
  prompt=$(cat <<EOF
@review.md

Use the GitHub plugin to review this pull request.

Repository: ${pr_owner}/${pr_repo}
Pull request: ${pull_request_url}

Use the GitHub plugin to inspect the repository, current code, complete pull-request diff, discussion, and checks.

The caller will save the result to:
${review_path}

Return only the final code-review as plain Markdown text without any JSON, YAML, HTML, code fences, structured data, or non-Markdown content. Lead with findings ordered by severity and include exact file and line references. If there are no findings, state that explicitly and identify residual risks or testing gaps. Do not create files, narrate your work, add a preamble, wrap the review in a Markdown code fence, or emit file-citation markers.
EOF
)
fi

if [[ -n $additional_context ]]; then
  prompt+=$(printf '\n\nAdditional context:\n%s' "$additional_context")
fi

request=$(jq -n \
  --arg model "$SUPERVISOR_MODEL" \
  --arg prompt "$prompt" \
  '{model: $model, messages: [{role: "user", content: $prompt}], stream: false, metadata: {"chatgpt_temporary_chat": false}}')

printf 'API URL: %s\nAPI key: %s****\nModel: %s\nOutput: %s\nInput prompt:\n%s\n\n' \
  "$SUPERVISOR_API_URL" "${SUPERVISOR_API_KEY:0:4}" "$SUPERVISOR_MODEL" "$review_path" "$prompt" >&2

request_started_at=$SECONDS
if ! response=$(curl -sS --fail-with-body \
  --connect-timeout 15 \
  --max-time 1800 \
  -X POST "$SUPERVISOR_API_URL" \
  -H "Authorization: Bearer ${SUPERVISOR_API_KEY}" \
  -H 'Content-Type: application/json' \
  -d "$request"); then
  printf 'Error: supervisor request failed (url=%s, model=%s, time=%ss)\n' \
    "$SUPERVISOR_API_URL" "$SUPERVISOR_MODEL" "$((SECONDS - request_started_at))" >&2
  exit 1
fi
printf 'Request time: %ss\n' "$((SECONDS - request_started_at))" >&2

temporary_path=$(mktemp "${review_path}.tmp.XXXXXX")
trap 'rm -f "$temporary_path" "$review_path"' EXIT

if ! jq -er '.choices[0].message.content | select(type == "string" and length > 0)' <<<"$response" >"$temporary_path"; then
  rm -f "$temporary_path"
  api_error=$(jq -r '.error.message // "missing choices[0].message.content"' <<<"$response" 2>/dev/null || true)
  api_error_redacted=${api_error//"${SUPERVISOR_API_KEY}"/"***"}
  printf \
    'Error: invalid supervisor response (url=%s, model=%s): %s\n' \
    "$SUPERVISOR_API_URL" \
    "$SUPERVISOR_MODEL" \
    "$api_error_redacted" \
    >&2
  exit 1
fi

mv "$temporary_path" "$review_path"
trap - EXIT

review=$(cat "$review_path"; printf x)
review=${review%x}
review=${review%$'\n'}

if [[ $no_post == true ]]; then
  printf 'PR review post: skipped (--no-post)\n' >&2
elif [[ $gh_available != true ]]; then
  printf 'Warning: gh is not installed; review saved locally but was not posted\n' >&2
else
  # Sanitize for posting: strip leading non-Markdown artifacts (JSON,
  # structured metadata). Preserve raw file verbatim.
  # Accept heading-first or paragraph-first Markdown. Then validate
  # the complete body for remaining structured patterns.
  review_to_post=$(printf '%s' "$review" | awk '
    {
      if (!found) {
        if (/^[[:space:]]*$/) next
        pos = match($0, /#+[[:space:]]/)
        if (pos > 0) { $0 = substr($0, pos); gsub(/["}]+$/, "", $0); found = 1; if (length > 0) print; next }
        if ($0 ~ /^[[:alnum:]#*>\-[`\[]/) { found = 1; print; next }
        exit 1
      }
      print
    }
  ' || true)
  if [[ -z $review_to_post ]]; then
    printf 'Warning: supervisor response not valid Markdown; skipping post\n' >&2
  elif grep -qE \
    '(start_line|end_line|original_line|num_lines)[[:space:]]*[:=][[:space:]]*[0-9]|"[a-z_]+"[[:space:]]*:' \
    <<< "$review_to_post"; then
    printf 'Warning: supervisor response contains structured metadata; skipping post\n' >&2
  else
    if post_error=$(
      printf '%s\n\n---\n*Full review saved to: `%s`*' \
        "$review_to_post" \
        "$review_path" |
      gh pr review "$pull_request_url" \
        --comment \
        --body-file - \
        2>&1
    ); then
      printf 'PR review post: posted to %s\n' "$pull_request_url" >&2
    else
      printf 'Warning: failed to post PR review; local artifact remains at %s\n' \
        "$review_path" >&2
      printf '%s\n' "$post_error" >&2
    fi
  fi
fi

printf '%s\n' "$review_path"
