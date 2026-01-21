# Stop Conditions and Budgets (Claude Code)

Claude Code’s headless mode (`claude -p`) does **not** have a built‑in step limit or cost control mechanism.  Unlike OpenCode (which exposes `maxSteps`) and Codex (which has approval policies and sandbox options), Claude delegates all iteration management and budgeting to the orchestrator.  A Ralph loop therefore must enforce its own limits.

## Recommended stop conditions

* **Sentinel marker.** Include a sentinel such as `<promise>COMPLETE</promise>` in your prompts and instruct the agent to emit it when the current task is finished.  The harness should parse the final message of the JSON stream and exit the iteration once the sentinel appears.
* **Max iterations.** Define an outer loop counter (`max_iterations`) to avoid infinite looping.  If the sentinel is never produced after the allotted number of iterations, mark the job as **ESCALATED** and switch models or ask for human intervention.
* **Max failures.** Track consecutive validation failures (e.g. failing tests, lint errors or repeated permission prompts).  When the number of failures exceeds a threshold, treat the run as stuck and trigger escalation.
* **Time budgets.** Monitor wall‑clock time per iteration and overall.  If a single iteration exceeds a timeout (e.g. 10 minutes) or the job exceeds a time budget, abort or retry.
* **Token budgets.** Claude’s `stream-json` output includes metadata about usage in each event.  Sum these usage numbers to estimate token consumption and stop when a budget is exhausted.  This requires post‑processing since the CLI does not enforce token caps itself.

## Budgeting strategies

* **Think modes.** Claude supports phrases like “think,” “think hard,” “think harder” and “ultrathink” in prompts to allocate more reasoning time to the model【135116144821332†L234-L239】.  Each step consumes more tokens; use these sparingly and consider lowering the max iteration count when using higher think modes.
* **Model selection.** Higher‑end Claude models (e.g. Opus) have larger context windows but cost more.  For routine tasks start with Sonnet or Haiku; reserve Opus for escalations.
* **Allowed tools.** Restrict tools via `--allowedTools` (e.g. `Read,Edit,Bash`)【649120918286103†L161-L173】.  Limiting tools keeps the agent from performing expensive operations (such as external network calls) and reduces risk of runaway loops.

## Harness enforcement

Because Claude does not enforce budgets, the Ralph harness should:

1. **Track iteration count and failures** in memory or in a job state file.
2. **Parse JSON events** from `stream-json` to detect when tests fail or commands exit non‑zero.  Treat these as validation failures.
3. **Abort on repeated permission prompts.** Multiple `PermissionRequest` events with the same resource indicate that the agent is stuck behind a denied tool call.  Stop the run or adjust allowed tools.
4. **Persist progress** after each iteration.  An append‑only `PROGRESS.md` and session artifacts allow the harness to resume a job if a crash occurs or budgets are exceeded.
5. **Escalate** to a more capable model or human review when budgets are exhausted.  Use the normalized adapter interface’s `exit_code` and error codes to decide when to switch.

These guidelines ensure that a Claude‑based Ralph loop remains predictable and cost‑effective despite the absence of native stop controls.