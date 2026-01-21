# Prompting Patterns – Codex CLI

Crafting effective prompts for Codex in a Ralph harness requires attention to structure and context.  Because Codex executes a single turn, your prompt must include all necessary instructions and context for that iteration.

## Use non‑interactive prompts

When running headless, call:

```bash
codex exec -f prompts/iteration.md --json --sandbox read-only --ask-for-approval on-request
```

This reads the prompt from a file and emits a JSON event stream.  The prompt should:

1. Clearly identify the story or task being worked on (e.g., by referencing `prd.json`).
2. Tell Codex to read necessary files using its own tools (it implicitly uses `bash` and other commands internally).
3. Instruct it to run tests, update the PRD and summarise its work.  Include a completion sentinel like `<promise>COMPLETE</promise>` in the expected output.
4. Describe any acceptance criteria and constraints (e.g., “Do not modify tests”).

## Emitting structured output

Add `--json` to `codex exec` to obtain newline‑delimited JSON events【874755510451889†L258-L270】.  Each event includes a type (`thread.started`, `turn.started`, `turn.completed`, `item.*`, `error`), timestamp and payload.  Parsing this stream allows you to extract diffs, tool calls and final messages.  You can also use:

* `--output-last-message <path>` to save the final assistant message while still printing it to stdout【874755510451889†L283-L285】.
* `--output-schema <schema>` to have Codex validate and structure its final output according to a JSON Schema【874755510451889†L287-L313】.

## Handling approvals

If your prompt requires running shell commands or making file edits, configure the approval policy via CLI flags:

* `--ask-for-approval on-request` – only ask when Codex explicitly asks for approval.
* `--ask-for-approval untrusted` – prompt before any command.
* `--ask-for-approval never` – never ask (use with caution)【413965132490193†L233-L287】.

Avoid using slash commands in Codex prompts; instead, describe the task explicitly.  Since skills are implicit or invoked by `$skillname` mentions, include skill names only if necessary (e.g., `$review`).

## Templates and reuse

Write prompt templates that parameterise the story ID, acceptance criteria and sentinel.  Use environment variables or a small script to substitute values before each iteration.  This yields reproducible prompts and simplifies debugging.
