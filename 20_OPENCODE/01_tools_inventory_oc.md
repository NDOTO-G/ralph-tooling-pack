# Tools Inventory – OpenCode

OpenCode exposes several **built‑in tools** that agents can call to interact with the repository and environment.  Understanding these tools helps you craft permission policies and predict behaviour.  Common tools include:

| Tool | Purpose |
|---|---|
| `read` | Read the contents of a file.  Takes a `filePath` and returns the file’s text. |
| `edit` | Edit a file.  Provides a unified diff or replacement content.  The agent uses this to modify code. |
| `bash` | Execute shell commands within the project directory.  Returns stdout, stderr and exit code.  Constrained by sandbox and permissions. |
| `glob` | List files matching a glob pattern.  Useful for discovering source files. |
| `grep` | Search for text across files and return matching lines. |
| `skill` | Load a skill by name; returns the skill’s instructions.  Skills extend the agent’s abilities. |
| `task` | Schedule a background task (e.g., run tests).  Returns a task handle. |
| `webfetch` | Fetch content from a URL.  Disabled by default for safety. |
| `coverage` | Generate code coverage reports and merge them with progress. |
| `write` | Write text to a file.  Limited by permissions; replaced by `edit` in most workflows. |

Some tools are optional and may be disabled by permissions.  You can also add custom tools via MCP servers (e.g., `puppeteer` for browser automation).  Permissions should be configured in `opencode.json` to allow or deny specific tool calls【310356558666353†L139-L164】.

In addition to tools, the CLI provides **subcommands** such as:

* `opencode run` – Execute prompts non‑interactively, attach to a server and stream JSON output.
* `opencode serve` – Start a headless server that clients can attach to; supports `--port`, `--hostname` and basic authentication【674709478433772†L469-L480】.
* `opencode session list` / `export` / `import` – Manage and archive past sessions【674709478433772†L510-L546】.
* `opencode acp` – Expose the Agent Client Protocol for editor integrations【674709478433772†L590-L599】.
* `opencode stats` – Display token usage and cost statistics【674709478433772†L518-L533】.

When designing prompts and permissions, choose which tools the agent may call automatically (e.g., `read`, `grep`) and which require approval (`bash`, `edit`).  This ensures that your harness maintains control over side effects while still enabling productive automation.
