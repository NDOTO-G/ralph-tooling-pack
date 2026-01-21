# Tools Inventory – Claude Code

Claude offers a set of built‑in tools accessible through its CLI.  In interactive mode they are invoked via slash commands (e.g., `/read`, `/edit`); in headless mode they are used automatically when you instruct Claude to perform tasks.  Key tools include:

| Tool | Purpose |
|---|---|
| `Read` | Read the contents of one or more files.  Useful for exploring code and specifications. |
| `Edit` | Apply patches to files.  Claude uses unified diff format internally. |
| `Bash` | Execute shell commands.  The agent will prompt for permission unless the command is auto‑approved via `--allowedTools`.  Use prefixes like `Bash(npm test:*)` in `--allowedTools` to approve specific commands【649120918286103†L161-L173】. |
| `Glob` | List files matching a glob pattern. |
| `Grep` | Search for patterns in files. |
| `Write` | Write text directly to a file.  Less common since `Edit` is preferred. |
| `Commit` | Create a git commit with a message.  Only available in interactive mode; disabled headless【649120918286103†L193-L195】. |
| `Push` / `PR` | Push changes or open pull requests.  Disabled headless. |
| `Skill` | Load and execute a skill; available only in interactive mode. |
| `MCP` tools | Additional connectors configured via MCP servers (e.g., `mcp__puppeteer__*` for browser automation). |

In headless mode you must grant permissions for tools via `--allowedTools` on the CLI (comma‑separated names)【649120918286103†L161-L173】.  For example, `--allowedTools "Read,Edit,Bash(git diff:*)"` auto‑approves read/edit operations and any bash command starting with `git diff`【649120918286103†L186-L191】.

Claude also respects the settings file `.claude/settings.json`, which persists permission choices across sessions【135116144821332†L118-L137】.  Use this file to tailor tool access for your project.
