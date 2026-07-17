---
name: code-review-with-supervisor
description: Ask the supervisor model to review one GitHub pull request against its originating ticket, save the review locally, and post it to the PR by default.
disable-model-invocation: true
---

# Code Review With Supervisor

Delegate a pull-request review to the supervisor model, save its Markdown response as a local review artifact, and post a comment-level review to the pull request by default.

**Requires the `supervisor` skill to be installed alongside this skill.** Install both together:

```bash
npx skills@latest add syunar/agent-skills --skill supervisor --skill code-review-with-supervisor
```

## 1. Validate the references

After an optional leading `--no-post`, provide either a pull-request URL alone, or an issue URL followed by a pull-request URL.

Expected forms:

```text
https://github.com/<owner>/<repo>/issues/<number>
https://github.com/<owner>/<repo>/pull/<number>
```

If either reference is malformed, ask for valid URLs. If no issue URL is provided, the review will be performed against the pull request alone. The supervisor resolves `@review.md` and uses the GitHub plugin; do not search this repository for `review.md` or duplicate the issue and pull-request contents in the prompt.

Completion criterion: one public GitHub pull-request URL and, when supplied, one public GitHub issue URL are available.

### Supervisor configuration

The helper reads the merged OpenCode configuration through:

```bash
opencode debug config
```

The supervisor configuration must be nested under `provider.supervisor.options` because OpenCode's config validator rejects unknown top-level keys:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "supervisor": {
      "options": {
        "baseUrl": "http://127.0.0.1:8000",
        "apiKey": "<required-api-key>",
        "model": "gpt-5-6-thinking-extended"
      }
    }
  }
}
```

Place this in the global file at `~/.config/opencode/opencode.json`, or in a project-root `opencode.jsonc` to override it per-project. `baseUrl`, `apiKey`, and `model` are required. `baseUrl` is the server root; the helper appends `/v1/chat/completions`. No endpoint, credential, or model default is stored in this repository.

When the `opencode` command is unavailable, the helper falls back to the JSON file at `$XDG_CONFIG_HOME/opencode/opencode.json` or `~/.config/opencode/opencode.json`. That fallback requires strict JSON rather than JSONC.

## 2. Request and save the review

**CRITICAL: When using a Bash tool to run this helper, set its timeout to at least 2,100,000 milliseconds (35 minutes). The supervisor request can take 20–30 minutes.**

Run the bundled helper from the repository root.

By default, the review is saved locally and posted as a comment-level PR review:

```bash
bash skills/code-review-with-supervisor/scripts/request-review.sh '<issue-url>' '<pull-request-url>'
```

To save the review locally without posting:

```bash
bash skills/code-review-with-supervisor/scripts/request-review.sh --no-post '<issue-url>' '<pull-request-url>'
```

`--no-post` must be the first argument. The issue URL remains optional in both forms.

The helper:

1. Parses the optional `--no-post` flag before the URL arguments.
2. Resolves the PR title and derives `.scratch/<slug>/reviews/pr-<pr-number>-code-review.md`, adding a numeric run suffix when needed to preserve existing reviews. If `gh` cannot resolve the title, it uses a repository-and-PR-number slug.
3. Prints the start time, API URL, masked API key, model, destination path, input prompt, and request time.
4. Reads the shared supervisor URL, API key, and model from merged OpenCode configuration, then sends `@review.md`, the available references, their owner/repo, and the destination path to that configured supervisor.
5. Waits up to 30 minutes for a non-streaming response.
6. Extracts and trims the supervisor's complete non-empty review response.
7. Atomically writes the review without overwriting an existing file.
8. By default, appends the local artifact path to a copy of the review and submits it through `gh pr review --comment`.
9. When `--no-post` is present, skips posting.
10. Treats missing `gh` or a failed PR review submission as a warning after the local artifact has been saved.

If the API request, response extraction, or local artifact write fails, report its error and leave no partial artifact. Do not attempt to post when the local save failed, and do not replace the supervisor response with a locally authored review.

Completion criterion: the helper prints the saved review path and its stderr output identifies whether posting succeeded, was skipped via `--no-post`, or failed non-fatally.

## 3. Report the result

Report:

1. The saved review path printed by the helper.
2. One posting result:
   - The review was posted to the pull request.
   - Posting was skipped (`--no-post`).
   - Posting failed, but the local artifact was saved successfully.

Do not claim that the review was posted when the helper emitted a warning.
