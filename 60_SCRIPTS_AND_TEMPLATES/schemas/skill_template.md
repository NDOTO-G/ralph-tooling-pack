---
name: example-review
description: "Review a pull request or diff and suggest improvements"
user-invocable: true
allowed-tools:
  - Read
  - Grep
  - Edit
disable-model-invocation: false
context: fork
---

## Purpose

This skill reviews a set of code changes and highlights potential issues.  It assumes a diff has been generated and saved to `diff.patch`.  The skill will:

1. Read the contents of `diff.patch`.
2. Identify any coding style violations or performance problems.
3. Suggest improvements and refactoring opportunities.
4. Return a structured report that can be appended to the progress log.

When integrating into your project, place this file under `.opencode/skills/example-review/` or `.claude/skills/example-review/` depending on the engine.  Adjust the tool list and context as appropriate.