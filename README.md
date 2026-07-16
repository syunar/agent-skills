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

## Custom agents

OpenCode workflow comes from `.opencode/agents/*.md`; `opencode.json` sets `default_agent` to `marcus`.

Claude Code equivalents live in `.claude/agents/*.md`. `.claude/settings.json` starts normal project sessions as `marcus`. Use `claude --agent sophia` for a dedicated spec/plan session, or `@agent-<name>` to invoke any specialist.

Both agent sets stay supported.

| File | Mode | Role |
|------|------|------|
| `marcus.md` | `primary` | Orchestrates feature and fix work through subagents |
| `sophia.md` | `primary` | Orchestrates specs and plans |
| `builder.md` | `subagent` | Focused implementation slices with tests |
| `documentation-researcher.md` | `subagent` | Read-only docs, source lookup, current-info research |
| `explorer.md` | `subagent` | Read-only repo discovery |
| `fast-reviewer.md` | `subagent` | Read-only review for small bounded changes |
| `feedback-responder.md` | `subagent` | Addresses bounded PR review feedback |
| `researcher.md` | `subagent` | General read-only research |
| `reviewer.md` | `subagent` | Final holistic review |
| `shipper.md` | `subagent` | Git and GitHub delivery tasks |

No `/spec`, `/plan`, `/build`, `/review`, or `/feedback` slash-command templates exist in repo.

## Available skills

### Productivity

| Skill | Description |
|-------|-------------|
| **grill-me** | Interview you relentlessly about a plan or design until shared understanding is reached |
| **grill-with-docs** | Relentless interview that also creates ADRs and glossary as you go |
| **grilling** | The reusable interview loop behind grill-me and grill-with-docs |
| **ponytail** | Forces the laziest solution that actually works — YAGNI, stdlib first, no unrequested abstractions |
| **caveman** | Ultra-compressed communication mode. Cuts token usage ~75% |
| **caveman-commit** | Ultra-compressed Conventional Commits. Short subjects, body only when needed |
| **to-spec** | Turn the current conversation into a spec and save it as a dated markdown file |

### Engineering

| Skill | Description |
|-------|-------------|
| **writing-plans** | Create bite-sized implementation plans from specs or requirements |
| **tdd** | Test-driven development — red-green-refactor cycle with test quality guidance |
| **test-driven-development** | Test-driven development — write failing tests first, prove-it pattern for bugs, test pyramid guidance |
| **incremental-implementation** | Build in thin vertical slices with individual test-verify-commit per increment |
| **codebase-design** | Shared vocabulary for designing deep modules with depth, seams, and leverage |
| **improve-codebase-architecture** | Scan codebase for deepening opportunities, present as HTML report, then grill through each |
| **domain-modeling** | Build and sharpen a project's domain model — glossary and ADRs |
| **implement** | Implement work from a spec or tickets using tdd and code-review |
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
