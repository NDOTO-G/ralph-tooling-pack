# Example Workflows – Codex CLI

These examples illustrate how to incorporate Codex into a Ralph loop.  Adjust the specifics to match your project structure and tooling.

## Workflow: Implement a story via Codex

1. **Prepare the plan** – Write a `prd.json` file containing user stories.  Ensure each story has clear acceptance criteria and a `passes: false` flag.
2. **Generate prompt** – Use a script (e.g., Python or bash) to read `prd.json`, select the next story and fill a prompt template similar to the one in `20_OPENCODE/07_sample_prompts`.  Save it to `prompts/iter_N.md`.
3. **Run Codex** – Invoke the agent non‑interactively:
   ```bash
   codex exec -f prompts/iter_N.md --json --sandbox workspace-write \
     --ask-for-approval on-request --output-last-message artifacts/iter_N_last.txt \
     > artifacts/iter_N_events.jsonl
   ```
   Use `--model` to select the desired model or `--oss` to use a local provider【413965132490193†L892-L904】.
4. **Parse results** – Write a parser that reads `artifacts/iter_N_events.jsonl`.  Extract file diffs, command outputs and the final message.  Determine whether tests passed and whether the sentinel appears.  Log token usage and reasoning steps.
5. **Update state** – If the story is complete and passes validation, update `prd.json` (`passes: true`) and append an entry to `progress.md`.  Otherwise, construct a new prompt including error messages and retry.
6. **Loop control** – Continue until all stories pass or until hitting `max_iterations` or `max_failures`.  Switch to another tool (e.g., Claude Code) for escalation if progress stalls.

## Workflow: Offline runs with local models

1. Install and start an OSS provider (e.g., Ollama) that serves open‑source models.
2. Set `--oss` on `codex exec` to route the request to the local provider.  Optionally specify the provider in `config.toml` with `oss_provider = "lmstudio"` or `"ollama"`【702130749475210†L368-L374】.
3. Execute the same loop as above.  Expect slower or less accurate results but no API costs.  Use lower reasoning effort levels to keep token usage manageable.

These workflows demonstrate how Codex can be integrated into a Ralph loop as either the primary executor for budget‑sensitive tasks or as a fallback when API access is unavailable.
