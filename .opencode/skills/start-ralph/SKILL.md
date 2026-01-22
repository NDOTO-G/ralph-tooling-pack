---
name: start-ralph
description: "Initialize a new Ralph loop by selecting top priority stories and generating prompt files"
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
disable-model-invocation: false
---

# Start Ralph — Initialize New Loop

You are initializing a new Ralph loop. Follow these steps precisely.

## Inputs

Check for these input sources in order:
1. `backlog.json` or `issues.json` in current directory
2. `TODO.md` or `BACKLOG.md` in current directory
3. GitHub issues via `gh issue list --json number,title,body,labels`
4. User-provided inline tasks

## Step 1: Read and Parse Backlog

```bash
# Check for backlog files
ls -la *.json *.md 2>/dev/null | head -20
```

Read available backlog sources. Parse into normalized format:
```json
{
  "id": "string",
  "title": "string",
  "description": "string",
  "priority": "number (1-10, higher = more important)",
  "labels": ["array", "of", "labels"],
  "acceptance_criteria": ["array", "of", "criteria"]
}
```

## Step 2: Score and Select Top 3

Apply scoring algorithm:
- **Priority weight**: base priority × 2
- **Complexity penalty**: -1 for each "complex" or "large" label
- **Dependency boost**: +2 if other items depend on this
- **Quick win boost**: +3 for items with "quick-win" or "low-effort" labels

Select top 3 by score. If fewer than 3 items exist, use all available.

## Step 3: Generate PRD

Create `ralph/prd.json`:

```json
{
  "branch": "ralph/<timestamp>",
  "created_at": "<ISO timestamp>",
  "max_iterations": 15,
  "stories": [
    {
      "id": "1",
      "title": "<from backlog>",
      "priority": 10,
      "acceptance_criteria": [
        "<criterion 1>",
        "<criterion 2>"
      ],
      "passes": false
    }
  ]
}
```

## Step 4: Generate First Prompt

Create `ralph/prompts/iteration_1.md`:

```markdown
# Ralph Iteration 1

## Current Story
**ID:** <story_id>
**Title:** <story_title>

## Acceptance Criteria
<list criteria>

## Instructions
1. Implement the feature/fix described above
2. Ensure all acceptance criteria are met
3. Run tests: `npm test` or appropriate test command
4. If tests pass, output: <promise>COMPLETE</promise>
5. If tests fail, output the error and stop

## Constraints
- Make minimal changes necessary
- Do not refactor unrelated code
- Do not add features beyond scope
```

## Step 5: Initialize Progress Log

Create `ralph/progress.md`:

```markdown
# Ralph Progress Log

## Session Info
- **Started:** <timestamp>
- **Branch:** ralph/<timestamp>
- **Stories:** <count>

---

## Iterations

(No iterations yet)
```

## Step 6: Create Config

Create `ralph/config.json`:

```json
{
  "max_iterations": 15,
  "max_failures_per_story": 3,
  "test_command": "npm test",
  "lint_command": "npm run lint",
  "completion_sentinel": "<promise>COMPLETE</promise>",
  "created_at": "<timestamp>"
}
```

## Step 7: Output Summary

After creating all files, output:

```
Ralph loop initialized successfully!

Stories selected:
1. [HIGH] <title 1>
2. [MED]  <title 2>
3. [LOW]  <title 3>

Files created:
- ralph/prd.json
- ralph/prompts/iteration_1.md
- ralph/progress.md
- ralph/config.json

Next: Run iteration 1 or use /ralph-auto MODE=ITERATE
```

## Error Handling

- If no backlog found: Ask user to provide tasks inline
- If backlog empty: Output error and stop
- If write fails: Output error with path and stop
