# Ralph Failure Modes

Ralph loops simplify agent orchestration but are not immune to problems.  Recognising common failure modes allows you to design better prompts, validation and back‑pressure.

## Context rot & compaction loss

Although Ralph discards chat history each iteration, the agent still carries context within a single turn.  Large prompts or long responses can fill the model’s context window, leading to **context rot**—a gradual degradation in quality.  Some runtimes automatically compact context by summarising previous messages.  If critical details are lost during compaction, the agent may forget instructions (e.g., file paths or design constraints) and veer off course.

*Mitigation*: Keep prompts concise.  Move large specifications into files and instruct the agent to read them rather than inlining.  For OpenCode, use compaction hooks to inject important context back into the summary.  For all tools, limit the number of concurrent stories per iteration.

## Infinite loops & runaway iterations

If the sentinel is never produced or validation keeps failing, the harness may loop indefinitely.  This can happen if the agent cannot satisfy the acceptance criteria due to missing context, ambiguous requirements or a bug in the prompt.

*Mitigation*: Set **max_iterations** and **max_failures** thresholds.  If the loop exceeds these, abort or hand off to a human.  Review the prompt and PRD for clarity and completeness.

## Permission & sandbox denials

Agents often request to run commands that exceed their permissions.  In Codex and Claude this triggers approval prompts; in OpenCode it raises a permission error.  If the harness is fully unattended these prompts can stall progress.

*Mitigation*: Define appropriate permission policies (`ask`, `deny`, `allow`) and use `--allowedTools` or `permission.tool` patterns to grant just enough access.  For destructive operations, require interactive approval or run in a disposable container.

## Compounded errors in PRD

If the agent updates the PRD incorrectly (e.g., marking a story as complete when tests fail) or if a merge conflict occurs, the plan can become inconsistent.  Subsequent iterations may pick the wrong tasks.

*Mitigation*: Implement validation gates that verify test results before updating the PRD.  Use Git branches per story to isolate changes.  Have the harness parse the JSON event stream to confirm that a task truly passes before toggling `passes: true`.

## Resource exhaustion

Long loops can consume large amounts of tokens or time.  Without limits on step counts or output sizes the agent may produce verbose reasoning or run commands indefinitely.

*Mitigation*: Configure `maxSteps` in OpenCode, set environment variables to cap output tokens, and tune reasoning modes (e.g., avoid “ultrathink” in Claude unless necessary).  Abort iterations that exceed a wall‑clock time budget.
