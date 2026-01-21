# Claude Code Overview

**Claude Code** is Anthropic’s CLI for interacting with Claude models in a coding environment.  It supports both interactive (REPL) and headless modes.  In the context of Ralph loops, the headless `-p` flag allows non‑interactive execution.

Notable features:

* **Headless mode (`-p`)** – Run prompts non‑interactively.  Claude prints only the final message to stdout and streams progress to stderr【649120918286103†L66-L90】.  Options available in the REPL (e.g. model selection, system prompt customisation) also apply to headless mode.
* **Structured output** – `--output-format` accepts `text` (default), `json` or `stream-json`.  Use `json` to get a single JSON object with `result`, `session_id` and metadata or `stream-json` to get newline‑delimited JSON events【649120918286103†L110-L117】.
* **Skills and subagents** – Claude supports advanced skills defined in `.claude/skills` or `~/.claude/skills` and can run them in isolated subagents using `context: fork`【500585924894070†L540-L560】.  Skills include fields like `allowed-tools`, `model` and `agent`【500585924894070†L290-L318】.
* **Hook system** – Claude offers a powerful hook mechanism with events such as PreToolUse, PermissionRequest, PostToolUse, Notification, Stop, PreCompact, SessionStart and SessionEnd【995113787448290†L100-L119】.  Hooks run user‑defined shell commands that can modify or block tool calls【995113787448290†L68-L88】.
* **Permissions** – By default Claude asks permission before running any tool that might have side effects.  Permissions can be adjusted via `/permissions` in interactive mode or via `--allowedTools` and settings files in headless mode【135116144821332†L118-L137】.
* **Resumption** – The `--continue` flag resumes the most recent session; `--resume <session-id>` continues a specific session【649120918286103†L219-L245】.  This allows multi‑iteration workflows in headless mode.

Claude’s combination of rich skills, hooks and non‑interactive execution makes it ideal for complex reasoning and review tasks within a Ralph harness.  However, skills and slash commands are disabled in headless mode【649120918286103†L193-L195】, so prompts must inline any instructions normally provided by skills.
