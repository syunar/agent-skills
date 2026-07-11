---
description: Implement a plan or spec incrementally with tests
agent: build
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
7. Before committing, do a lightweight self-review: compare changes against the plan/spec, confirm tests prove the intended behavior, check for obvious bugs, dead code, unrelated edits, and scope creep, and apply `ponytail` to remove unnecessary abstraction or complexity. Fix clear issues inline. Do not run the full `/review` pipeline unless the user asks.
8. Use `code-review` after implementation to review the work.
9. Commit verified work to the current branch unless the user explicitly says not to commit. Do not push unless explicitly asked.

User input:

`$ARGUMENTS`
