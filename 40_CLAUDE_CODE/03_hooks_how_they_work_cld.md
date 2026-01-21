# Hooks & Notifications – Claude Code

Claude includes a native **hook system** that lets you run custom shell commands at specific lifecycle events.  This can be used to enforce policies, log activity or run formatters automatically.  Hooks are configured in your `.claude/settings.json` or passed via CLI flags.

## Hook events

Available events include【995113787448290†L100-L119】:

* **PreToolUse** – Fires before a tool call.  Your hook can inspect the tool name and arguments and either allow or block the call.
* **PermissionRequest** – Fires when Claude asks for permission to run a tool.  You can auto‑approve or deny based on custom logic.
* **PostToolUse** – Fires after a tool call completes.  Use this to run formatters or collect outputs.
* **Notification** – Fires when Claude emits a notification (e.g., after a turn).  The payload contains details about the turn and messages.
* **Stop** / **SubagentStop** – Fires when a session or subagent ends.  Good for cleanup or logging.
* **PreCompact** – Fires before context compaction; you can modify the messages that will be compacted.
* **SessionStart** / **SessionEnd** – Fires at session boundaries.

Hooks run arbitrary shell commands and receive a JSON payload on stdin.  Configure them by adding a `hooks` section in your settings file or by specifying a `--hooks` flag (if supported).  For example:

```json
{
  "hooks": {
    "PreToolUse": ["python3", "hooks/pre_tool.py"],
    "Notification": ["bash", "-c", "notify-send 'Claude event'"]
  }
}
```

The scripts receive a JSON object with fields such as `event`, `tool`, `args`, `session_id`, `cwd` and `timestamp`.  They can inspect and mutate the payload (for PreToolUse) or just log it.

## Security considerations

Hooks run with your user privileges and can execute arbitrary code.  Audit hook scripts carefully and avoid including secrets or network operations【995113787448290†L90-L94】.  If possible, run the harness inside a container or VM to isolate any side effects.  Use `--dangerously-skip-permissions` only in controlled environments【135116144821332†L299-L309】.

## Recommended uses

* **Formatter integration** – Run `prettier` or `black` after `Edit` calls via a PostToolUse hook.
* **Command logging** – Log all `Bash` commands with timestamps to aid debugging.
* **Policy enforcement** – Deny dangerous commands (e.g., `rm -rf`) by exiting with a non‑zero status in a PreToolUse hook.
* **Progress logging** – Append an entry to `PROGRESS.md` on SessionEnd containing token usage and summary details.

Hooks complement Ralph’s harness‑level validation: while the harness decides when to run the agent and how to interpret outputs, hooks allow fine‑grained control over what happens inside the session.
