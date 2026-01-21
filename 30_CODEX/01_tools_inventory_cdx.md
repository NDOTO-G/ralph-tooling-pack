# Tools & Commands – Codex CLI

Codex does not expose individual `read`/`edit`/`bash` tools like OpenCode or Claude.  Instead, it offers a set of CLI subcommands and flags that control how the underlying agent interacts with your repository.  Important commands include:

| Command/Flag | Purpose |
|---|---|
| `codex exec` | Run a single agent turn with the provided prompt.  Use `--json` to emit structured JSON events【874755510451889†L258-L270】. |
| `codex exec resume` | Resume the last or a specified session ID for follow‑up iterations【874755510451889†L340-L344】. |
| `--model <id>` | Select a specific OpenAI model (e.g., `gpt-3.5-turbo`, `gpt-4o`). |
| `--oss` | Route requests to a local open source provider (e.g., Ollama or LM Studio)【413965132490193†L892-L904】.  Requires a running server. |
| `--json` | Emit newline‑delimited JSON events describing tool decisions, file edits and errors【874755510451889†L258-L270】. |
| `--output-last-message <path>` (`-o`) | Save the final assistant message to a file【874755510451889†L283-L285】. |
| `--output-schema <schema>` | Validate and format the final message against a JSON Schema【874755510451889†L287-L313】. |
| `--ask-for-approval <policy>` | Control when Codex asks for human approval.  Policies include `untrusted`, `on-failure`, `on-request`, and `never`【413965132490193†L233-L287】. |
| `--sandbox <mode>` | Restrict file and network access: `read-only`, `workspace-write` or `danger-full-access`【413965132490193†L418-L427】. |
| `--full-auto` | Shortcut for `--ask-for-approval on-request` and `--sandbox workspace-write`【413965132490193†L246-L364】. |
| `--add-dir <path>` | Grant extra write access to a directory outside the workspace【413965132490193†L231-L274】. |
| `--dangerously-bypass-approvals-and-sandbox` | Disable sandboxing and approvals entirely.  Use only in isolated environments【413965132490193†L316-L325】. |

Codex commands rely heavily on configuration in `~/.codex/config.toml`.  You can define profiles, set default models, choose sandbox modes and specify environment variable filtering【454175575763456†L405-L423】.  For fine‑grained command control, define `.rules` files in `~/.codex/rules` that return `allow`, `prompt` or `forbidden` decisions for matching patterns【40854120253895†L214-L280】.

Although Codex lacks discrete tools, understanding these flags and configuration files is essential for harness integration and controlling agent behaviour.
