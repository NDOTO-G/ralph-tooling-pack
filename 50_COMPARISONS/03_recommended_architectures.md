# Recommended Architectures

Based on our research and comparative analysis, we recommend a **tiered architecture** for agentic development that leverages the strengths of each tool while mitigating their weaknesses.  The aim is to maximise throughput, minimise cost and maintain safety.

## Tiered runner model

1. **Primary runner – OpenCode**
   * **When to use:** Most feature work, refactors and repetitive tasks on a trusted codebase.
   * **Why:** OpenCode offers a mature skills system, rich plugin hooks and explicit `maxSteps` limits.  It can run unattended loops via `opencode serve` and emits structured JSON events for auditing【674709478433772†L420-L449】.  Because it runs in your local environment, it can operate on large repositories with low latency.
   * **Architecture:** Run `opencode serve` once, then invoke `opencode run` with `--format json --attach`.  Use custom plugins to intercept commands and enforce policies.  Plan tasks as PRD stories and iterate until `<promise>COMPLETE</promise>` is returned.

2. **Budget/offline runner – Codex CLI**
   * **When to use:** Projects with strict cost constraints, limited compute budgets or no internet connectivity.  Use for tasks where perfect safety and reproducibility are less critical.
   * **Why:** Codex supports `--oss` to route to local providers (Ollama or LM Studio)【413965132490193†L892-L904】.  Non‑interactive runs print only the final message, reducing network overhead【874755510451889†L214-L242】.  However, it lacks native hooks and `maxSteps`, so the harness must supply validation and budgeting logic.
   * **Architecture:** Use `codex exec --json` to stream events.  Implement approval policies via `--ask-for-approval` and `.rules` files.  Parse JSON for completion and validation.  Escalate to OpenCode or Claude when complex reasoning or plugin capabilities are needed.

3. **Escalation/review runner – Claude Code**
   * **When to use:** Difficult bugs, architectural changes, complex reasoning, code reviews and stuck runs.
   * **Why:** Claude’s models (e.g., Opus) have excellent reasoning ability and large context windows.  The hook system enables notifications and policy enforcement【995113787448290†L100-L119】.  Nevertheless, headless mode lacks built‑in step limits and disables slash commands【649120918286103†L66-L90】, so use it sparingly.
   * **Architecture:** Run headless via `claude -p` with `--output-format stream-json` and specify `--allowedTools`.  The harness monitors budgets, detects `<promise>COMPLETE</promise>` and decides whether to continue.  Use hooks for logging and permission enforcement.  Deploy in an isolated container to mitigate risk.

## Hand‑off strategy

* Start tasks with **OpenCode**.  Its skills and plugins support fine‑grained control and high throughput.  Use `maxSteps` and back‑pressure mechanisms to keep loops tight.
* If OpenCode stalls due to repeated validation failures or lacking capability (e.g. planning complexity), **escalate to Claude**.  Copy the same PRD and progress files and run a headless Claude iteration.  If Claude produces a solution, merge it back into the OpenCode loop.
* Use **Codex** for local/offline runs or when budgets must be tightly constrained.  Its event stream is similar to OpenCode’s, so the same parsing logic applies.
* A human reviewer may intervene at any stage by inspecting `PROGRESS.md`, diffs and test outputs.  The harness should make it easy to swap from automated to manual control.

## Automation pipeline

1. **Plan generation:** Use a planning skill or a separate agent to break a feature into tasks and produce a PRD.  Store it under version control.
2. **Loop execution:** For each task in the PRD, iterate using the primary runner until the task is complete or budgets are exhausted.
3. **Validation:** Run CI jobs (tests, lints, type checks, code reviews) outside of the agent.  Use gates to prevent commits if validation fails.
4. **Escalation:** When failure thresholds or budgets are exceeded, switch runners or request human input.
5. **Merge and release:** Once all PRD items are complete and validated, merge changes into the main branch.  Document learnings in the progress log for future reference.

This tiered architecture balances speed and safety.  As models and tools evolve, you can update the runner definitions without rewriting the harness’s core logic.