---
name: to-plan
description: Turn one ticket and its parent spec into a local executable implementation plan.
disable-model-invocation: true
---

# To Plan

Create one **implementation plan** for one ticket. Assume its implementer has little codebase context and should execute, not redesign.

## 1. Gather sources

Treat the invocation argument as the ticket reference. Fetch its full body and comments, then follow its `Parent` reference and fetch the parent spec's full body and comments.

If the ticket reference is missing, ask for it. If the parent spec cannot be identified, stop and ask for its reference. Never guess requirements.

The spec owns feature-wide intent and decisions. The ticket owns this slice's behaviour and acceptance criteria. Surface contradictions instead of resolving them silently.

Completion criterion: both sources and all comments are in context, and every ticket acceptance criterion is listed for coverage.

## 2. Explore current code

Read relevant domain glossary and ADRs. Find current implementation and test patterns, exact commands, symbols, types, and files this ticket touches. Prefer existing seams, utilities, dependencies, and style. Plan the smallest change that satisfies the ticket.

Completion criterion: every planned path, symbol, command, and prior-art reference is verified against the current repository.

## 3. Design the blueprint

Map files before ordering tasks. Split the ticket into the smallest tasks that each complete their own test cycle. Fold setup, configuration, and docs into the task that needs them.

For behaviour changes, use this order:

1. Write complete failing-test code.
2. Run an exact command and observe the expected failure.
3. Write complete minimal production code.
4. Run an exact command and observe the expected pass.

Do not force a failing test for documentation, configuration, or trivial mechanical edits. End with every relevant repository lint, typecheck, focused-test, and full-suite command that actually exists. Omit unavailable or irrelevant checks.

Every code-changing step must show complete final code for the stated edit. Include imports, signatures, error handling, and surrounding replacement context needed for mechanical application. Use line numbers only as navigation aids; code content is authoritative.

Completion criterion: a low-context implementer can apply every edit and run every check without making a design decision.

## 4. Write the plan

Save it to `.scratch/<feature-slug>/plans/<ticket-number>-<ticket-slug>.md`. Create parent directories when needed. This file is temporary and must remain uncommitted. Change no product files.

Use this structure:

````markdown
# <Ticket title> Implementation Plan

**Ticket:** <reference>
**Parent spec:** <reference>

**Goal:** <one sentence>

**Architecture:** <execution-relevant approach; omit for trivial changes>

**Tech stack:** <relevant technologies and existing dependencies; omit when unchanged>

## Global constraints

- <exact feature-wide constraint copied from the spec>

## Acceptance-criteria coverage

| Acceptance criterion | Plan task |
| --- | --- |
| <criterion> | Task N |

## File map

- Create: `exact/path` — <responsibility>
- Modify: `exact/path` — <responsibility>
- Test: `exact/path` — <behaviour covered>

### Task N: <deliverable>

**Files:**
- Create: `exact/path`
- Modify: `exact/path`
- Test: `exact/path`

**Interfaces:** <omit when this task creates or changes no shared interface>
- Consumes: <exact existing signatures>
- Produces: <exact new signatures>

- [ ] **Step 1: Write the failing test**

```<language>
<complete test code>
```

- [ ] **Step 2: Verify red**

Run: `<exact command>`
Expected: FAIL with `<specific reason>`

- [ ] **Step 3: Write minimal implementation**

```<language>
<complete production code>
```

- [ ] **Step 4: Verify green**

Run: `<exact command>`
Expected: `<specific success output or observable result>`

## Final verification

- [ ] Run: `<exact relevant command>` — Expected: `<specific success output or observable result>`

## Implementation handoff

Run `/implement <plan-path>`.
````

Omit empty constraint or interface entries instead of inventing content.

Completion criterion: the plan exists at the required local path, changes no product files, and contains complete mechanically applicable steps for every acceptance criterion.

## 5. Self-review

Before reporting completion:

1. Map every ticket acceptance criterion to a task.
2. Map every relevant spec decision to a task or global constraint.
3. Remove `TBD`, `TODO`, "implement later", "handle edge cases", "write tests", "similar to", and every other placeholder.
4. Confirm every referenced type, method, property, import, path, and command exists now or is defined completely in an earlier step.
5. Confirm later snippets use the exact names and types introduced earlier.
6. Confirm `/to-plan` changed only the local plan.

Fix failures inline. Completion criterion: all six checks pass. Then report only the saved plan path and `/implement <plan-path>` handoff.

Adapted from obra/superpowers `skills/writing-plans/SKILL.md`.
