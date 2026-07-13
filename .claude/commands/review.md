---
description: Run a full quality, security, performance, simplification, and HTML review
---

Apply the `caveman` skill for concise communication throughout this command. Do not apply `ponytail`; review should be thorough, not minimal.

Run the full review pipeline:

1. Use `code-review-and-quality` for the primary five-axis review: correctness, readability, architecture, security, and performance.
2. Use `security-and-hardening` for a focused security pass.
3. Use `performance-optimization` for a focused performance pass.
4. Use `code-simplification` to identify clarity-preserving simplifications.
5. Use `explain-diff-html` to produce a rich HTML explanation of the reviewed change.

Workflow:

1. Treat `$ARGUMENTS` as the review target: PR URL, commit range, branch, file path, or natural-language review request.
2. If no argument is provided, review the current working tree diff and recent commits against the current branch.
3. Inspect the real code paths, not only the diff.
4. Do not modify source code unless the user explicitly asks for fixes. Writing a review report is allowed.
5. Order findings by severity and include concrete file/line references where possible.
6. Save the HTML report under `docs/reviews/YYYY-MM-DD-<review-slug>.html` unless the user asks for a different path.
7. End with a concise verdict: ship, fix-then-ship, rework, or reject.

User input:

`$ARGUMENTS`
