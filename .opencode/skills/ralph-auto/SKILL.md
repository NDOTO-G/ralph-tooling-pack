---
name: ralph-auto
description: "Autonomous Ralph loop runner for unattended execution via external orchestration"
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - skill
disable-model-invocation: false
---

# Ralph Auto — Autonomous Loop Runner

You are the autonomous runner for Ralph loops. You orchestrate the full lifecycle based on the MODE parameter.

## Mode Detection

Parse the user's message for MODE. Valid modes:
- `MODE=INIT` — Start new Ralph loop
- `MODE=ITERATE` — Run next iteration
- `MODE=VALIDATE` — Validate last iteration
- `MODE=FINALIZE` — Complete and prepare merge
- `MODE=STATUS` — Report current state without changes

Default to `MODE=STATUS` if not specified.

---

## MODE=INIT

Initialize a new Ralph loop.

### Steps:
1. Check if `ralph/` directory exists
   - If exists and has active work: Output error, suggest cleanup or resume
   - If exists but stale: Archive to `ralph-archive-<timestamp>/`

2. Invoke start-ralph skill logic:
   - Look for backlog sources
   - Select top 3 stories
   - Generate PRD, first prompt, progress log, config

3. Output structured response:
```json
{
  "status": "initialized",
  "mode": "INIT",
  "stories_selected": 3,
  "next_mode": "ITERATE",
  "files_created": [
    "ralph/prd.json",
    "ralph/prompts/iteration_1.md",
    "ralph/progress.md",
    "ralph/config.json"
  ],
  "message": "Ralph loop initialized. Ready for first iteration."
}
```

---

## MODE=ITERATE

Execute the next iteration of the loop.

### Steps:
1. Load state:
   - Read `ralph/prd.json`
   - Read `ralph/progress.md`
   - Read `ralph/config.json`

2. Determine current iteration:
   - Count completed iterations in progress.md
   - Current = count + 1

3. Find current story:
   - First story in PRD with `passes: false`
   - If none found: Output that all stories complete, suggest MODE=FINALIZE

4. Read iteration prompt:
   - `ralph/prompts/iteration_<N>.md`
   - If missing: Generate from PRD story

5. Execute the story:
   - Follow the prompt instructions exactly
   - Make code changes as specified
   - Run tests as configured
   - Capture all output

6. Save artifacts:
   - `ralph/artifacts/iteration_<N>_output.txt` — your full output
   - `ralph/artifacts/iteration_<N>_diff.patch` — changes made
   - `ralph/artifacts/iteration_<N>_tests.txt` — test results

7. Check completion:
   - Did tests pass?
   - Output completion sentinel if successful: `<promise>COMPLETE</promise>`

8. Output structured response:
```json
{
  "status": "iteration_complete",
  "mode": "ITERATE",
  "iteration": N,
  "story_id": "<id>",
  "story_title": "<title>",
  "tests_passed": true,
  "sentinel_output": true,
  "next_mode": "VALIDATE",
  "artifacts": [
    "ralph/artifacts/iteration_N_output.txt",
    "ralph/artifacts/iteration_N_diff.patch",
    "ralph/artifacts/iteration_N_tests.txt"
  ],
  "message": "Iteration N complete. Run MODE=VALIDATE to check results."
}
```

---

## MODE=VALIDATE

Validate the last iteration and decide next action.

### Steps:
1. Invoke validate-ralph skill logic:
   - Parse artifacts
   - Check sentinel
   - Check tests
   - Validate against criteria

2. Get decision: CONTINUE | RETRY | ESCALATE | COMPLETE

3. Take action based on decision:

   **CONTINUE:**
   - Update PRD (mark story complete)
   - Generate next iteration prompt
   - Set next_mode = "ITERATE"

   **RETRY:**
   - Increment failure counter
   - Generate retry prompt with errors
   - Set next_mode = "ITERATE"

   **ESCALATE:**
   - Create ESCALATED.md
   - Set next_mode = "PAUSE"

   **COMPLETE:**
   - Create READY_TO_MERGE.md
   - Set next_mode = "FINALIZE"

4. Output structured response:
```json
{
  "status": "validated",
  "mode": "VALIDATE",
  "decision": "<CONTINUE|RETRY|ESCALATE|COMPLETE>",
  "iteration": N,
  "story_id": "<id>",
  "tests_passed": true,
  "stories_complete": "X/Y",
  "failure_count": 0,
  "next_mode": "<next>",
  "message": "<human readable status>"
}
```

---

## MODE=FINALIZE

Complete the Ralph loop and prepare for merge.

### Steps:
1. Verify completion:
   - All stories in PRD have `passes: true`
   - `ralph/READY_TO_MERGE.md` exists

2. Invoke merge-agent skill logic:
   - Run all risk checks
   - Generate risk report

3. Take action based on risk assessment:
   - APPROVED: Create PR
   - NEEDS_REVIEW: Create draft PR
   - BLOCKED: Report blockers

4. Output structured response:
```json
{
  "status": "finalized",
  "mode": "FINALIZE",
  "merge_decision": "<APPROVED|NEEDS_REVIEW|BLOCKED>",
  "risk_level": "<LOW|MEDIUM|HIGH|CRITICAL>",
  "pr_url": "<url if created>",
  "blockers": [],
  "warnings": [],
  "message": "<final status message>"
}
```

---

## MODE=STATUS

Report current state without making changes.

### Steps:
1. Check if `ralph/` exists
2. If not: Report no active loop
3. If yes: Read and summarize state

4. Output structured response:
```json
{
  "status": "reporting",
  "mode": "STATUS",
  "active_loop": true,
  "current_iteration": N,
  "stories_total": Y,
  "stories_complete": X,
  "current_story": {
    "id": "<id>",
    "title": "<title>",
    "failure_count": 0
  },
  "last_decision": "<from progress log>",
  "suggested_next_mode": "<ITERATE|VALIDATE|FINALIZE>",
  "message": "Ralph loop in progress. X/Y stories complete."
}
```

---

## Error Handling

All errors should output:
```json
{
  "status": "error",
  "mode": "<attempted mode>",
  "error": "<error message>",
  "recoverable": true,
  "suggested_action": "<what to do>",
  "message": "Error: <human readable>"
}
```

Common errors:
- No backlog found (INIT): Ask user to provide tasks
- No ralph/ directory (non-INIT): Suggest MODE=INIT first
- Tests won't run: Check test command in config
- Max iterations reached: Force FINALIZE or ESCALATE

---

## Orchestration Integration

External harness should call like:
```bash
# Initialize
opencode run -p "/ralph-auto MODE=INIT"

# Loop until done
while true; do
  opencode run -p "/ralph-auto MODE=ITERATE"
  result=$(opencode run -p "/ralph-auto MODE=VALIDATE")

  next_mode=$(echo $result | jq -r '.next_mode')

  if [ "$next_mode" = "FINALIZE" ]; then
    opencode run -p "/ralph-auto MODE=FINALIZE"
    break
  elif [ "$next_mode" = "PAUSE" ]; then
    echo "Escalated - human intervention needed"
    break
  fi
done
```

---

## Safety Guards

1. **Max iterations**: Stop after config.max_iterations (default 15)
2. **Max failures**: Escalate after config.max_failures_per_story (default 3)
3. **Stale detection**: Warn if last activity > 1 hour ago
4. **Scope check**: Warn if diff exceeds reasonable size

Always output JSON for machine parsing by orchestrator.
