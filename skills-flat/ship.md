---
name: ship
description: Use /ship for the final review, verification, commit, push, and pull-request delivery gates.
---

# Ship

Treat invocation arguments as the delivery target and preserve explicit user
constraints.

Delegate an independent final review of the full diff and repository state to
the `code-reviewer` subagent when available; otherwise load and follow
`code-review-and-quality` directly. Require all available tests, typechecks,
builds, and runtime verification to pass. Report skipped checks and blockers
plainly; do not ship with unresolved Critical or Important findings.

Load and follow `caveman-commit` to prepare the commit message. Ask for explicit
confirmation immediately before creating the commit. Do not amend unless the
user explicitly requests it.

After a successful commit, ask for separate explicit confirmation before any
push or pull request creation. Never publish, push, or open a pull request
implicitly.
