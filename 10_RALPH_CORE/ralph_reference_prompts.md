# Reference Prompts

This section collects example prompt templates used when invoking different agents.  Each prompt instructs the agent to pick a task from the PRD, implement it, run tests and update state.  Customise these templates for your codebase and agent of choice.

## Generic Ralph iteration prompt

```
## Context
You are an AI coding agent operating in a Ralph loop.  The current repository contains a PRD at `prd.json` and a progress log at `progress.txt`.  Your job is to pick the highest‑priority user story where `passes = false`, implement that story and run tests.

## Instructions
1. Load and parse `prd.json`.
2. Select the story with the highest priority where `passes` is `false`.
3. Plan your approach briefly before coding.
4. Implement the story by editing files as needed.  Do not modify test files unless instructed.
5. Run type checks and unit tests.
6. If all tests pass, mark the story’s `passes` field as `true` in `prd.json`.
7. Append a summary of what you did to `progress.txt`.  Include commit hashes and any learnings.

## Sentinel
When all stories in `prd.json` have `passes = true`, output `<promise>COMPLETE</promise>` on a separate line.
```

## OpenCode‑specific additions

* Remind the agent to use the `skill` tool to load any relevant skills.
* Mention `specme.md` or other specification files to prime the model.
* Use a compaction hook to persist important context between iterations if necessary.

## Codex‑specific additions

* Avoid slash commands; describe the task entirely in natural language.
* Ask Codex to produce newline‑delimited JSON events by specifying `--json` on the CLI.  In the prompt you can request that it outputs additional metadata in the final message.
* Include your stop sentinel and explain that the loop will parse it.

## Claude‑specific additions

* Clarify which tools are allowed via `--allowedTools` (e.g., “You may use the `Read`, `Edit` and `Bash(npm test:*)` tools without prompting.”).
* Avoid slash commands in headless mode; inline any skill instructions from `CLAUDE.md`.
* Optionally use “think” or “think hard” to encourage deeper reasoning, but be aware of increased token usage.

Feel free to adapt these prompts; the key is to bound the work to a single story, run tests and emit a completion marker.
