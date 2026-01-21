# Sources and References

This pack collates information from official documentation, blog posts and repositories.  Each link below is accompanied by a brief annotation describing its relevance to the research.

## Ralph and harness design

* **Geoff Huntley – Ralph:** <https://ghuntley.com/ralph/> – Introduces the Ralph loop concept and emphasises fresh context, back‑pressure and monolithic orchestration.  Source for definitions and mental models.
* **Snarktank’s Ralph implementation:** <https://github.com/snarktank/ralph> – Provides a working `ralph.sh` script, prompt template and PRD JSON schema.  Used as a concrete example for the loop structure and files.
* **How‑to‑Ralph‑Wiggum playbook:** <https://github.com/ghuntley/how-to-ralph-wiggum> – A comprehensive guide on context engineering, planning phases, back‑pressure and building a robust harness.
* **Shipping at inference speed:** <https://steipete.me/posts/2025/shipping-at-inference-speed> – Blog post discussing advances in large models and the trade‑offs between Opus and Sonnet; informs decisions about model selection and budgeting.

## OpenCode documentation

* **CLI usage:** <https://docs.opencode.ai/cli> – Describes `opencode run`, `serve` and related flags such as `--format json` and `--attach`.  Provides guidance on headless automation and warm sessions.
* **Agent configuration:** <https://docs.opencode.ai/agents> – Details the `maxSteps` parameter and other agent settings for controlling iterations and tool access.
* **Agent skills:** <https://docs.opencode.ai/agent-skills> – Explains how to define skills (`SKILL.md`), how they are discovered and how to invoke them via the `skill` tool.
* **Plugins:** <https://docs.opencode.ai/plugins> – Lists available event hooks (`tool.execute.before`, `session.*`, etc.), load order and examples like notification and environment‑protection plugins.
* **Permissions:** <https://docs.opencode.ai/permissions> – Defines the `permission.tool` patterns (`allow`, `deny`, `ask`) and outlines doom loop and external directory guards.
* **MCP servers:** <https://docs.opencode.ai/mcp> – Describes how to configure Model Context Protocol servers to provide external capabilities and cautions about context size.

## Codex documentation

* **Non‑interactive runs:** <https://developers.openai.com/codex/noninteractive> – Introduces `codex exec`, the `--json` flag, sandbox policies (`--sandbox`) and how to resume sessions.  Source for headless usage patterns.
* **CLI reference:** <https://developers.openai.com/codex/cli/reference> – Enumerates flags such as `--model`, `--oss`, `--ask-for-approval`, `--sandbox` and `--dangerously-bypass-approvals-and-sandbox`.  Defines profiles and configuration precedence.
* **Skills:** <https://developers.openai.com/codex/skills> – Describes skills discovery (multiple scopes), the `SKILL.md` front‑matter and invocation via slash commands or `$` tokens.
* **Rules:** <https://developers.openai.com/codex/rules> – Explains the `.rules` file format and how to define allow/prompt/forbid policies for commands.  Important for permission enforcement.
* **Configuration:** <https://developers.openai.com/codex/configuration> – Documents `config.toml` options including notifications, OpenTelemetry, shell environment policies and history settings.

## Claude Code documentation

* **Programmatic use:** <https://docs.anthropic.com/claude/docs/claude-code-programmatic> – Shows how to run Claude with `-p` headless mode, `--output-format` options, `--allowedTools` and session resumption.  Notes that skills and slash commands are disabled in headless mode.
* **Agentic coding best practices:** <https://docs.anthropic.com/claude/docs/agentic-coding-best-practices> – Recommends an Explore → Plan → Code → Commit workflow, test‑driven development and think modes.
* **Skills:** <https://docs.anthropic.com/claude/docs/skills> – Defines the skill structure, front‑matter fields (`description`, `allowed-tools`, `context`), dynamic context injection via `!` commands and subagent contexts.
* **Hooks:** <https://docs.anthropic.com/claude/docs/hooks> – Lists hook events such as PreToolUse, PostToolUse, PermissionRequest, Notification and PreCompact.  Warns that hooks run arbitrary shell commands and should be audited.

These sources were consulted for definitions, command syntax, API behaviour and best practices.  All factual statements in this pack include citations to specific lines or sections from these documents.