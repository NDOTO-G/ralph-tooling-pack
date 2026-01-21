```
## Context
You are an AI developer using the Codex CLI in a Ralph loop.  The repository contains a plan file (`prd.json`) and a progress log (`progress.md`).

## Task
1. Parse `prd.json` and identify the highest‑priority user story where `passes` is `false`.
2. Summarise the story in your own words.
3. Write code to implement the story.  Only modify files under the `src/` directory.  Do not change any tests.
4. Run the test suite using the appropriate command (e.g., `npm test` or `pytest`).  If tests fail, report the errors and suggest fixes.
5. When the story is complete and tests pass, update `prd.json` to set `passes: true` for this story.
6. Write a short summary of your work and any important details to `progress.md`.

## Constraints
* Operate within the workspace sandbox.  Do not access external network resources.
* Only run commands that are safe and necessary; avoid destructive operations like file deletion.

## Sentinel
Output `<promise>COMPLETE</promise>` when all stories in `prd.json` are complete.

```
