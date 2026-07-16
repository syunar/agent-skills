# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository model

This repository distributes reusable Agent Skills, not an application.

- `skills/<name>/SKILL.md` is the source of truth for each skill.
- `skills-flat/<name>.md` is generated distribution output for `npx skills add` consumers.
- `README.md` is the public skill catalog and installation guide.
- Workflow skills (`spec`, `plan`, `build`, `review`, `fix`, `ship`) compose lower-level skills by name.
- `.claude/agents/` contains project-local Claude Code subagents. Agent files are not part of `skills-flat/` generation.
- Some source skills have `references/` directories. The sync script copies only `SKILL.md`; references are not included in `skills-flat/`.

Never edit `skills-flat/` directly. Change `skills/<name>/SKILL.md`, then regenerate the flat tree.

## Commands

Regenerate all flat skill files:

```bash
make sync
# equivalent: ./sync-skills.sh
```

Check generated files and whitespace before committing:

```bash
make sync
git diff --check
git status --short
```

Verify one source/flat pair while editing a single skill:

```bash
cmp skills/<name>/SKILL.md skills-flat/<name>.md
```

No dependency installation, compile step, linter, or automated test suite exists. `make sync` plus source/flat comparison is the repository's executable validation.

## Skill authoring contract

Each `SKILL.md` starts with YAML frontmatter containing `name` and `description`. Keep directory name, frontmatter `name`, and generated flat filename aligned. Description must state when the skill applies because agents use it for skill selection.

Skill bodies may compose sibling skills by bare skill name. Keep workflow boundaries explicit, especially whether a skill may modify files, commit, push, or open a pull request.

After adding, deleting, or renaming a skill:

1. Update `skills/`.
2. Run `make sync`; it replaces the entire `skills-flat/` directory.
3. Update the catalog in `README.md`.
4. Confirm `git status --short` shows matching source and flat changes.

Do not place manually maintained files in `skills-flat/`; regeneration deletes them.

## Custom agents

Keep project agent definitions under `.claude/agents/<name>.md`. Use matching `name` frontmatter and grant only tools required by the role. Read-only reviewers must not receive edit or write tools.

Global installation is separate from repository generation. When requested, copy an agent definition to `~/.claude/agents/` and verify the project and global files match; never sync unrelated global settings or runtime state.
