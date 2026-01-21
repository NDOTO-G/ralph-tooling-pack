# Best‑Practices Playbook (Claude Code)

This playbook distills guidelines from Anthropic’s documentation and our synthesis work into actionable steps for using Claude Code safely and effectively in a Ralph harness.

## Project preparation

* **Create a `CLAUDE.md` file.** Populate it with high‑level project instructions, coding conventions, style guides and any constraints (e.g. avoid network calls).  Claude loads this file automatically【135116144821332†L48-L90】.  Update it as the project evolves.
* **Define skills via `SKILL.md`.** Place skills in `.claude/skills/<skill-name>/SKILL.md`.  Use YAML front‑matter fields like `description`, `allowed-tools`, `user-invocable`, `disable-model-invocation` and `context` to control when the skill fires【500585924894070†L290-L318】.  Store support files (templates, examples, scripts) alongside the skill【500585924894070†L195-L220】.
* **Pin the allowed tools.** In headless mode, specify `--allowedTools "Read,Edit,Bash"` to auto‑approve a limited set of tools【649120918286103†L161-L173】.  Avoid `--dangerously-skip-permissions` except in disposable environments【135116144821332†L299-L309】.

## Workflow patterns

1. **Explore → Plan → Code → Commit**【135116144821332†L216-L247】:
   * *Explore:* Start with an exploration prompt (e.g., “review the repository and identify high priority tasks”).
   * *Plan:* Ask Claude to propose a task breakdown and acceptance criteria.  Review and edit these tasks manually in a PRD file.
   * *Code:* Provide a prompt instructing Claude to pick the highest priority incomplete task, implement it using permitted tools, run tests, update the PRD and append to a progress log.  Require it to emit `<promise>COMPLETE</promise>` when done.
   * *Commit:* After validation, commit the changes.  Use a separate iteration or plugin to handle git operations so they are explicit in the harness.

2. **Test‑driven development** – Ask Claude to generate failing tests before implementation【135116144821332†L254-L270】.  Run them using a harness script and then instruct Claude to make them pass.
3. **Use think modes strategically.** For complex tasks instruct the model to “think hard” or “ultrathink” but monitor token usage【135116144821332†L234-L239】.  Apply higher budgets only when necessary.
4. **Leverage subagents.** For research or planning phases, run skills with `context: fork` so they operate in a separate subagent and do not pollute the main context【500585924894070†L540-L560】.
5. **Use hooks judiciously.** Configure shell hooks (PreToolUse, PostToolUse, PermissionRequest, etc.) to log tool invocations or enforce policies【995113787448290†L100-L119】.  Keep hook scripts short and deterministic; review them regularly to avoid accidental privilege escalation【995113787448290†L90-L94】.

## Safety and reliability

* **Never run headless mode on untrusted repositories** without a container.  Claude can execute Bash commands; combine `--allowedTools` with sandbox or system‑level restrictions.
* **Review skills and hooks for hidden side effects.** Skills can run arbitrary shell commands via `!`‑prefixed lines【500585924894070†L498-L531】; ensure you trust the content of each skill.
* **Persist progress and artifacts** after each iteration.  Store JSON event streams, diffs, test outputs and commit hashes in an `artifacts/` directory and summarise them in `PROGRESS.md`.
* **Incrementally refine prompts.** Start with simple instructions and gradually add constraints.  When errors occur, adjust the prompt or allowed tools rather than skipping permissions.

Following these practices will help harness Claude’s capabilities without compromising safety or blowing through budgets.