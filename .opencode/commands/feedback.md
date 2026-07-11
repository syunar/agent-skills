---
description: Address PR review feedback, commit fixes, and push to the existing PR branch
agent: build
---

Apply the `caveman` skill for concise communication throughout this command.

Workflow:

1. Treat `$ARGUMENTS` as the PR URL, PR number, or review feedback text.
2. If a PR URL or number is provided, fetch the review comments via `gh`.
3. If no argument is provided, look for the most recent PR on the current repository and ask before proceeding.
4. For each piece of feedback, understand the concern, locate the relevant code, and apply the fix. Use `test-driven-development` or `tdd` to add or adjust tests as needed.
5. After all fixes are applied, run verification (tests, build, typecheck).
6. Commit fixes to the current branch with messages that reference each piece of feedback.
7. Push to the existing PR branch.
8. Optionally leave a `gh pr comment` summarizing what was addressed.

Do not change behavior outside the scope of the feedback unless it is a direct dependency. Do not use `ponytail` — address feedback thoroughly.
