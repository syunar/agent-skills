---
description: Safely split, commit, and push current changes
agent: publisher
---

Load `caveman-commit` skill before work. Review current working-tree changes, then follow this workflow:

1. Inspect `git status`, `git diff`, current branch, recent commits.
2. Stage all current changes, including untracked files, with `git add -A`.
3. Run `git diff --check`. Abort on failure.
4. Commit all staged changes using `caveman-commit` conventions.
5. Push current branch with `git push origin HEAD` without asking.
6. Report commit SHA and push target.

For GitHub operations, use `gh` CLI. Use high-level `gh` commands first; use `gh api` only when no suitable command exists. Do not use browser automation or manual web actions.

User input:

$ARGUMENTS
