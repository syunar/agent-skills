---
name: code-review-with-supervisor
description: Ask the supervisor model to review one GitHub pull request against its originating ticket, save the review locally, and optionally post it to the PR.
disable-model-invocation: true
---

# Code Review With Supervisor

Delegate a pull-request review to the supervisor model, save its Markdown response as a local review artifact, and optionally post a comment-level review to the pull request.

## 1. Validate the references

After an optional leading `--post`, provide either a pull-request URL alone, or an issue URL followed by a pull-request URL.

Expected forms:

```text
https://github.com/<owner>/<repo>/issues/<number>
https://github.com/<owner>/<repo>/pull/<number>
```

If either reference is malformed, ask for valid URLs. If no issue URL is provided, the review will be performed against the pull request alone. The supervisor resolves `@github` and `@review.md`; do not search this repository for `review.md` or duplicate the issue and pull-request contents in the prompt.

Completion criterion: one public GitHub pull-request URL and, when supplied, one public GitHub issue URL are available.

## 2. Request and save the review

Run the bundled helper from the repository root.

To save the review locally without posting:

```bash
bash skills/code-review-with-supervisor/scripts/request-review.sh '<issue-url>' '<pull-request-url>'
```

To save the review locally and post a comment-level PR review:

```bash
bash skills/code-review-with-supervisor/scripts/request-review.sh --post '<issue-url>' '<pull-request-url>'
```

`--post` must be the first argument. The issue URL remains optional in both forms.

The helper:

1. Parses the optional `--post` flag before the URL arguments.
2. Resolves the PR title and derives `.scratch/<slug>/reviews/pr-<pr-number>-code-review.md`, adding a numeric run suffix when needed to preserve existing reviews. If `gh` cannot resolve the title, it uses a repository-and-PR-number slug.
3. Prints the start time, API URL, masked API key, model, destination path, input prompt, and request time.
4. Sends `@github`, `@review.md`, the available references, their repository URLs, and the destination path to `gpt-5-6-thinking-extended` at the local supervisor API.
5. Waits up to 30 minutes for a non-streaming response.
6. Extracts and trims the supervisor's complete non-empty review response.
7. Atomically writes the review without overwriting an existing file.
8. When `--post` is present, appends the local artifact path to a copy of the review and submits it through `gh pr review --comment`.
9. Treats missing `gh` or a failed PR review submission as a warning after the local artifact has been saved.

If the API request, response extraction, or local artifact write fails, report its error and leave no partial artifact. Do not attempt to post when the local save failed, and do not replace the supervisor response with a locally authored review.

Completion criterion: the helper prints the saved review path and its stderr output identifies whether posting succeeded, was not requested, or failed non-fatally.

## 3. Report the result

Report:

1. The saved review path printed by the helper.
2. One posting result:
   - The review was posted to the pull request.
   - Posting was not requested.
   - Posting failed, but the local artifact was saved successfully.

Do not claim that the review was posted when the helper emitted a warning.
