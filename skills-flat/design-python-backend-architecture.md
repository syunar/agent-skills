---
name: design-python-backend-architecture
description: Design or review a Python backend using a thin, feature-first modular monolith. Use for APIs, WebSockets, webhooks, background jobs, queues, events, schedulers, databases, caches, storage, search, integrations, CPU/GPU workers, observability, security, deployment, and testing.
---

# Python Backend Architecture Designer

Design or review Python backends that are simple to implement and operate now,
modular enough to evolve safely, explicit about ownership and runtime
boundaries, recoverable under retries and restarts, and testable without
excessive mocking.

The default is a **thin, feature-first modular monolith**:

```text
single Python codebase
├── API process
├── worker process
├── scheduler process
└── migration process
```

Multiple processes do not automatically mean microservices. Keep one logical
application unless independent ownership, deployment, scaling, security, or
fault-isolation requirements clearly justify separation.

Do not generate a complete implementation unless the user explicitly asks for
code after the architecture is agreed.

## Instruction Precedence

Use this order when recommendations conflict:

1. explicit user requirements;
2. existing-codebase and technology constraints;
3. measured workload, reliability, security, and operational requirements;
4. this skill's defaults.

Do not replace a user's chosen framework, database, broker, or deployment
platform merely because another option is the default here.

## Operating Modes

Choose the smallest useful mode. When uncertain, use standard mode.

### Quick decision

For a narrow question such as queue vs direct call, repository vs direct SQL,
or sync vs async, output:

1. verdict;
2. reasoning;
3. smallest implementation;
4. trigger to reconsider.

### New-project standard

Output architecture verdict, assumptions, system summary, module map, runtime
topology, concrete initial tree, applicable workflows, data and reliability
design, security, observability, testing, implementation order, and an
overengineering check.

### Full production design

Use when several runtimes, durable workflows, significant tenancy, compliance,
storage, scale, CPU, or GPU concerns are central. Include the full output
contract below, omitting irrelevant sections.

### Existing-project review

Output review verdict, observed architecture, severity-ordered findings with
evidence, target architecture, incremental migration plan, and validation.
Do not recommend a rewrite unless the current design blocks safe incremental
evolution.

Separate evidence from inference:

```text
Observed: directly supported by inspected code or configuration.
Inferred: likely, but not fully verified.
Unknown: requires runtime, deployment, product, or operational information.
```

## Maturity Levels

Describe the design as one of:

- **Prototype**: optimized for learning and rapid change, limited operational guarantees.
- **Production baseline**: validated configuration, migrations, bounded retries, durable work where required, essential observability, safe deployment, backups, and recovery.
- **Scale-sensitive**: explicit backpressure, workload isolation, capacity planning, and independent process scaling where justified.

Do not confuse maturity with runtime topology.

## Core Principles

1. Organize code by business capability, not global technical layers.
2. Keep modules flat and concrete at first.
3. Keep routes, queue handlers, webhook handlers, and scheduler callbacks thin.
4. Put business workflows in the owning module.
5. Let modules own their data, rules, queries, entrypoints, jobs, and business-specific integrations.
6. Expose a small deliberate public surface from each module.
7. Keep cross-module dependencies explicit, one-directional, and acyclic.
8. Prefer direct function calls before internal events.
9. Prefer normal database transactions before distributed workflow patterns.
10. Use synchronous execution when work is fast and the caller needs the result.
11. Use durable processing when work must survive restarts, retries, load bursts, or separate resource needs.
12. Add infrastructure only when a real requirement justifies it.
13. Design for future extraction without pre-building microservices.
14. Do not hide business concepts in `utils.py`, `helpers.py`, `common.py`, or `manager.py`.

## Required Discovery

Determine as many of these as possible. Ask only architecture-critical
questions. If facts are missing, state conservative assumptions and explain
which decisions they affect.

### Product and workload

- product, actors, and critical workflows;
- immediate versus deferred operations;
- latency, traffic, data volume, and job volume;
- I/O-bound, CPU-bound, GPU-bound, or mixed workloads;
- restart durability and workflow duration.

### Interfaces

- HTTP, GraphQL, WebSocket, SSE, CLI, webhook, consumer, or scheduler;
- external systems calling the backend and systems it calls.

### Data and consistency

- database, object storage, search, vector search, and cache;
- cross-module transactions, audit, retention, ordering, deduplication;
- tenancy and any claimed exactly-once requirement.

### Operations

- deployment target and instance count;
- existing queues, brokers, monitoring, security, compliance, team size, and change rate.

## Design Procedure

### 1. Summarize and select maturity

Describe the product, actors, workflows, workload types, and reliability
expectations before discussing frameworks. Select Prototype, Production
baseline, or Scale-sensitive and explain why.

### 2. Identify business modules

Use names such as `accounts`, `projects`, `billing`, `assets`, `processing`,
`inference`, `notifications`, and `publishing`. Avoid global technical
modules such as `services`, `controllers`, `repositories`, `models`, and
`helpers`.

For every module define responsibility, owned data, public operations,
incoming entrypoints, outgoing dependencies, and published or consumed jobs
and events. Merge modules that are too small. Split only when ownership,
rules, data, security, scaling, or change cadence differ meaningfully.

### 3. Define public boundaries and dependency direction

Use the package as the stable public boundary:

```python
from project_name.modules.users import create_user, get_user
```

```python
# modules/users/__init__.py
from .service import create_user, get_user

__all__ = ["create_user", "get_user"]
```

Other modules must not import another module's ORM models, repositories,
private workflows, providers, transport schemas, or queue handlers. Use
`public.py` only when `__init__.py` becomes too large.

Keep this direction:

```text
transport entrypoint → owning module workflow → model/repository/provider → shared infrastructure
modules → shared
shared ✗→ modules
```

When a cycle appears, reconsider ownership, move orchestration to the owning
module, extract only a genuinely independent capability, or use an event only
when eventual consistency is acceptable.

### 4. Assign workflow and transaction ownership

The module representing the business action owns orchestration. The outermost
workflow owns the transaction; nested operations must not independently commit
while participating in the caller's transaction.

```text
publishing.publish_video()
├── loads publishing state
├── calls assets.require_ready_asset()
├── calls accounts.require_publish_permission()
├── updates publishing state
└── commits once
```

Use a neutral top-level workflow only when no business module clearly owns the
action. Do not add a generic orchestration layer for every cross-module call.

### 5. Classify every operation

- **Inline synchronous**: fast, immediate result, no durability requirement.
- **In-request async I/O**: the request still waits and concurrent I/O materially helps.
- **Best-effort in-process task**: telemetry or similarly non-critical work only.
- **Durable background job**: slow, retryable, bursty, resource-isolated, or restart-sensitive work.
- **Scheduled job**: usually scheduler dispatches a durable job and a worker executes it.
- **Long-running workflow**: persisted state machine when steps branch, wait, resume, cancel, or expose progress.

Never use `asyncio.create_task()` or framework background tasks for work that
must survive restarts or retry reliably. Recommend a workflow engine only when
timers, signals, compensation, and recovery outgrow application code.

### 6. Select minimum runtime topology

```text
Level 1: API + database
Level 2: API + database + database-backed jobs + worker
Level 3: API + database + broker + workers + optional scheduler
Level 4: API + database + broker + workers + scheduler + outbox/inbox
```

Recommend independently deployable services only for concrete independent
ownership, deployment, scaling, security, data isolation, or fault-isolation
needs.

### 7. Define data, consistency, overload, and failure behavior

For each write workflow state owner, tables, transaction start/end, atomic
changes, messages, and concurrency controls. Use normal database transactions
when all state is in one database. Use a transactional outbox only when a
committed change must reliably produce a message. Use an inbox or processed
message record when duplicates can cause harm.

Define behavior for request limits, exhausted pools, queue limits, degraded
providers, unavailable CPU/GPU capacity, and tenant quotas. Consider bounded
prefetch, admission control, load shedding, circuit breakers, queue-depth
alerts, and graceful degradation.

For each background operation define timeout, retryable/permanent failures,
maximum attempts, backoff and jitter, idempotency key, dead-letter handling,
replay, stuck-job recovery, and observability fields. Assume at-least-once
delivery. Acknowledge only after durable completion. Exactly one layer should
own delayed retries.

### 8. Define security and observability

Transport authenticates callers; business workflows enforce authorization and
tenant scope so workers, schedulers, CLIs, and webhooks are safe too. Consider
secret management, input/upload/webhook validation, rate limits, quotas,
audit logs, encryption, least privilege, and dependency/container security.

Use structured logs and traces with bounded metric labels. Useful fields are
`request_id`, `correlation_id`, `user_id`, `tenant_id`, `module`, `operation`,
`job_id`, `event_id`, `attempt`, `duration_ms`, `result`, and `error_category`.
Track HTTP latency/errors, queue depth and oldest-job age, job duration and
retries, database pools, external API failures, cache hit rate, CPU/GPU use,
and business success metrics. Propagate correlation IDs through jobs/events.

### 9. Design tests and tree

Use global tests organized by level and mirrored by module ownership:

```text
tests/
├── unit/
├── integration/
└── end_to_end/
```

Unit-test rules, state transitions, validation, retry classification, parsing,
and simple fakes. Integration-test real database repositories, migrations,
transactions, API routes, serialization, duplicate delivery, idempotency,
module interactions, adapters, and tenant scoping. Use end-to-end tests
sparingly for critical flows such as API → database → queue → worker.
Do not heavily mock ORM sessions or query builders.

Always show concrete `.py` files, first a minimal justified tree, then
conditional add-ons only for credible near-term needs.

## Module Template

Start with only needed files:

```text
modules/projects/
├── __init__.py
├── api.py
├── models.py
├── schemas.py
├── service.py
├── repository.py
├── worker.py
├── scheduler.py
└── webhook.py
```

Every file except `__init__.py` is optional.

| File | Responsibility |
|---|---|
| `__init__.py` | Empty marker or small public API |
| `api.py` | Validation, auth context, workflow invocation, response mapping |
| `service.py` | Workflows, transactions, state changes, module calls, publication |
| `models.py` | ORM models, enums, close-to-model invariants and transitions |
| `schemas.py` | API, job, webhook, command, and event contracts |
| `repository.py` | Reused, complex, lock-sensitive, or noisy persistence |
| `worker.py` | Thin message validation, invocation, retry classification |
| `scheduler.py` | Thin schedule registration and dispatch |
| `webhook.py` | Verification, deduplication, receipt persistence, dispatch |

Prefer plain functions in `service.py`; use classes only for stateful
dependencies or lifecycle behavior. Keep business-specific providers in the
owning module. Do not automatically introduce `domain/`, `application/`,
`ports/`, or `adapters/` layers.

## Runtime and Shared-Code Rules

| File | Responsibility |
|---|---|
| `config.py` | Validate settings; no connections or startup |
| `bootstrap.py` | Construct infrastructure and own resource lifecycle |
| `api.py` | Create app, mount routes, middleware, errors, health, shutdown |
| `worker.py` | Start worker runtime and register handlers |
| `scheduler.py` | Start scheduler and register schedules |
| `main.py` | Optional executable launcher |

Keep infrastructure flat (`database.py`, `queue.py`, `storage.py`, `cache.py`,
`http.py`, `observability.py`) until it becomes broad. Move code to `shared/`
only when it is domain-neutral, used by at least two meaningful modules,
stable, and imports no business module. Do not use shared files for business
rules.

## Special Decision Rules

### Sync and async

Choose sync for CPU-bound work, modest concurrency, synchronous dependencies,
or operational simplicity. Choose async for high concurrent I/O or long-lived
connections with consistently async dependencies. Warn against async routes
that call blocking ORM/HTTP clients or CPU/GPU work. Async does not accelerate
CPU or GPU work; use dedicated workers or pools.

### Commands, events, and queues

A command requests one action; an event states that something happened. Use
direct calls when an immediate result or same transaction is needed. Use events
for independent reactions where eventual consistency is acceptable.

For every queue define schema, producer, consumer, duration, concurrency,
resource class, timeout, acknowledgement timing, attempts, backoff, dead-letter
destination, idempotency, ordering, and replay. Separate `default`,
`cpu_heavy`, `gpu`, and `notifications` queues when resources differ. For AI
or media work also define memory/GPU limits, model loading, warmup, cancellation,
progress, batching, and shutdown.

### Webhooks, realtime, schedules, and storage

Webhook flow:

```text
verify signature → validate envelope → deduplicate → persist receipt → enqueue → return quickly
```

Define replay protection, provider event ID, raw-payload retention, unknown
events, retries, and reconciliation. For WebSockets/SSE define auth, topics,
reconnect, missed messages, backpressure, connection limits, and multi-instance
fan-out. Use in-memory fan-out for one API process; add pub/sub only when
multiple instances require it.

For schedules, define timezone/UTC normalization, status, attempts, lease or
lock, idempotency, cancellation, and duplicate-dispatch prevention. For object
storage define ownership, metadata, checksums, MIME/size validation, scanning,
cleanup, retention, access control, multipart uploads, and processing state.

### Database, cache, and search

Define table ownership even when cross-module foreign keys exist. Use
optimistic concurrency for uncommon conflicts, pessimistic locks for claims or
reservations, unique constraints for invariants, and leases for recoverable
long-running claims. For modest workloads, PostgreSQL with
`FOR UPDATE SKIP LOCKED` may be simpler than a broker; state the tradeoff.

Default to no distributed cache. Add one only after defining the bottleneck,
staleness, invalidation, fallback, and failure behavior. Prefer:

```text
database indexes → database full-text → database vector extension → search engine
```

## Deployment and Graceful Shutdown

APIs stop accepting requests, finish in-flight work by a deadline, and close
connections. Workers stop consuming, finish or safely abandon active jobs,
release leases, and acknowledge only completed jobs. Schedulers stop dispatching,
release locks/leadership, and avoid duplicate dispatch on restart.

## Existing-Project Review

Review for business logic in transport handlers; global technical layers;
unclear ownership; private cross-module access; cycles; hidden nested commits;
unsafe in-process tasks; unbounded or multiplicative retries; duplicate
external side effects; weak authorization or tenant scoping; dumping-ground
utilities; unnecessary abstractions; missing migration, shutdown, or recovery;
and framework-layer tests that miss behavior ownership.

Each finding must include severity (`blocking`, `high`, `medium`, or `low`),
evidence, problem, impact, smallest safe recommendation, and validation.

## Output Contracts

### New-project standard

1. **Architecture verdict**: style, maturity, fit, and intentionally excluded components.
2. **Assumptions**
3. **System summary**
4. **Module map**

   | Module | Responsibility | Owns | Entrypoints | Depends on |
   |---|---|---|---|---|

5. **Runtime topology**
6. **Concrete initial tree** and conditional add-ons
7. **Core workflows**
8. **Data and transaction design**
9. **Reliability, security, observability, and testing**
10. **Implementation order**
11. **Overengineering check**

### Full production design

Include the standard sections plus conditional growth tree, file responsibility
map, dependency/public-boundary rules, reliability/overload design, tenant
isolation, operational metrics, deployment, and graceful shutdown.

### Existing-project review

1. **Review verdict**
2. **Observed architecture**
3. **Findings by severity with evidence**
4. **Target architecture**
5. **Incremental migration plan**
6. **Validation**

### Quick decision

1. **Verdict**
2. **Why**
3. **Recommended implementation**
4. **Reconsider when**

## Architecture Decision Matrix

| Requirement | Default | Upgrade when |
|---|---|---|
| Fast immediate operation | Direct service call | It becomes slow or unreliable |
| Durable background work | Database-backed jobs/simple queue | Throughput, routing, latency, or isolation needs a broker |
| One side effect | Direct orchestration | Subscribers need independent ownership |
| Reliable DB-to-message publication | Transactional outbox | Message loss is unacceptable |
| Fixed recurring task | Scheduler dispatches module workflow | Multiple instances need coordination |
| User-defined schedules | Database schedule records | Scale needs specialized scheduling |
| Cache | None | Measurement or hard latency target justifies it |
| Search | Primary database | Required behavior exceeds database capability |
| Real-time fan-out | In-memory manager | Multiple API instances need pub/sub |
| Scaling | Scale process type | A module needs independent deployment |
| Microservices | Avoid | Ownership/deployment/scaling/security/isolation demands them |

## Final Quality Check

Before finalizing, verify that the mode matches the request; modules are named
for business capabilities; every generated file has a current responsibility;
entrypoints are thin; workflows and tables have owners; public APIs are small;
imports are acyclic and do not reach private internals; the outermost workflow
owns transactions; durable work is idempotent; retries are bounded and owned
by one layer; ambiguous external outcomes are reconciled; overload, dead-letter,
replay, and stuck-job behavior are defined where needed; async and CPU/GPU
choices are justified; auth and tenant scope are enforced below transport;
metric labels are bounded; tests mirror module ownership; shared code is
domain-neutral; the initial tree excludes future-only infrastructure; and the
design is incremental and explicitly states what is excluded.

Prefer the smallest architecture safe under real failure modes. A good result
may be an API, PostgreSQL, three business modules, one database-backed worker,
and mirrored tests. It does not need microservices, Kafka, CQRS, event sourcing,
a workflow engine, a distributed cache, or five abstraction layers.
