---
name: start-ralph
description: "Start OpenCode agents for Ralph tasks (Phase 1)"
user-invocable: true
disable-model-invocation: true
allowed-tools:
  - Read
  - Write
  - Bash
---

# Start Ralph Multi-Agent Orchestration (Phase 1)

**Phase 1 Scope:** Single agent test with minimal error handling

## Prerequisites

1. OpenCode installed and configured
2. Repository has clean dev branch
3. `.autoralph/config.yaml` exists
4. `.autoralph/work_ledger.json` has at least one pending task
5. Work doc exists for the task

## Usage

```
/start-ralph
```

## Instructions for Claude

### Step 1: Run Preflight Checks

Execute preflight script:
```bash
./.claude/skills/start-ralph/scripts/preflight.sh
```

If it fails, **stop** and show the error message.

### Step 2: Load Configuration and Work Ledger

Read these files:
- `.autoralph/config.yaml` (use grep/sed to extract values if needed)
- `.autoralph/work_ledger.json` (parse with jq if available, or read manually)

Extract:
- `base_branch` (default: "dev")
- `worktree_root` (default: ".autoralph/worktrees")
- First task where `status == "pending"`

### Step 3: Initialize Status File

Create `.autoralph/status.json` if it doesn't exist:

```json
{
  "schema_version": "2.0",
  "created_at": "${current_timestamp}",
  "updated_at": "${current_timestamp}",
  "status": "running",
  "base_branch": "dev",
  "selected_work_items": [],
  "runs": {}
}
```

### Step 4: For the Selected Task

**For Phase 1, we only process ONE task.**

Let's call it `work_id = "001"` (or whatever the first pending task ID is).

#### 4a. Create Worktree

Execute:
```bash
./.claude/skills/start-ralph/scripts/worktree_create.sh ${work_id}
```

This will output the worktree path. Capture it.

#### 4b. Generate Prompt

Read `.autoralph/work_docs/task_${work_id}.md` to get task specification.

Create prompt file at `.autoralph/prompts/task_${work_id}_attempt_1.md`:

```markdown
# OpenCode Agent Instructions - Task ${work_id}

You are an OpenCode agent working in an isolated git worktree to implement this task.

## Task Specification

${paste_content_of_work_doc_here}

## Critical Requirements

1. **You MUST commit your changes** before completing
   - Make atomic commits as you work
   - Use clear commit messages
   - Final commit message should summarize the implementation

2. **Run validation checks in the worktree**
   - After implementation, run: npm test (or the command from work doc)
   - Fix any failures before completing

3. **Output completion marker**
   - When all work is done and tests pass, output exactly:
   - `<promise>COMPLETE</promise>`

4. **Stay in the worktree**
   - Your working directory is: ${worktree_path}
   - Do NOT modify files outside this worktree

5. **Be thorough but concise**
   - Implement according to spec
   - Write tests as specified
   - Do NOT over-engineer or add extra features

## Completion Checklist

Before outputting <promise>COMPLETE</promise>:
- [ ] All files created/modified as specified
- [ ] All tests passing
- [ ] Changes committed to branch ${branch_name}
- [ ] Acceptance criteria met

## Important

This is attempt 1.
You have 10 tool calls available.
Timeout: 30 minutes.

Focus on implementing the specification correctly and completely.
```

#### 4c. Spawn OpenCode Agent

Execute:
```bash
./.claude/skills/start-ralph/scripts/opencode_spawn.sh ${work_id} ${worktree_path} .autoralph/prompts/task_${work_id}_attempt_1.md 1
```

This will output a PID. Capture it.

### Step 5: Update Status File

Update `.autoralph/status.json`:

```json
{
  "schema_version": "2.0",
  "created_at": "${original_timestamp}",
  "updated_at": "${current_timestamp}",
  "status": "running",
  "base_branch": "dev",
  "selected_work_items": [
    {
      "work_id": "${work_id}",
      "title": "${task_title}",
      "priority": ${priority},
      "source_ref": "work_docs/task_${work_id}.md",
      "selected_at": "${current_timestamp}"
    }
  ],
  "runs": {
    "${work_id}": {
      "work_id": "${work_id}",
      "worktree_path": "${worktree_path}",
      "branch": "ralph/task-${work_id}",
      "prompt_path": ".autoralph/prompts/task_${work_id}_attempt_1.md",
      "run_dir": ".autoralph/runs/task-${work_id}/attempt-1",
      "pid": ${pid},
      "tries_used": 1,
      "tries_remaining": 2,
      "state": "running",
      "started_at": "${current_timestamp}"
    }
  },
  "next_actions": ["wait_for_completion", "invoke_validate_ralph"]
}
```

### Step 6: Show Summary

Display to user:

```
✅ Ralph orchestration started (Phase 1)

Selected task:
  • Task ${work_id}: ${title} (priority: ${priority})

Worktree created:
  • ${worktree_path} → ${branch_name}

OpenCode agent spawned:
  • PID: ${pid}
  • Timeout: 30 minutes
  • Max steps: 10

Monitor progress:
  tail -f .autoralph/runs/task-${work_id}/attempt-1/events.jsonl

Check status:
  cat .autoralph/status.json

When the agent completes (2-5 minutes), run:
  /validate-ralph
```

## Error Handling

- If preflight fails → show error, stop
- If no pending tasks → show message "No pending tasks in work ledger"
- If worktree creation fails → show error, stop
- If OpenCode spawn fails → show error, check that OpenCode is installed

## Notes

This is a Phase 1 simplified implementation:
- Only processes ONE task
- Minimal error handling
- No retry logic (yet)
- No heartbeat monitoring (yet)
- Uses direct bash execution

Phase 2 will add parallel execution for multiple tasks.
