# Testing Superpowers Skills

Integration tests for verifying OpenClaw skill behavior using real LLM sessions.

## Philosophy

We test *behavior*, not *content*. No grepping SKILL.md files for keywords — every test
spawns a real OpenClaw session and verifies the agent actually followed the methodology.

This means tests burn real tokens. Design accordingly.

## Test Structure

```
tests/
├── run-tests.sh              # Test runner (--test, --verbose, --dry-run)
├── test-helpers.sh            # Shared utilities (spawn, assert, cleanup)
├── test-skill-triggering.sh   # Right skill fires for the right task
├── test-sdd-workflow.sh       # Subagent-driven-development end-to-end
├── test-beads-detection.sh    # Beads vs inline tracking detection
├── test-brainstorm-gate.sh    # Brainstorming enforces design-before-code
└── fixtures/                  # Toy projects for integration tests
    ├── node-hello/            # Minimal Node.js project
    └── plans/                 # Sample implementation plans
```

## Running Tests

### Run all tests:
```bash
./tests/run-tests.sh
```

### Run a specific test:
```bash
./tests/run-tests.sh --test test-skill-triggering.sh
```

### Dry run (show what would execute, no tokens burned):
```bash
./tests/run-tests.sh --dry-run
```

### Verbose output:
```bash
./tests/run-tests.sh --verbose
```

## How Tests Work

Each test follows the same pattern:

1. **Setup** — Create a temporary project directory with fixtures
2. **Spawn** — `sessions_spawn` a subagent with a task prompt (`mode: "run"`)
3. **Wait** — Subagent completes the task
4. **Inspect** — `sessions_history` to read the session transcript
5. **Assert** — Verify expected behaviors occurred
6. **Cleanup** — Remove temp directories

### Example: Testing Skill Triggering

```bash
# Spawn with a prompt that should trigger systematic-debugging
result=$(openclaw session spawn \
  --task "Debug why this test is flaky. The test passes alone but fails in CI." \
  --mode run \
  --cwd "$FIXTURE_DIR")

# Check session history for evidence the skill was loaded
history=$(openclaw session history --key "$session_key")

# Assert: agent read the systematic-debugging SKILL.md
assert_contains "$history" "systematic-debugging" "Correct skill triggered"

# Assert: agent followed 4-phase investigation (not jumped to a fix)
assert_contains "$history" "reproduce" "Phase 1: Reproduce"
assert_not_contains "$history" "try changing\|quick fix" "Didn't skip to fix"
```

## What We Test

### Skill Triggering
Verifies OpenClaw's description matching selects the right skill for a given task.

| Prompt pattern | Expected skill |
|---|---|
| "Debug why X fails" | systematic-debugging |
| "Build a feature that..." | brainstorming → writing-plans |
| "Execute this plan" | executing-plans or subagent-driven-development |
| "Review this code" | requesting-code-review |

### Subagent-Driven Development (SDD)
Full workflow test on a toy Node.js project:
- Creates a 2-task implementation plan
- Verifies subagents are spawned via `sessions_spawn` (not hallucinated tools)
- Verifies spec compliance review happens before code quality review
- Verifies implementation files exist and tests pass
- Verifies git commits follow the workflow

### Beads Detection
- With `.beads/` in project → skill uses `bd create`, `bd start`, `bd close`
- Without `.beads/` → skill tracks progress inline in the plan markdown

### Brainstorm Gate
- Given a "build X" prompt with no existing plan → agent brainstorms first
- Agent does NOT jump straight to coding

## Cost Control

Integration tests burn real tokens. Mitigations:

- **Target specific tests** — don't run the full suite when iterating
- **`--dry-run`** — verify setup without spawning sessions
- **Toy projects** — minimal fixtures (2-task plans, hello-world code)
- **Token tracking** — each test reports estimated cost on completion
- **Don't run in CI by default** — manual trigger or scheduled (weekly)

## Adding New Tests

1. Create `tests/test-<name>.sh`
2. Source `test-helpers.sh` for utilities
3. Use `spawn_session`, `wait_for_completion`, `get_history`, and `assert_*` helpers
4. Add fixtures to `tests/fixtures/` if needed
5. Register in `run-tests.sh`

## Upstream Context

This test suite replaces the upstream `obra/superpowers` test harness, which was built
around Claude Code CLI (`claude -p` headless mode). The upstream tests verified skill
behavior by invoking Claude Code sessions and parsing `.jsonl` transcripts.

Our approach uses OpenClaw's `sessions_spawn` and `sessions_history` instead, making
tests native to the platform the skills actually run on.

The upstream `analyze-token-usage.py` concept (per-subagent cost breakdown) is worth
preserving — adapt for OpenClaw's session metadata format when available.
