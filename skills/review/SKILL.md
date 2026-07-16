---
name: review
description: Use /review to assess a supplied scope or working diff for quality, security, performance, and simplicity without applying fixes.
---

# Review

Treat invocation arguments as the review scope, fixed point, or requirements.
If absent, review the current working diff against the best available spec or
task context.

Delegate the review to the `code-reviewer` subagent when available, with the
scope and best available spec or task context. Otherwise load and follow
`code-review-and-quality`, `security-and-hardening`, `performance-optimization`,
and `code-simplification` directly. Apply HTML or UI review only when the
changed surface requires it.

Report findings in severity order with concrete locations, failure scenarios,
and verification gaps. Distinguish required fixes from optional suggestions.

Do not modify files, commit, push, or open a pull request.
