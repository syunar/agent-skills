---
name: code-review-with-supervisor
description: Ask the supervisor model to review one GitHub pull request against its originating ticket and save the review locally.
disable-model-invocation: true
---

# Code Review With Supervisor

Delegate a pull-request review to the supervisor model, then save its Markdown response as a local review artifact.

## 1. Validate the references

The first argument is the originating public GitHub issue URL (optional); the second is the public GitHub pull-request URL.

Expected forms:

```text
https://github.com/<owner>/<repo>/issues/<number>
https://github.com/<owner>/<repo>/pull/<number>
```

If either reference is malformed, ask for valid URLs. If no issue URL is provided, the review will be performed against the pull request alone. The supervisor resolves `@github` and `@review.md`; do not search this repository for `review.md` or duplicate the issue and pull-request contents in the prompt.

Completion criterion: one public GitHub issue URL and one public GitHub pull-request URL are available.

## 2. Request and save the review

Run the bundled helper from the repository root:

```bash
bash skills/code-review-with-supervisor/scripts/request-review.sh '<issue-url>' '<pull-request-url>'
```

The helper:

1. Resolves the PR title (or issue title, if an issue URL was given) and derives `.scratch/<slug>/reviews/pr-<pr-number>-code-review.md`, adding a numeric run suffix when needed to preserve existing reviews.
2. Prints the start time, API URL, masked API key, model, destination path, input prompt, and request time.
3. Sends `@github`, `@review.md`, both references, their repository URLs, and the destination path to `gpt-5-6-thinking-extended` at the local supervisor API.
4. Waits up to 30 minutes for a non-streaming response.
5. Extracts the supervisor's complete non-empty review response.
6. Atomically writes the review without overwriting an existing file.

If the API request or response extraction fails, report its error and leave the filesystem unchanged. Do not replace the supervisor response with a locally authored review.

Completion criterion: the helper prints the saved review path.

## 3. Report the artifact

Report only the saved review path printed by the helper.
