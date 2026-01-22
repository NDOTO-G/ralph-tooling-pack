---
name: validate-ralph
description: "Validate completed Ralph agents (Phase 1)"
user-invocable: true
disable-model-invocation: false
allowed-tools:
  - Read
  - Write
  - Bash
  - Grep
---

# Validate Ralph Agent Results (Phase 1)

**Phase 1 Scope:** Validate single agent, no retry logic yet

## Usage

After spawning agents with `/start-ralph`, wait for completion (2-5 minutes), then:

```
/validate-ralph
```

## Instructions for Claude

### Step 1: Load Status

Read `.autoralph/status.json` to get run metadata.

For Phase 1, there should be exactly ONE run.

Extract:
- `work_id`
- `worktree_path`
- `run_dir`
- `branch`

### Step 2: Check Process Completion

Execute:
```bash
./.claude/skills/validate-ralph/scripts/check_completion.sh ${work_id} 1
```

This outputs JSON with `status` field. Parse it.

**Possible statuses:**
- `"running"` - Still executing, need to wait
- `"completed"` - Finished, ready for trials
- `"error"` - Something went wrong

### Step 3: Handle Status

**If "running":**

Show message:
```
⏳ Agent still running

Task ${work_id} is still executing.
Check again in a few minutes with /validate-ralph

Monitor progress:
  tail -f ${run_dir}/events.jsonl
```

STOP here. Do not proceed to trials.

**If "error":**

Show error message and stop.

**If "completed":**

Proceed to Step 4.

### Step 4: Check for Completion Sentinel

Check if the events file contains `<promise>COMPLETE</promise>`:

```bash
grep -q '<promise>COMPLETE</promise>' ${run_dir}/events.jsonl
```

If NOT found:
- Show warning: "Agent completed but did not emit completion marker"
- Ask user if they want to proceed with validation anyway

### Step 5: Check for Commits

Go to worktree and check commit count:

```bash
cd ${worktree_path}
git log --oneline ${base_branch}..HEAD
```

Count commits. If 0:
- Show error: "Agent completed but made no commits"
- This violates the "must commit" requirement
- STOP and request human review

### Step 6: Run Validation Trials

Execute:
```bash
./.claude/skills/validate-ralph/scripts/run_trials.sh ${work_id}
```

This will:
- Enter the worktree
- Run `npm test` (or configured command)
- Write results to `.autoralph/trials/task_${work_id}.md`
- Output "PASSED" or "FAILED"

Capture the output.

### Step 7: Analyze Results

Read `.autoralph/trials/task_${work_id}.md` to see detailed results.

**If PASSED:**

Update status.json:
```json
{
  "runs": {
    "${work_id}": {
      ...existing fields...,
      "state": "passed",
      "completed_at": "${current_timestamp}",
      "exit_code": 0,
      "has_commits": true,
      "validation_passed": true
    }
  },
  "status": "validated"
}
```

Update work_ledger.json:
```json
{
  "tasks": [
    {
      "id": "${work_id}",
      ...existing fields...,
      "status": "complete",
      "validation": {
        "tests_passing": true,
        "linting_passing": true,
        "type_check_passing": true
      },
      "completed_at": "${current_timestamp}"
    }
  ]
}
```

Show success message (Step 8a).

**If FAILED:**

Update status.json with state="failed".

Update work_ledger.json with status="failed".

Show failure message (Step 8b).

### Step 8a: Success Message

```
✅ Validation PASSED - Task ${work_id}

Process Status: Completed
Completion Marker: ✅ Found
Commits: ${commit_count} commits on ${branch}
Duration: ${duration}

Validation Trials:
  ✅ Tests: PASSED

Overall: ✅ PASSED - Ready for merge

See details: .autoralph/trials/task_${work_id}.md

Next: Run /merge-agent to merge this task into dev
```

### Step 8b: Failure Message

```
❌ Validation FAILED - Task ${work_id}

Process Status: Completed
Completion Marker: ${sentinel_status}
Commits: ${commit_count} commits on ${branch}

Validation Trials:
  ❌ Tests: FAILED

Failed tests:
${excerpt_from_trial_file}

Overall: ❌ FAILED - Requires fixes

Phase 1 does not include automatic retry.
You need to manually fix issues or rerun the agent.

See details: .autoralph/trials/task_${work_id}.md
```

## Error Handling

- If status.json doesn't exist → "Run /start-ralph first"
- If no runs to validate → "No runs to validate"
- If trial command fails → log error, show to user

## Notes

This is Phase 1 simplified validation:
- Only validates ONE task
- No automatic retry on failure
- Basic trial execution (just tests)
- Minimal error handling

Phase 2 will add:
- Multiple task validation
- Automatic retry with enhanced prompts
- Linting and type checking
- Better failure analysis
