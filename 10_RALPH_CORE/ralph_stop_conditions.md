# Stop Conditions & Budgets

A Ralph harness must decide when to end an iteration and when to stop the entire loop.  Because different agent runtimes offer varying controls, these conditions are enforced primarily by the harness rather than the tools themselves.

## Iteration stop conditions

* **Sentinel detection** – The prompt instructs the agent to output a sentinel such as `<promise>COMPLETE</promise>` when it believes the current story or all stories are complete.  The harness scans the final assistant message or structured output for this marker.  When found, it marks the story as finished and moves on.
* **Tool stop signals** – OpenCode agents can be configured with `maxSteps`; when the limit is reached the agent summarises its work and returns【559550733105805†L491-L524】.  The harness treats this summary as a stop signal and logs it.
* **Test pass/fail** – If validation fails (tests or linters), the iteration stops and the harness decides whether to retry or abort.  A passed validation indicates that the story is complete.

## Loop termination conditions

* **All stories complete** – When the PRD shows `passes: true` for all entries, exit the loop.  Use the sentinel to confirm that the agent agrees.
* **Max iterations** – Define a `max_iterations` count (e.g. 50) to avoid infinite loops.  If reached, log an escalation entry and stop.
* **Max failures** – Abort after a set number of consecutive failed iterations.  Escalate to a different model or a human reviewer.
* **Time budget** – Enforce a wall‑clock time limit per iteration and per job (e.g. 20 minutes per iteration).  If exceeded, treat as a failure.
* **Cost budget** – Track token usage via JSON event metadata.  Stop when the cumulative usage exceeds a project‑defined budget.  This is particularly important when using paid models.

## Budgeting considerations

Because headless agents have no inherent limits on thinking time or tokens, budgeting is critical.  Use the following strategies:

* **maxSteps** – For OpenCode, set `maxSteps` in the agent configuration to cap tool calls.  Use different profiles for planning, implementation and validation.
* **Token output caps** – Set environment variables like `OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX` or `CLAUDE_CODE_MAX_OUTPUT_TOKENS` to restrict the length of generated messages.
* **Model selection** – Choose models with lower costs or reasoning effort for mundane tasks (e.g., `gpt-3.5-turbo` in Codex) and reserve more expensive models (e.g., Claude Sonnet) for complex reasoning.
* **Local models** – Use Codex’s `--oss` flag to route to an on‑premise model for cost‑sensitive runs.

By combining sentinel detection, iteration limits and budgets, you can run long Ralph loops safely and deterministically.  Escalation and manual review provide escape hatches when stop conditions are breached.
