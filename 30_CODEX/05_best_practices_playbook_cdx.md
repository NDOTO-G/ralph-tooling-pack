# Best Practices Playbook – Codex CLI

The following guidelines help you use Codex effectively within a Ralph harness.  They combine official recommendations and lessons learned.

## Plan and scope

* **Keep prompts concise** – Codex processes only one turn at a time.  Provide enough context to complete the current story but avoid overloading with unrelated details.
* **Explicit instructions** – Because slash commands are disabled headless, instruct Codex exactly what to do (e.g., “Read `src/auth.py`, implement a login function, run tests, update `prd.json`).
* **One story per iteration** – Break work into small units to simplify validation and reduce context.  Update the PRD after each successful completion.

## Use JSON output

* **Parse events** – Always run with `--json` and capture the JSONL stream.  Use this to extract tool calls, file diffs and errors.  Do not rely on human‑formatted messages for automation.
* **Save final message** – Use `--output-last-message` to persist the assistant’s final response for logging or further processing.
* **Consider schemas** – For structured responses (e.g., summarising commit information), provide a JSON Schema via `--output-schema` and parse the `structured_output` field【874755510451889†L287-L313】.

## Balance cost and performance

* **Select appropriate models** – Use `--model` to choose cheaper models for simple tasks.  Reserve larger models for complex reasoning or critical paths.
* **Route to local models** – Use `--oss` for offline runs or to avoid API costs【413965132490193†L892-L904】.  Ensure a compatible provider (e.g., Ollama) is running.
* **Tune reasoning effort** – Configure `model_reasoning_effort` in `config.toml` to control how much thought Codex expends【984562243754748†L277-L281】.  Lower levels reduce token usage.

## Permissions and safety

* **Use sandbox** – Default to `read-only` during planning.  Switch to `workspace-write` only when ready to apply patches【413965132490193†L418-L427】.
* **Define rules** – Create `.rules` files to forbid dangerous commands (e.g., `rm -rf`) or prompt before certain patterns【40854120253895†L214-L280】.
* **Skip prompts sparingly** – Avoid `--dangerously-bypass-approvals-and-sandbox`; instead rely on `--ask-for-approval on-request` and review potential side effects.

## Harness integration

* **Implement pre/post hooks** – Since Codex has no plugin API, your script should wrap `codex exec` with pre‑run setup (checkout branches, write prompt file) and post‑run parsing (collect evidence, update PRD and progress log).
* **Validate externally** – Run tests and linters outside of Codex.  If they fail, include the errors in the next prompt.  Limit retries and scale to a different tool if needed.
* **Log everything** – Append iteration metadata, diff summaries and token usage to the progress log.  Commit changes after each iteration to preserve state.

These practices turn Codex’s simple CLI into a reliable component within a larger autonomous coding pipeline.
