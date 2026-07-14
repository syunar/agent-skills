---
description: Grill requirements, update docs, and save a dated spec
agent: build
---

Apply the `caveman` skill for concise communication and the `ponytail` skill for simplest-viable scope throughout this command.

Use this workflow:

1. Use `grill-with-docs` as the primary workflow.
2. Ask one question at a time and wait for the user's answer.
3. If a fact can be discovered from the codebase, inspect the codebase instead of asking.
4. If the request is for a new Python backend, Python backend architecture, or a Python backend project structure, also apply `design-python-backend-architecture`. Use its discovery questions, modular-monolith defaults, and output contracts when relevant; do not force its technology defaults over explicit requirements.
5. As domain terms and hard-to-reverse decisions crystallize, use `domain-modeling` behavior: update `CONTEXT.md` and create ADRs in `docs/adr/` only when warranted.
6. Continue until shared understanding is reached.
7. Then use `to-spec` to synthesize the discussion and save the spec to `docs/specs/YYYY-MM-DD-<feature-slug>.md`.
8. Do not implement or create an implementation plan unless the user explicitly asks.

User input:

`$ARGUMENTS`

If no input was provided, ask the user what idea, feature, or design they want to spec.
