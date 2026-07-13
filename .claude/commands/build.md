---
description: Implement a plan or spec incrementally with tests
---

Apply the `caveman` skill for concise communication and the `ponytail` skill for simplest-viable implementation throughout this command.

Use `implement` as the primary workflow. Apply `incremental-implementation` and `test-driven-development`/`tdd` as execution discipline.

Workflow:

1. Treat `$ARGUMENTS` as the plan path, spec path, task number, or implementation request.
2. If no argument is provided, look for the most recent plan in `docs/plans/`. If there is no clear plan, ask what to build.
3. Read the plan/spec and inspect the relevant code before editing.
4. Implement in small vertical slices. Keep each slice working, testable, and rollback-friendly.
5. Use TDD where practical: write or identify the failing test, make it pass, then refactor.
6. Run focused verification after each meaningful slice and the broader verification at the end.
7. Use `code-review` after implementation to review the work.
8. Commit verified work to the current branch unless the user explicitly says not to commit.
9. After all slices are complete, push the current branch and create a pull request. If the branch name doesn't describe the change, ask before pushing. Use `gh pr create` to create the PR with a title derived from the plan/spec.

User input:

`$ARGUMENTS`
