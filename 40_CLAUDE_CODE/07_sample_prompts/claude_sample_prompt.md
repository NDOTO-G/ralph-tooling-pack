# Sample Prompt – Claude Code

This sample prompt illustrates how to instruct Claude Code to execute a single iteration of a Ralph loop.  Adapt paths and filenames to your project structure.

```
## Context

You are an AI coding agent working in a Git repository.  Read the project readme and CLAUDE.md for general guidelines.

**PRD location:** `prd.json`
**Progress log:** `progress.md`

## Task

1. Load the PRD (`prd.json`) and the progress log (`progress.md`).  Each entry in the PRD has a `passes` flag indicating whether the task has been completed.
2. Select the highest priority story where `passes` is `false`.  Do not pick the first story blindly – choose what seems most important.
3. Implement that story using only the permitted tools (Read, Edit, Bash).  Follow any acceptance criteria defined in the PRD.
4. Run type checks and tests via the provided `run_tests.sh` script.  If tests fail, describe the failures and do **not** mark the story as complete.
5. Update the PRD by setting the story’s `passes` field to `true` if and only if tests pass.  Append a summary of what you learned to the progress log with a timestamp and commit hash.
6. Conclude your response with `<promise>COMPLETE</promise>` so the harness knows when you are done.

## Additional guidelines

* Use `grep`, `read` and `glob` to inspect files before modifying them.
* Do not modify files outside the repository root.
* If you need to search for information, use the search tool or ask clarifying questions in your reasoning (these will not be shown to users).
* Keep your code changes focused on the selected story; do not begin working on other tasks until this one is completed.
```