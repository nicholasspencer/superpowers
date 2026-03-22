# Fix Implementer Subagent Prompt Template

Use this template when dispatching a fix implementer after external review finds issues.

**Key:** Fix implementers run as one-shot sessions (`mode: "run"`). They address specific review findings, commit fixes, set `review:pending`, and exit. The bead stays `in_progress` — the controller re-runs the reviewer after.

```
sessions_spawn (runtime: "acp", mode: "run"):
  description: "Fix review findings for Task N: [task name]"
  cwd: "[working directory]"
  prompt: |
    You are fixing review findings for Task N: [task name]

    ## Original Task Description

    [FULL TEXT of task from plan]

    ## Context

    [Scene-setting: where this fits, dependencies, architectural context]

    ## Review Findings to Address

    The following issues were found by an external reviewer:

    [PASTE REVIEWER FINDINGS HERE — include file:line references if available]

    ## Previous Implementation

    The implementation is already committed. Key files:
    [List main files the implementer created/modified]

    ## Bead Tracking

    Your bead ID: [BEAD_ID] (already claimed, status: in_progress)

    After you fix the issues and verify:
    ```
    bd set-state [BEAD_ID] review=pending
    ```

    **Do NOT close the bead.** The controller will re-run the
    external reviewer and close it if the fixes pass.

    ## Your Job

    1. Read the existing implementation
    2. Address each review finding specifically
    3. Run tests to confirm nothing broke
    4. Commit your fixes (conventional commits)
    5. Set review state: `bd set-state [BEAD_ID] review=pending`
    6. Report back with "READY FOR RE-REVIEW"

    Work from: [directory]

    ## Important

    - Fix the specific issues identified — don't refactor unrelated code
    - If a finding seems wrong, explain why in your report (don't silently ignore it)
    - Run the full test suite, not just the tests you think are affected
    - Each fix should be a focused commit

    ## Report Format

    When done, report:
    - What you fixed (map each finding to what you changed)
    - Test results after fixes
    - Commit SHA(s)
    - Any findings you disagree with and why
    - **End with: READY FOR RE-REVIEW**
```
