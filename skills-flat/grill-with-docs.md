---
name: grill-with-docs
description: A relentless interview to sharpen a plan or design, which also creates docs (ADRs and glossary) as we go.
---

Run a grilling session, using the domain-modeling skill. If the agent can load
other skills, load and follow `grilling` first, then use `domain-modeling` as
decisions crystallize. If not, use this fallback workflow:

Interview the user relentlessly about every aspect of the plan until reaching
shared understanding. Walk down each branch of the design tree, resolving
dependencies between decisions one-by-one. For each question, provide your
recommended answer.

Ask one question at a time and wait for feedback before continuing. If a fact
can be found by exploring the codebase, look it up rather than asking. The
decisions belong to the user; put each decision to them and wait.

As domain terms become clear, update `CONTEXT.md` inline. Create it lazily if
it does not exist. Keep it as a glossary only: no implementation details, no
spec text, no scratch notes.

Offer an ADR only when the decision is hard to reverse, surprising without
context, and the result of a real trade-off. ADRs live in `docs/adr/` and use
sequential filenames like `0001-short-title.md`.

Do not enact the plan until the user confirms shared understanding.
