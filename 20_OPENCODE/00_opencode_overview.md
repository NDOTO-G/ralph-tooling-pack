# OpenCode Overview

**OpenCode** is Anthropic’s agentic coding environment and acts as a wrapper around Claude models with additional tooling.  For Ralph loops it serves as a robust and feature‑rich executor.  Key characteristics include:

* **CLI‑centric design** – All core functionality is exposed via a CLI (`opencode run`, `serve`, `session`, `stats`, etc.), making it easy to automate from scripts.  The `run` command accepts prompts non‑interactively and can output JSON for parsing【674709478433772†L420-L449】.
* **Skill system** – OpenCode implements the Agent Skills standard.  Skills live in `.opencode/skills/` and `~/.config/opencode/skills/` directories and contain a `SKILL.md` with YAML front‑matter.  Skills extend the agent with reusable workflows and domain knowledge【474358579328195†L96-L115】.
* **Plugin & event system** – A native plugin API allows you to hook into tool executions, session lifecycle events and context compaction.  Plugins run automatically from `.opencode/plugins/` and can mutate tool inputs or send notifications【543225958782144†L114-L121】.
* **Permissions & safety** – Fine‑grained permissions (`allow`, `ask`, `deny`) are defined in `opencode.json` or per agent and apply to tools and skills.  Defaults include `doom_loop` and `external_directory` to prevent runaway loops and restrict file access【310356558666353†L193-L214】.
* **MCP integration** – OpenCode can connect to external services via Model Context Protocol (MCP) servers.  You can define local or remote servers in the `mcp` section of your config【605040260244603†L195-L223】.  Each server adds tools (e.g., Puppeteer) to the agent’s environment.
* **Configuration** – Agents, permissions and MCP servers are configured via `opencode.json`.  Environment variables influence timeouts, token caps and server passwords (e.g., `OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX`)【674709478433772†L710-L717】.

Because of these features, OpenCode is well‑suited as the **primary executor** in a Ralph harness: you can precisely control its behaviour, integrate domain knowledge via skills and implement pre/post‑tool hooks to enforce policies.
