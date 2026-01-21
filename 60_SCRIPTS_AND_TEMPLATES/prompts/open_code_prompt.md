# Sample Prompt – OpenCode

```
## Current context
This repository includes a planning file `prd.json` listing pending stories and a progress log `progress.md`.  You are an OpenCode agent running in a Ralph loop.

## Your task
1. Read `prd.json` and identify the story with the highest priority where `passes` is false.
2. Summarise what needs to be done in one paragraph and ask any clarifying questions if necessary.
3. Implement the story.  Use the `read`, `grep` and `bash` tools to explore the codebase.  When editing files, follow our style guide (see `spec/style.md`).  Do not modify test files unless explicitly instructed.
4. Run the test suite (`bash("npm test")`).  If tests fail, fix the issues and re‑run until the suite passes.
5. When the story is complete, update `prd.json` by setting the story’s `passes` flag to true.
6. Append a summary of your work, including the files changed and any key learnings, to `progress.md`.

## Sentinel
If all stories in `prd.json` now have `passes: true`, output `<promise>COMPLETE</promise>` on a line by itself.

## Skills
You may load and use any skill that starts with `internal-` automatically.  For other skills, ask for confirmation.
```