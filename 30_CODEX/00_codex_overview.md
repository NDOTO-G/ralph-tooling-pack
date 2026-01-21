# Codex Overview

**Codex CLI** is OpenAI’s command‑line interface to the GPT‑4/3.5 family for coding tasks.  While originally designed for interactive use, it offers a `codex exec` subcommand that makes it useful in automation scenarios such as a Ralph harness.

Key characteristics:

* **Non‑interactive execution** – `codex exec` runs a single agent turn and returns immediately.  It streams progress to stderr and prints the final assistant message to stdout【874755510451889†L214-L242】.  Adding `--json` emits newline‑delimited JSON events for programmatic consumption【874755510451889†L258-L270】.
* **Model flexibility** – Choose a specific OpenAI model with `--model` or route requests to a local provider using `--oss`【413965132490193†L892-L904】.  This allows offline or cost‑optimised runs.
* **Skill system** – Codex supports Agent Skills stored in `.codex/skills` and loaded automatically【317920800239899†L260-L291】.  The system is simpler than OpenCode’s but still allows modular instructions.
* **Limited hooks** – There is no plugin API.  Hooks are limited to a `notify` mechanism that runs an external command on `agent-turn-complete` events【454175575763456†L564-L604】 and an OpenTelemetry integration【454175575763456†L428-L457】.  Fine‑grained control must be implemented in the harness.
* **Permissions & sandbox** – Use `--ask-for-approval` to control when human approval is required and `--sandbox` to choose the level of filesystem/network access【413965132490193†L220-L287】.  Codex also supports `.rules` files for command whitelisting【40854120253895†L214-L280】.

These features make Codex a versatile but lightweight option in a Ralph loop.  It is especially attractive when running locally via `--oss` or when cost is a concern.  However, the lack of native hooks and step limits means the harness must provide its own validation and escalation logic.
