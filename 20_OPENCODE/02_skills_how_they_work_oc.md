# Skills: How They Work (OpenCode)

OpenCode implements the Agent Skills standard to allow reusable workflows.  A **skill** is a small package of instructions (often accompanied by scripts or templates) that the agent can load on demand via the `skill` tool.

## Structure and discovery

* Each skill lives in a directory named after the skill.  The directory must contain a `SKILL.md` file with YAML front‑matter and markdown instructions.  Optional subdirectories (`scripts/`, `assets/`, `templates/`) may provide extra resources.
* Skills are discovered in two main locations: `.opencode/skills/` in the project and `~/.config/opencode/skills/` in the user’s home directory【474358579328195†L96-L105】.  OpenCode walks up to the git worktree root and loads any skills it finds【474358579328195†L110-L115】.  Skills in your project override identically named skills in the global directory.
* The YAML front‑matter must include a `name` and `description`.  Optional fields include `license`, `compatibility` (e.g., `opencode` or `claude`) and arbitrary `metadata`【474358579328195†L119-L146】.  Names must match the directory name and follow lowercase alphanumeric patterns with hyphens.

## Invocation

The agent calls a skill by name using the `skill` tool.  For example:

```
skill({ name: "git-release" })
```

This returns the skill’s instructions, which the agent can then follow to perform the task (e.g., drafting release notes).  You can view available skills in the `skill` tool description; each entry lists its name and description【474358579328195†L195-L210】.

## Permissions

Skill usage is governed by the `permission.skill` section of `opencode.json`.  Pattern rules decide whether a skill is `allow`ed, `deny`ed or `ask`ed.  Wildcards (e.g., `experimental-*`) make it easy to prompt before running experimental skills【474358579328195†L218-L247】.  Agents can override these settings in their own front‑matter.

You can completely disable skills for an agent by setting `tools.skill: false` in the agent configuration【474358579328195†L295-L327】.

## Role in a Ralph harness

* **Modularity** – Use skills to encapsulate repetitive processes such as planning, code review, validation or deployment.  This keeps prompts concise and enables reuse across projects.
* **Context management** – Skills are loaded only when invoked, so their instructions do not pollute the main context until needed.
* **Safety** – Restrict which skills the agent may call automatically.  For high‑impact tasks, set the permission to `ask` or `deny` and require human approval.

By designing a library of skills for your domain, you can dramatically improve the reliability and maintainability of your Ralph harness with OpenCode.
