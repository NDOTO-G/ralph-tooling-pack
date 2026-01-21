# Best Practices Playbook – OpenCode

This playbook summarises lessons learned when using OpenCode as the primary engine in a Ralph harness.  It highlights patterns that maximise reliability, reproducibility and safety.

## Structure your plan and prompts

* **Write clear PRDs** – Break work into small, independent stories with well‑defined acceptance criteria.  Keep descriptions concise and actionable.
* **Load specifications via files** – Place important context (e.g., API documentation, style guides) in dedicated files and instruct the agent to read them.  Avoid embedding large documents in the prompt.
* **Use skills for reusable workflows** – Encapsulate common tasks (planning, code review, deployment) in skills.  Invoke them via the `skill` tool when needed.  This keeps prompts short and maintainable.
* **Include a sentinel** – Tell the agent to emit a completion marker when all tasks are complete.  This allows the harness to detect completion automatically.

## Tune permissions and tools

* **Start with least privilege** – Default all tools to `ask` or `deny` in `opencode.json`.  Explicitly `allow` low‑risk tools like `read` and `grep` and require manual approval for `edit`, `bash` and network operations.
* **Use patterns** – Grant fine‑grained permissions using patterns (e.g., `bash(git commit *): ask`, `bash(rm *): deny`)【310356558666353†L139-L164】.
* **Control skills access** – Restrict high‑risk skills by pattern and set them to `ask` or `deny`【474358579328195†L218-L247】.  Disable all skills for agents that do not need them by setting `tools.skill: false`.

## Exploit plugins

* **Pre‑run sanitisation** – Use a `tool.execute.before` hook to escape bash commands and block dangerous operations (e.g., reading `.env` files)【543225958782144†L382-L400】.
* **Context compaction** – Implement an `experimental.session.compacting` hook to inject critical context into summaries【543225958782144†L485-L523】.
* **Notifications** – Hook `session.idle` or `session.error` to send alerts via your notification system【543225958782144†L344-L366】.  This helps monitor long‑running loops.

## Manage iterations

* **Set `maxSteps` per agent** – Use lower `maxSteps` values for simple tasks and higher values when the agent needs to call multiple tools in one run.  Evaluate summaries if a run hits the limit.
* **Configure budgets** – Use environment variables to cap token output and command timeouts.  Combine with harness‑level limits like `max_iterations` and `time_budget_minutes`.
* **Retry judiciously** – When validation fails, add specific guidance (e.g., test error messages) to the prompt and retry.  Limit the number of retries to avoid burning tokens.
* **Escalate when stuck** – After repeated failures, switch to a more capable model (e.g., Claude) or involve a human.

## Logging and observability

* **Always capture JSON events** – Run `opencode run` with `--format json` and save the output to a file.  Parse it to extract tool calls, diffs, exit codes and token usage.
* **Write to the progress log** – At the end of each iteration append an entry to `PROGRESS.md` summarising the actions taken, results, evidence paths and any warnings.
* **Use Git effectively** – Commit after each iteration.  Use branches per story to isolate changes.  Store the commit hash in the progress log for auditability.

Following these practices helps maintain control over OpenCode’s powerful capabilities and ensures that your Ralph loop operates safely and predictably.
