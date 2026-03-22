# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent.

**Key:** Implementers run as one-shot sessions (`mode: "run"`). They build, self-review, commit, set `review:pending`, and exit. They do NOT close the bead — the controller closes it after external review passes.

```
sessions_spawn (runtime: "acp", mode: "run"):
  description: "Implement Task N: [task name]"
  cwd: "[working directory]"
  prompt: |
    You are implementing Task N: [task name]

    ## Task Description

    [FULL TEXT of task from plan - paste it here, don't make subagent read file]

    ## Context

    [Scene-setting: where this fits, dependencies, architectural context]

    ## Before You Begin

    If you have questions about:
    - The requirements or acceptance criteria
    - The approach or implementation strategy
    - Dependencies or assumptions
    - Anything unclear in the task description

    **Ask them now.** Raise any concerns before starting work.

    ## Bead Tracking

    Your bead ID: [BEAD_ID]

    At the start of work, claim it:
    ```
    bd update [BEAD_ID] --status=in_progress
    ```

    After you finish and self-review, mark it ready for external review:
    ```
    bd set-state [BEAD_ID] review=pending
    ```

    **Do NOT close the bead.** The controller will close it after
    an external reviewer verifies your work.

    ## Your Job

    Once you're clear on requirements:
    1. Claim your bead (`bd update [BEAD_ID] --status=in_progress`)
    2. Implement exactly what the task specifies
    3. Write tests (following TDD if task says to)
    4. Verify implementation works
    5. Commit your work (conventional commits)
    6. Self-review (see below)
    7. Set review state: `bd set-state [BEAD_ID] review=pending`
    8. Report back with "READY FOR REVIEW"

    Work from: [directory]

    **While you work:** If you encounter something unexpected or unclear, **ask questions**.
    It's always OK to pause and clarify. Don't guess or make assumptions.

    ## Before Reporting Back: Self-Review

    Review your work with fresh eyes. Ask yourself:

    **Completeness:**
    - Did I fully implement everything in the spec?
    - Did I miss any requirements?
    - Are there edge cases I didn't handle?

    **Quality:**
    - Is this my best work?
    - Are names clear and accurate (match what things do, not how they work)?
    - Is the code clean and maintainable?

    **Discipline:**
    - Did I avoid overbuilding (YAGNI)?
    - Did I only build what was requested?
    - Did I follow existing patterns in the codebase?

    **Testing:**
    - Do tests actually verify behavior (not just mock behavior)?
    - Did I follow TDD if required?
    - Are tests comprehensive?

    If you find issues during self-review, fix them now before reporting.

    ## Report Format

    When done, report:
    - What you implemented
    - What you tested and test results
    - Files changed
    - Commit SHA
    - Self-review findings (if any)
    - Any issues or concerns
    - **End with: READY FOR REVIEW**
```
