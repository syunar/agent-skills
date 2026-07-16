---
name: plan
description: Use /plan to turn a spec or requirements into an executable, dated implementation plan without changing product code.
---

# Plan

Treat invocation arguments as the spec path or requirements. If absent, use the
current conversation context; ask only when scope cannot be inferred.

Read the requirements, then load and follow `writing-plans`. Load
`codebase-design` only when module boundaries, seams, or architecture need a
decision.

Save the plan under the existing `docs/plans/` convention. Include exact files,
ordered testable tasks, verification commands, dependencies, and out-of-scope
items.

Do not modify product code.
