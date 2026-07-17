# Agent Skills

A collection of reusable agent skills for code review, planning, implementation, and productivity workflows. Compatible with OpenCode, Claude Code, Codex, Cursor, and other Agent Skills-compatible tools.

## Installation

List available skills:

```bash
npx skills add syunar/agent-skills --list
```

Install interactively:

```bash
npx skills add syunar/agent-skills
```

Install a specific skill:

```bash
npx skills add syunar/agent-skills --skill tdd
```

Install globally for a specific agent:

```bash
npx skills add syunar/agent-skills --skill tdd --agent opencode --global --yes
```

## Claude Code agents

Project custom agents live in `.claude/agents/*.md`.

| Agent | Role |
|-------|------|
| `code-reviewer` | Read-only five-axis review for a change, diff, or pull request |

Ask Claude Code to use the `code-reviewer` subagent, or start a session with
`claude --agent code-reviewer`. The `/review` and `/ship` workflow skills
delegate their review pass to this agent.

Project workflow commands compose the reusable skills below:

| Command | Workflow |
|---------|----------|
| `/spec` | Grill with docs, confirm shared understanding, then write a dated spec |
| `/to-plan` | Turn one ticket and its parent spec into a local executable implementation plan |
| `/build` | Implement incrementally with tests, verification, and review |
| `/review` | Review quality, security, performance, and simplicity without fixes |
| `/fix` | Apply verified fixes with regression coverage and re-verification |
| `/ship` | Run final gates, then confirm commit and external delivery separately |

Pipeline: `/grill-with-docs` → `/to-spec` → `/to-tickets` → `/to-plan <ticket>` → `/implement <plan-path>` → `/code-review`.

## Available skills

### Claude Code agents

Project custom agents live in `.claude/agents/*.md`.

| Agent | Role |
|-------|------|
| `code-reviewer` | Read-only five-axis review for a change, diff, or pull request |

Ask Claude Code to use the `code-reviewer` subagent, or start a session with
`claude --agent code-reviewer`. The `/review` and `/ship` workflow skills
delegate their review pass to this agent.

### Workflow

| Skill | Description |
|-------|-------------|
| **spec** | `/spec` workflow: documented grilling followed by dated spec synthesis |
| **to-plan** | `/to-plan` workflow: executable planning for one ticket |
| **build** | `/build` workflow: incremental implementation with tests and review |
| **review** | `/review` workflow: read-only quality, security, performance, and simplicity review |
| **fix** | `/fix` workflow: verified fixes with regression coverage and re-verification |
| **ship** | `/ship` workflow: final gates and confirmed delivery actions |

### Productivity

| Skill | Description |
|-------|-------------|
| **grill-me** | Interview you relentlessly about a plan or design until shared understanding is reached |
| **grill-with-docs** | Relentless interview that also creates ADRs and glossary as you go |
| **grilling** | The reusable interview loop behind grill-me and grill-with-docs |
| **ponytail** | Forces the laziest solution that actually works — YAGNI, stdlib first, no unrequested abstractions |
| **caveman** | Ultra-compressed communication mode. Cuts token usage ~75% |
| **caveman-commit** | Ultra-compressed Conventional Commits. Short subjects, body only when needed |
| **to-spec** | Turn the current conversation into a spec and publish it to the issue tracker |
| **to-tickets** | Split a spec into blocked tracer-bullet tickets |
| **to-plan** | Turn one ticket and its parent spec into a local executable implementation plan |

### Engineering

| Skill | Description |
|-------|-------------|
| **tdd** | Test-driven development — red-green-refactor cycle with test quality guidance |
| **test-driven-development** | Test-driven development — write failing tests first, prove-it pattern for bugs, test pyramid guidance |
| **incremental-implementation** | Build in thin vertical slices with individual test-verify-commit per increment |
| **codebase-design** | Shared vocabulary for designing deep modules with depth, seams, and leverage |
| **improve-codebase-architecture** | Scan codebase for deepening opportunities, present as HTML report, then grill through each |
| **domain-modeling** | Build and sharpen a project's domain model — glossary and ADRs |
| **implement** | Execute an implementation plan, spec, or ticket using tdd and code-review |
| **code-review** | Two-axis review (standards + spec) using parallel sub-agents |
| **code-review-and-quality** | Multi-axis review across correctness, readability, architecture, security, and performance |
| **scrutinize** | Outsider-perspective end-to-end review of plans, PRs, diffs, and designs |
| **code-simplification** | Simplify code for clarity while preserving exact behavior |
| **security-and-hardening** | Security-first practices — input validation, auth, SSRF, secrets, LLM safety |
| **performance-optimization** | Measure-first optimization for frontend, backend, queries, and Core Web Vitals |
| **explain-diff-html** | Produce a rich, interactive HTML explanation of any code change |
| **design-python-backend-architecture** | Design or review a thin, feature-first Python modular monolith |

## License

MIT
