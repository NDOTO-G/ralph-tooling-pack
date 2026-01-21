# Hooks & Plugins (OpenCode)

OpenCode provides a **native plugin system** that allows you to hook into its internal events.  This enables pre‑ and post‑processing of tool calls, session lifecycle notifications and context compaction customisation.  In the context of a Ralph harness, plugins let you implement back‑pressure, security policies and logging without modifying the core loop.

## Plugin basics

* A plugin is a JavaScript/TypeScript module placed in `.opencode/plugins/` (project) or `~/.config/opencode/plugins/` (user).  Each plugin must export an async function that receives a context object and returns an object mapping event names to handler functions【543225958782144†L172-L217】.
* The context object contains references to the project, client, bash executor (`$`) and environment.  Event handlers can read and mutate the input arguments and output of tool calls, send notifications or abort actions.
* Plugins are loaded automatically at startup in the following order: global config, project config, global plugins, project plugins【543225958782144†L157-L167】.  No extra CLI flags are needed to enable them.

## Event categories

Key event names include【543225958782144†L271-L336】:

* `tool.execute.before` / `tool.execute.after` – intercept tool calls; mutate arguments or inspect results.  Useful for escaping shell commands or blocking dangerous operations.
* `session.created`, `session.compacted`, `session.idle`, `session.error` – track session lifecycle.  Use these to send notifications or persist context between iterations.
* `permission.updated`, `permission.replied` – handle permission prompts; automatically allow or deny tools.
* `file.edited`, `file.watcher.updated` – monitor file changes during a session.
* `experimental.session.compacting` – customise context summarisation; inject persistent context or override the compaction prompt【543225958782144†L485-L523】.
* Generic `event` – fires on every event; inspect `event.type` to implement catch‑all logic (e.g., notifications).

## Example patterns

* **Notification on session idle** – Use the generic `event` hook to detect `session.idle` and run a command (e.g., `osascript` to display a desktop notification)【543225958782144†L344-L366】.
* **Protect secrets** – In `tool.execute.before`, throw an error if the agent tries to read sensitive files like `.env`【543225958782144†L382-L400】.
* **Escape shell** – Escape or rewrite bash commands before execution to prevent injection attacks【543225958782144†L201-L217】.
* **Compaction injection** – Add key context to the summary using the `experimental.session.compacting` event to ensure important instructions persist across iterations【543225958782144†L485-L523】.

## Harness integration

To use hooks in a Ralph harness:

1. Place plugin files in `.opencode/plugins` and commit them to your repository.  Define dependencies in `.opencode/package.json` if using external modules.
2. Design handlers for pre‑run and post‑run logic.  For example, record start time in `tool.execute.before` and write logs in `session.idle`.
3. Catch exceptions inside your handlers to avoid crashing the loop.  Write any errors to the progress log so you can diagnose issues.
4. Keep your plugins small and focused; avoid making network calls unless necessary.  Hooks run with your credentials and can perform arbitrary side effects【995113787448290†L90-L94】.

Using the plugin system removes the need for harness‑level pre/post wrappers for many tasks, allowing you to concentrate the harness on prompt generation, validation and iteration control.
