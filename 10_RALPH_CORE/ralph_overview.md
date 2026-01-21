# Ralph Loop Overview

A **Ralph loop** is an orchestration pattern for agentic coding.  Instead of relying on a single long chat session, Ralph executes an AI coding agent repeatedly in a fresh context, reading state from disk and writing progress back to disk after each iteration.  This simple loop solves two problems:

1. **Context rot** – Large chats degrade model performance.  Ralph avoids this by discarding chat history and starting each turn with just the relevant plan (PRD), progress log and a prompt template.  Fresh context yields consistent reasoning across hundreds of iterations.
2. **Reliability** – By breaking work into small, self‑contained steps (one story at a time), Ralph allows the harness to validate outcomes after each iteration, apply back‑pressure when tests fail, and restart if necessary.  This deterministic loop is far easier to monitor than a multi‑agent swarm.

### Basic anatomy

Each iteration of a Ralph loop follows these steps:

1. **Read state** – Load the current PRD (list of stories with `passes` flags), progress log and any specification files.  Determine which story to work on next.
2. **Build prompt** – Construct a prompt instructing the agent to pick the highest‑priority uncompleted story, implement it, run tests/type checks, update the PRD and append a summary to the progress log.  Include a sentinel (e.g., `<promise>COMPLETE</promise>`) to signal completion.
3. **Invoke agent** – Use the agent’s CLI (OpenCode, Codex or Claude) in headless mode to process the prompt.  Capture structured output (JSON events) and the final assistant message.
4. **Validate and log** – Parse the events to detect errors, failed tests or permission prompts.  Append a progress entry describing the outcome, including session ID, diff summaries and token usage.
5. **Update state** – Mark the story as `passes: true` in the PRD if the implementation succeeds.  Commit changes to Git to persist the new state and context for the next iteration.
6. **Decide to continue** – If the sentinel appears and all stories pass, exit the loop.  Otherwise, advance to the next iteration and repeat.

### Philosophy

Ralph loops embrace simplicity.  They run a **single agent** at a time rather than swarms of agents, avoid multi‑threaded complexity, and rely on durable state (files and Git) instead of in‑memory chat history.  This makes them deterministic, auditable and easy to pause or resume.

Jeff Huntley, the original proponent of Ralph, emphasised “learn to use a screwdriver before the jackhammer”: start with simple loops and manual back‑pressure before automating everything.  Ralph loops align with this ethos by giving you full control over context, prompts, validation and iteration budgets.  Over time you can add automation (plugins, hooks, subagents) but the core remains a straightforward `while true` loop.
