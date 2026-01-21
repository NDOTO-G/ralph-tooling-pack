# Glossary

This glossary defines key terms used throughout the research pack.

| Term | Definition |
|---|---|
| **Ralph loop** | A bash or script loop that repeatedly invokes an AI coding agent to work through a backlog.  It manages prompts, persists state (PRD and progress log) on disk, discards chat history to avoid context rot and uses a completion sentinel to detect when tasks are done. |
| **Harness** | The orchestration layer around the agent runtime.  It creates prompts, runs the agent, parses outputs, logs evidence, enforces budgets and decides when to retry, stop or switch tools. |
| **Agent** | The AI coding system invoked by the harness.  Examples include OpenCode (Anthropic), Codex CLI (OpenAI) and Claude Code (Anthropic). |
| **PRD (Product Requirements Document)** | A structured plan describing user stories or features to implement.  In Ralph loops it is typically a JSON or Markdown file with a `passes` flag per story. |
| **Progress log** | An append‑only file (e.g., `PROGRESS.md` or `progress.txt`) where each iteration records the session ID, prompt hash, diff summary, test results and summary.  This provides traceability and allows crash‑safe restarts. |
| **Prompt** | A plain‑text or Markdown instruction given to the agent.  Ralph prompts often instruct the agent to pick the highest‑priority story, implement it, run tests, update the PRD and emit a sentinel like `<promise>COMPLETE</promise>`. |
| **Skill** | A reusable package of instructions defined in a `SKILL.md` file with YAML front‑matter.  Skills can be invoked by agents to perform domain‑specific tasks.  OpenCode and Claude support skills extensively, while Codex has a simpler implementation. |
| **Hook** | A function or script that runs on specific lifecycle events.  OpenCode plugins and Claude hooks offer native pre‑/post‑tool hooks.  Codex provides a `notify` hook and relies on harness‑level hooks for custom logic. |
| **Back‑pressure** | Mechanisms that slow down or halt the agent when quality gates fail.  Examples include failing tests, exceeding `maxSteps`, encountering permission denials or hitting iteration limits.  The harness uses back‑pressure to force the agent to fix issues before continuing. |
| **Stop condition** | A rule that tells the harness when to exit the loop.  Common conditions include encountering a completion sentinel in the final message, hitting a `max_iterations` limit, or reaching a `maxSteps` limit in OpenCode. |
| **MCP (Model Context Protocol)** | A protocol for connecting agents to external services (e.g., browsers, GitHub).  OpenCode and Claude support MCP; each connector adds to the context window and may require authentication. |
| **Sandbox** | A mechanism restricting file system and network access.  Codex offers `read-only`, `workspace-write` and `danger-full-access` sandbox modes; OpenCode uses permission policies; Claude relies on `--allowedTools` and hooks. |
| **Headless mode** | Running an agent without an interactive user interface.  OpenCode (`opencode run`), Codex (`codex exec`) and Claude (`claude -p`) all support headless operation. |
