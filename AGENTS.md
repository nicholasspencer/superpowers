# AGENTS.md — Superpowers for OpenClaw

This is a fork of [obra/superpowers](https://github.com/obra/superpowers) adapted for [OpenClaw](https://github.com/openclaw/openclaw).

## What This Is

A skill pack that gives OpenClaw agents a structured software development methodology:
brainstorming → planning → TDD → execution → review → verification.

The original superpowers was built for Claude Code's plugin system. This fork adapts the
methodology to work natively with OpenClaw's skill system, subagent spawning, and tooling.

## Architecture

```
skills/                    # OpenClaw-compatible skills (SKILL.md + references)
├── brainstorming/         # Design-before-code workflow
├── writing-plans/         # Bite-sized task breakdown
├── executing-plans/       # Batch execution with checkpoints
├── subagent-driven-development/  # Per-task subagent dispatch
├── test-driven-development/      # Red-green-refactor
├── systematic-debugging/         # Root cause before fixes
├── verification-before-completion/ # Evidence before claims
├── requesting-code-review/       # Pre-merge review dispatch
├── receiving-code-review/        # Handling review feedback
├── dispatching-parallel-agents/  # Concurrent independent tasks
├── using-git-worktrees/          # Isolated workspaces
├── finishing-a-development-branch/ # Merge/PR/discard workflow
├── using-superpowers/            # Meta-skill: how skills trigger
└── writing-skills/               # How to create new skills
agents/                    # Subagent prompt templates
└── code-reviewer.md       # Code review subagent
```

## Key Adaptations from Upstream

### Subagent Dispatch
- **Upstream:** Claude Code `Task` tool spawns subagents
- **Ours:** `sessions_spawn` with `runtime: "acp"` or the `coding-agent` skill

### Task Tracking
- **Upstream:** Claude Code `TodoWrite` (ephemeral in-session tracking)
- **Ours:** Detect environment:
  - If `.beads/` exists or `bd` is on PATH → use beads (`bd create`, `bd start`, `bd close`)
  - Otherwise → track progress inline in the plan markdown (check off items)

### Skill Invocation
- **Upstream:** Claude Code `Skill` tool loads skill content on demand
- **Ours:** OpenClaw loads skills via description matching in `<available_skills>`
  - Skills trigger automatically when descriptions match the task
  - Cross-skill references use skill names, not `superpowers:` prefix

### Session Hooks
- **Upstream:** `hooks/session-start` injects `using-superpowers` into every session
- **Ours:** `using-superpowers` skill triggers via OpenClaw's normal skill matching

### Platform Scaffolding (Removed)
We've removed: `.claude-plugin/`, `.cursor-plugin/`, `.codex/`, `.opencode/`,
`hooks/`, `commands/`, `lib/skills-core.js` — these are Claude Code/Cursor/Codex
specific and replaced by OpenClaw's native skill system.

## Conventions

- **Conventional commits** — `feat:`, `fix:`, `docs:`, `refactor:`
- **Squash PRs** — branch history doesn't matter, final message does
- **Keep skills lean** — methodology in SKILL.md, details in reference files
- **Test adaptations** — verify skills trigger correctly and subagent dispatch works

## Upstream Sync (Fork Rebase)

This is a fork of `obra/superpowers`. Periodically sync with upstream to get
methodology improvements while preserving our OpenClaw adaptations.

### Quick Check
```bash
git fetch upstream
git rev-list --count HEAD..upstream/main
# If > 0, time to rebase
```

### Rebase Process
```bash
# Safety net
git tag pre-rebase-$(date +%Y%m%d)

# Rebase
git fetch upstream
git rebase upstream/main

# Force-push to fork (never upstream!)
git push origin main --force-with-lease
```

### Conflict Resolution Strategy

| File type | Strategy |
|-----------|----------|
| `skills/*/SKILL.md` | **Merge carefully** — upstream methodology + our OpenClaw adaptations |
| Skill reference files (`*.md` in skill dirs) | **Upstream wins** unless we've customized |
| `agents/` | **Merge** — upstream prompt improvements + our dispatch adaptations |
| `AGENTS.md`, `README.md` | **Ours wins** — these are fork-specific |
| `tests/` | **Case-by-case** — upstream test improvements are valuable |
| Platform files (`.claude-plugin/`, etc.) | **Drop** — we've removed these |
| `lib/`, `hooks/`, `commands/` | **Drop** — replaced by OpenClaw native |

### After Rebase
1. Check if upstream added new skills → adapt for OpenClaw
2. Check if upstream changed skill formats → verify our adaptations still apply
3. Run through skill descriptions to ensure triggering still works
4. Commit any new adaptations

## Installation

Install as OpenClaw skills (symlink or copy to `~/.chad/skills/` or project `.openclaw/skills/`):

```bash
# Symlink all skills
ln -s ~/development/com.nicospencer/superpowers/skills ~/.chad/skills/superpowers

# Or install individual skills
ln -s ~/development/com.nicospencer/superpowers/skills/brainstorming ~/.chad/skills/brainstorming
```
