# Equivalence Map

The tables below map similar concepts across OpenCode, Codex CLI and Claude Code.  Understanding these equivalences helps design a harness that can translate prompts, permissions and feedback between engines.

## Skills and commands

| Concept | OpenCode | Codex CLI | Claude Code |
|---|---|---|---|
| **Custom task encapsulation** | *Skills* live in `.opencode/skills/<name>` with `SKILL.md`; invoked via the `skill` tool call (e.g., `skill({name: 'review'})`)【474358579328195†L119-L129】. | *Skills* live in `<skill-name>/SKILL.md`; loaded from multiple scopes (project → user → system)【317920800239899†L260-L291】; invoked via `/skill` slash command or `$skillName` token【317920800239899†L213-L259】. | *Skills* live in `.claude/skills/<name>/SKILL.md`【500585924894070†L290-L318】; invoked automatically when `user-invocable` is true but disabled in headless mode【649120918286103†L193-L195】.  In headless runs the harness must inline skill content directly into prompts. |
| **High‑level instructions** | `prompt.md` plus `opencode.json` agent definitions; plans, PRD and progress logs are external. | `prompt.md` passed to `codex exec`; `.rules` files modify approval; PRD and progress logs managed by harness. | `prompt.md` passed via `-f` in headless mode; `CLAUDE.md` file provides context; PRD and progress logs external. |

## Permissions and sandboxing

| Function | OpenCode | Codex CLI | Claude Code |
|---|---|---|---|
| **Allow/deny tool calls** | `permission.tool` in `opencode.json` supports pattern matching and decisions (`allow`, `deny`, `ask`)【474358579328195†L218-L247】. | `--ask-for-approval` flag controls prompting and `.rules` files override per command【413965132490193†L220-L287】. | `--allowedTools` whitelists tools; interactive prompts for everything else【649120918286103†L161-L173】. |
| **Restrict file access** | Doom loop and external directory patterns restrict execution outside the repository【310356558666353†L193-L214】. | `--sandbox read-only`/`workspace-write`/`danger-full-access` determines FS access【413965132490193†L772-L801】; `--add-dir` adds specific writable directories. | Use OS/container sandboxing.  Claude has no built‑in sandbox; rely on headless allowed tools and container isolation. |

## Events and hooks

| Concept | OpenCode | Codex CLI | Claude Code |
|---|---|---|---|
| **Pre‑run interception** | `tool.execute.before` hook modifies commands before they run【543225958782144†L170-L336】. | No hook; wrap `codex exec` in a harness script. | `PreToolUse` hook runs a shell command before a tool call【995113787448290†L100-L119】. |
| **Post‑run logging** | `tool.execute.after`, `session.*` hooks can log results or send notifications【543225958782144†L170-L336】. | `notify` script triggers on `agent-turn-complete` to log or send alerts【454175575763456†L564-L603】. | `PostToolUse`, `Notification` and `SubagentStop` hooks can be configured; events are passed to the hook script【995113787448290†L100-L119】. |
| **Back‑pressure injection** | Compaction hooks (`experimental.session.compacting`) allow injecting context before summarisation【543225958782144†L485-L564】. | None; harness must enforce back‑pressure. | `PreCompact` hook runs before context compaction, allowing injection or alteration of the summary prompt【995113787448290†L100-L119】. |

## Stop conditions and budgets

| Condition | OpenCode | Codex CLI | Claude Code |
|---|---|---|---|
| **Step limit** | `maxSteps` in agent config caps tool calls【559550733105805†L491-L524】. | None; harness must track. | None; harness must track. |
| **Token/timeout budgets** | Environment variables like `OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX` and `OPENCODE_EXPERIMENTAL_BASH_DEFAULT_TIMEOUT_MS` constrain runs【674709478433772†L710-L717】. | None; monitor cost externally. | None; monitor usage via `stream-json` events. |
| **Completion sentinel** | Use sentinel like `<promise>COMPLETE</promise>`; detect in final assistant message. | Same approach; detect sentinel in final message. | Same approach. |

These equivalences help translate a harness design from one tool to another.  For example, a harness that uses OpenCode’s `tool.execute.before` hook to escape Bash commands can map that logic to Claude’s `PreToolUse` hook and to a wrapper script around `codex exec` for Codex.