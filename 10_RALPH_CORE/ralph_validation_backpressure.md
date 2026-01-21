# Validation & Back‑Pressure

In a Ralph loop, validation and back‑pressure ensure that each iteration produces correct and high‑quality code.  Without feedback, agents may drift, produce buggy code or get stuck.  This document summarises common validation techniques and how they influence the loop.

## Validation mechanisms

* **Unit tests and type checks** – Run the project’s test suite and type checker after each iteration.  If tests fail, the harness should log the errors and either retry with guidance (e.g., “fix failing tests”) or abort after multiple failures.
* **Static analysis & linters** – Use tools like ESLint, Prettier or CodeRabbit to catch style issues and potential bugs.  Post‑analysis, ask the agent to fix any reported problems.
* **Diff review** – Generate a diff of changes and summarise it using a separate agent or skill.  Check for unexpected file edits (e.g., modifications outside `src/`) or large deletions.  Optionally run a “review” skill to comment on the diff.
* **Human checkpoints** – For high‑impact changes (schema migrations, security updates), interleave manual review.  The progress log can flag entries that need human approval.
* **Permission and safety checks** – Reject tool calls that attempt to read secrets or modify protected files.  In OpenCode use permission patterns and plugin hooks; in Codex employ `.rules` files; in Claude use hooks and `--allowedTools`.

## Back‑pressure patterns

Back‑pressure is any mechanism that slows or stops the agent when the output is unsatisfactory.  Common patterns include:

| Pattern | Implementation | Outcome |
|---|---|---|
| **Explicit retry** | On failure, generate a new prompt with additional guidance (e.g., include error messages or failing tests) and rerun.  Limit retries to avoid infinite loops. | Agent iteratively fixes issues. |
| **Escalation** | If retries exceed a threshold or the agent appears stuck, switch to a more capable model (e.g., from Codex to Claude) or bring a human into the loop. | Ensures progress when the primary agent cannot solve a task. |
| **Step reduction** | Reduce `maxSteps` or shrink the task scope (e.g., implement only part of a story) after repeated failures. | Gives the agent a smaller problem to solve. |
| **Context injection** | Use compaction or hooks to inject additional context (specifications, previous learnings) when the agent forgets important details. | Improves reasoning without growing the prompt. |

## Logging evidence

Always capture **evidence**: test outputs, diff summaries, reasoning traces and token usage.  Include them in the progress log so you can trace why a particular iteration failed and how it recovered.  Evidence supports debugging and helps calibrate back‑pressure thresholds.

In summary, validation and back‑pressure transform the Ralph loop from a blind repetition into a feedback‑driven cycle.  They ensure that the agent meets your quality bar before moving on to the next story.
