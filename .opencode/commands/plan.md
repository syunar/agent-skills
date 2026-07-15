---
description: Turn a spec into a bite-sized implementation plan
agent: specifier
---

Apply the `caveman` skill for concise communication and the `ponytail` skill for simplest-viable scope throughout this command.

Use `writing-plans` to turn a spec into an implementation plan.

Workflow:

1. Treat `$ARGUMENTS` as the spec path, feature name, or planning request.
2. If no argument is provided, look for the most recent spec in `docs/specs/`. If there is no clear spec, ask the user which spec to plan from.
3. Inspect the relevant codebase areas before writing tasks.
4. Save the plan to `docs/plans/YYYY-MM-DD-<feature-name>.md` unless the user asks for a different path.
5. Make the plan executable by a fresh engineer: exact files, exact test commands, expected outcomes, no placeholders.
6. Do not implement the plan.
7. For GitHub operations, use the `gh` CLI. Use high-level `gh` commands first; use `gh api` only when no suitable command exists. Do not use browser automation or manual web actions.
8. End by reporting the saved plan path and asking whether the user wants to run `/build` next.

User input:

`$ARGUMENTS`
