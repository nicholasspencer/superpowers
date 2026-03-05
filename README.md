# Superpowers for OpenClaw

A structured software development methodology skill pack for [OpenClaw](https://github.com/openclaw/openclaw), forked from [obra/superpowers](https://github.com/obra/superpowers).

## What This Is

A set of composable skills that give OpenClaw agents a disciplined development workflow:
brainstorming → planning → TDD → execution → review → verification.

Skills trigger automatically via OpenClaw's description matching — no manual invocation needed.

## Installation

```bash
ln -s /path/to/superpowers/skills ~/.openclaw/skills/superpowers
```

Skills can also be placed in a project's `.openclaw/skills/` directory.

## Available Skills

Skills marked with **\*** have been adapted for OpenClaw.

| Skill | Description |
|-------|-------------|
| **brainstorming\*** | Design-before-code workflow with collaborative refinement |
| **writing-plans\*** | Bite-sized implementation plans with TDD steps |
| **executing-plans\*** | Batch execution with review checkpoints |
| **subagent-driven-development\*** | Per-task subagent dispatch with two-stage review |
| **test-driven-development** | Red-green-refactor cycle enforcement |
| **systematic-debugging\*** | Four-phase root cause investigation |
| **verification-before-completion** | Evidence before claims, always |
| **requesting-code-review\*** | Pre-merge review dispatch |
| **receiving-code-review\*** | Handling review feedback with technical rigor |
| **dispatching-parallel-agents\*** | Concurrent independent task execution |
| **using-git-worktrees\*** | Isolated workspace creation and management |
| **finishing-a-development-branch** | Merge/PR/discard workflow |
| **writing-skills\*** | How to create and test new skills |
| **using-superpowers\*** | Meta-skill: how skills trigger and compose |

## Documentation

See [AGENTS.md](AGENTS.md) for architecture, conventions, and upstream sync process.

## Credit

This is a fork of [obra/superpowers](https://github.com/obra/superpowers) by Jesse Vincent.
The core methodology is upstream — this fork adapts the tooling integration for OpenClaw's
native skill system, `sessions_spawn` subagent dispatch, and beads task tracking.

If superpowers has helped you, consider [sponsoring Jesse's work](https://github.com/sponsors/obra).

## License

MIT License — see [LICENSE](LICENSE) for details.
