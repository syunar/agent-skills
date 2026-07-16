---
name: fix
description: Use /fix to address verified review findings, test failures, or a bounded bug with regression coverage and re-verification.
---

# Fix

Treat invocation arguments as review findings, failing checks, or a bounded bug
scope. Preserve explicit constraints and reject speculative scope expansion.

Verify each reported issue before changing code. Load and follow `tdd` for
behavior bugs, then `incremental-implementation`; use `implement` where its
orchestration helps. Apply the minimum fix and add regression coverage when a
behavior bug is confirmed.

Run focused checks after each fix, then all available checks. Finish by loading
and following `code-review-and-quality` on the resulting diff. Stop with a clear
blocker report if required findings or failures remain.

Do not commit, push, or open a pull request; `/ship` owns delivery.
