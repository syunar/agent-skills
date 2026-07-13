---
description: Grill requirements, update docs, and save a dated spec
---

Apply the `caveman` skill for concise communication and the `ponytail` skill for simplest-viable scope throughout this command.

Use this workflow:

1. Use `grill-with-docs` as the primary workflow.
2. Ask one question at a time and wait for the user's answer.
3. If a fact can be discovered from the codebase, inspect the codebase instead of asking.
4. As domain terms and hard-to-reverse decisions crystallize, use `domain-modeling` behavior: update `CONTEXT.md` and create ADRs in `docs/adr/` only when warranted.
5. Continue until shared understanding is reached.
6. Then use `to-spec` to synthesize the discussion and save the spec to `docs/specs/YYYY-MM-DD-<feature-slug>.md`.
7. Do not implement or create an implementation plan unless the user explicitly asks.

User input:

`$ARGUMENTS`

If no input was provided, ask the user what idea, feature, or design they want to spec.
