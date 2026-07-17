---
name: supervisor
description: Shared library for supervisor-dependent skills. Not a standalone skill — required by to-plan-with-supervisor and code-review-with-supervisor.
disable-model-invocation: true
---

# Supervisor

Shared library for supervisor-dependent skills. This skill must be installed alongside `to-plan-with-supervisor` and `code-review-with-supervisor`.

## Dependencies

- `skills/supervisor/scripts/lib/config.sh` — supervisor configuration bootstrap, sourced by both supervisor-dependent helpers.
