# Stop Conditions & Budgets – Codex CLI

Codex lacks built‑in iteration or step limits, so the harness must enforce stop conditions and budgets externally.

## Stop conditions

* **Single‑turn completion** – `codex exec` ends when the agent produces a final assistant message.  Parse the JSON event stream to find the `turn.completed` event and treat it as the end of the iteration【874755510451889†L258-L270】.
* **Sentinel detection** – Include a sentinel (e.g., `<promise>COMPLETE</promise>`) in your prompt and look for it in the final message.  Stop processing the current story when seen.
* **Iteration limits** – Track the number of iterations in your harness (e.g., 50).  Abort when the limit is exceeded to prevent infinite loops.
* **Validation failures** – If tests or linting fail, retry up to a maximum number of attempts.  After repeated failures, log an escalation and stop.

## Budget management

* **Model costs** – Use cheaper models (`gpt-3.5-turbo`) for simple tasks and reserve more expensive ones (`gpt-4`) for complex reasoning.  Set the `model_reasoning_effort` configuration to limit reasoning depth【984562243754748†L277-L281】.
* **Local providers** – Enable the `--oss` flag to route to a local model provider (e.g., Ollama or LM Studio).  This eliminates API costs at the expense of potentially lower quality【413965132490193†L892-L904】.
* **Tool output limits** – Use the `tool_output_token_limit` configuration key to restrict how many tokens from tool output are stored in context【702130749475210†L456-L457】.
* **Time limits** – Enforce a wall‑clock timeout per iteration in your harness script (e.g., abort if the JSON stream does not end within 10 minutes).

## Sandbox and approvals

Permissions indirectly influence budgets by controlling side effects:

* Set `--sandbox read-only` for planning or exploration phases.  Switch to `workspace-write` when edits are needed【413965132490193†L418-L427】.
* Use `--ask-for-approval on-request` to reduce prompts while still gating high‑impact commands【413965132490193†L233-L287】.
* Avoid `--dangerously-bypass-approvals-and-sandbox` unless running in a locked‑down container【413965132490193†L316-L325】.

By combining these measures with harness‑level control flow, you can run Codex safely and within budget as part of a Ralph loop.
