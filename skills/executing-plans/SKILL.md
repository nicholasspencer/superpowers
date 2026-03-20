---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load plan, review critically, execute tasks in batches, report for review between batches.

**Core principle:** Batch execution with checkpoints for architect review.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Track tasks and proceed

### Task Tracking

If writing-plans created child beads for each task (check the plan header for `Bead:` and task headings for `[bead-id]`), use those:
- `bd update <child_id> --status=in_progress` when beginning work
- `bd close <child_id>` when complete

If no child beads exist, detect available tracking:
- If `.beads/` exists in the project or `bd` is on PATH → use beads:
  - `bd create -t "Task N: description" -p medium` to create
  - `bd update <id> --status=in_progress` when beginning work
  - `bd close <id>` when complete
- Otherwise → track inline in the plan markdown:
  - `- [ ] Task N: description` → `- [x] Task N: description`

### Step 2: Execute Batch
**Default: First 3 tasks**

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Refactor Tracking (RCA Traceability)

When implementation reveals code that needs refactoring:

1. **Don't refactor inline.** Create a new bead:
   ```bash
   bd create -t "Refactor: <what and why>" --type=task -p 3 --parent=<parent_bead_id>
   bd update <refactor_id> --add-label refactor
   bd update <refactor_id> --notes="Discovered during <parent_bead_id>, Task N. Reason: <why this needs refactoring>"
   ```
2. **Continue current work.** The refactor bead is tracked separately.
3. **If the refactor blocks current work**, note it and stop the batch — surface to architect.

This creates an audit trail: every refactor traces back to the bead where it was discovered, enabling RCA when the workflow produces unexpected results.

To review all refactors born from a piece of work:
```bash
bd children <parent_bead_id>
bd list --label=refactor
```

### Step 3: Report
When batch complete:
- Show what was implemented
- Show verification output
- Say: "Ready for feedback."

### Step 4: Continue
Based on feedback:
- Apply changes if needed
- Execute next batch
- Repeat until complete

### Step 5: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED:** Follow the finishing-a-development-branch skill
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Between batches: just report and wait
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
- **writing-plans** - Creates the plan this skill executes
- **finishing-a-development-branch** - Complete development after all tasks
