---
name: build
description: Use /build to execute a plan or spec incrementally with tests, verification, and review, without shipping it.
---

# Build

Treat invocation arguments as the plan, spec, or task scope. Preserve all
explicit constraints.

Load and follow `incremental-implementation` and `tdd`. Use `implement` where
its orchestration helps, but this skill owns the stage boundary below.

Build the smallest complete vertical slice first. After each slice, run the
focused checks that exercise it. At the end, run all available typechecks,
tests, builds, and end-to-end verification, then load and follow
`code-review-and-quality`.

Stop on failed checks or unresolved required findings. Do not commit, push, or
open a pull request; `/ship` owns delivery even when a composed skill suggests
a commit.
