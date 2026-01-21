# Ralph Primitives

The Ralph harness relies on a handful of simple but powerful primitives.  Understanding and designing these artefacts well is critical to building reliable loops.

## PRD (Product Requirements Document)

The PRD is a structured plan file describing what the agent should implement.  It typically contains an array of **user stories**, each with:

* A **title** (e.g., `Add login form`)
* A **description** (acceptance criteria or tests)
* A **priority** (optional)
* A **passes** boolean indicating whether the story has been completed

PRDs are often stored as JSON (`prd.json`) or Markdown with checkboxes.  At the start of each iteration the harness loads the PRD, selects the highest‑priority `passes: false` story and inserts its content into the prompt.  When a story is completed successfully, the harness sets `passes: true` and commits the change so that subsequent iterations skip it.

## Progress log

The progress log (`PROGRESS.md` or `progress.txt`) is an **append‑only** record of each iteration.  Each entry includes:

* A **timestamp** (ISO 8601 UTC)
* The **iteration number**
* The **prompt file** path and a hash for reproducibility
* **Agent metadata** (runtime, model, allowed tools)
* **Result** – one of `COMPLETE`, `FAILED`, `ESCALATED` or `ABORTED`
* A concise **summary** of work done
* Pointers to **evidence artefacts** (JSON event logs, diffs, test output, commit hashes)

By committing the progress log to Git after each iteration, you ensure that the harness is crash‑safe: you can restart the loop, reload the PRD and progress log, and continue from where you left off.

## Prompt templates

Prompts drive the agent to perform work.  Ralph prompts usually include:

* A **task description**: instruct the agent to read the PRD and progress log, pick the highest‑priority story and implement it.
* **Environment instructions**: remind the agent to run tests, check types and maintain style.  Specify which files to update (and which to avoid).
* **Context cues**: mention relevant specification files (e.g., `CLAUDE.md` for Claude, `specme.md` for OpenCode) so the agent knows where to read details.
* A **sentinel**: request the agent to output a special marker (e.g., `<promise>COMPLETE</promise>`) when it believes all tasks are complete.

Prompt templates are stored in files (e.g., `prompts/iteration.md`) and parameterised with the current story and context.  The harness writes a fresh prompt file each iteration, substituting values as needed.

## Back‑pressure and validation hooks

While not strictly a primitive, **back‑pressure** is a core concept.  The harness must provide feedback to the agent when it produces invalid code.  This includes running unit tests, type checks and linters, analysing diffs and capturing permission denials.  If validation fails, the harness records the failure and either retries with a modified prompt or escalates the task to a different tool or a human.
