---
name: implement
description: "Implement a piece of work based on an implementation plan, spec, or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the implementation plan, spec, or tickets.

When given an implementation plan, follow its code and verification steps in order. If planned code no longer matches current files, stop and ask the user to rerun `/to-plan`; do not redesign around the mismatch.

Without an implementation plan, use /tdd where possible at pre-agreed seams. Run typechecking and focused tests regularly, then the full test suite once at the end.

Once done, use /code-review to review the work.

Commit the completed ticket once to the current branch after verification passes.
