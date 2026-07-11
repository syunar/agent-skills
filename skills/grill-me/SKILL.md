---
name: grill-me
description: A relentless interview to sharpen a plan or design.
---

Run a grilling session. If the agent can load other skills, load and follow
the `grilling` skill. If not, use this fallback workflow:

Interview the user relentlessly about every aspect of the plan until reaching
shared understanding. Walk down each branch of the design tree, resolving
dependencies between decisions one-by-one. For each question, provide your
recommended answer.

Ask one question at a time and wait for feedback before continuing. If a fact
can be found by exploring the codebase, look it up rather than asking. The
decisions belong to the user; put each decision to them and wait.

Do not enact the plan until the user confirms shared understanding.
