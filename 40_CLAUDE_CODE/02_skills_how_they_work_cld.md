# Skills: How They Work (Claude Code)

Claude extends the Agent Skills standard with advanced features such as subagents and dynamic context injection.  Skills are a powerful way to encapsulate instructions but require special handling in headless mode.

## Structure and discovery

* Skills live in `.claude/skills/<name>/` within your project or in `~/.claude/skills/<name>/` in your home directory【500585924894070†L181-L202】.  Nested discovery is supported: if you are in `packages/frontend/`, Claude looks for `packages/frontend/.claude/skills/` as well.【500585924894070†L195-L202】
* A `SKILL.md` file with YAML front‑matter defines the skill.  The front‑matter may include:
  * `description` – text used to match prompts; if omitted, Claude uses the first paragraph of the body【500585924894070†L304-L312】.
  * `disable-model-invocation` – set to `true` to prevent auto‑loading; the skill can only be invoked manually【500585924894070†L398-L404】.
  * `user-invocable` – set to `false` to hide the slash command and allow only Claude to trigger it【500585924894070†L402-L406】.
  * `allowed-tools` – list of tools auto‑approved while the skill runs【500585924894070†L446-L458】.
  * `model` – choose a specific Claude model for the skill.
  * `context` – set to `fork` to run the skill in a new subagent context【500585924894070†L540-L560】.
  * `agent` – type of subagent (e.g., `Explore`, `Plan`, `Code`) when `context: fork` is used【500585924894070†L552-L556】.
* Skills may contain scripts or templates that are executed before or during the skill via `!`-prefixed commands【500585924894070†L498-L531】.

## Invocation and limitations

In interactive mode, you invoke a skill with `/skill-name` or by mentioning `$skill-name`.  In headless mode (`-p`) skills cannot be invoked directly【649120918286103†L193-L195】.  To use a skill in a Ralph loop, you must:

* Extract the relevant instructions from the skill and inline them into your prompt.
* Optionally run the skill in a subagent using the `context: fork` mechanism from another agent (e.g., ask OpenCode to call Claude as a subagent).  This is an advanced pattern.

## Best practices

* **Modularise domain knowledge** – Write skills for repetitive tasks like writing tests, generating API docs or deploying.  Set `disable-model-invocation: true` for destructive tasks so that they are only run intentionally【500585924894070†L398-L404】.
* **Use allowed tools** – Limit the tools a skill may use via `allowed-tools` to improve safety and determinism【500585924894070†L446-L458】.
* **Subagents for isolation** – For complex research or planning, set `context: fork` and specify an `agent` type.  The subagent will operate in a separate context and return results to the parent session【500585924894070†L540-L560】.
* **Dynamic context** – Use `!` shell commands in the skill body to fetch live data (e.g., `!gh pr diff`) before the agent begins reasoning【500585924894070†L498-L531】.

By structuring instructions as skills you can reuse workflows across projects and keep prompts concise, but remember to inline or pre‑load them when running in headless mode.
