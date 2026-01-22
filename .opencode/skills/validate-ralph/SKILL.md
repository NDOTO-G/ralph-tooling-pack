---
name: validate-ralph
description: "Validate Ralph iteration artifacts and decide next actions (CONTINUE/RETRY/ESCALATE/COMPLETE)"
user-invocable: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
disable-model-invocation: false
---

# Validate Ralph — Analyze Iteration Results

You are validating the results of a Ralph iteration. Analyze artifacts and determine the next action.

## Step 1: Locate Artifacts

Find the latest iteration artifacts:

```bash
ls -la ralph/artifacts/ 2>/dev/null
ls -la ralph/prompts/ 2>/dev/null
```

Identify the current iteration number from `ralph/progress.md` or file timestamps.

## Step 2: Read Core State

Load these files:
1. `ralph/prd.json` — current PRD state
2. `ralph/progress.md` — iteration history
3. `ralph/config.json` — loop configuration

## Step 3: Parse Iteration Artifacts

For iteration N, check for:
- `ralph/artifacts/iteration_N_events.jsonl` — event stream
- `ralph/artifacts/iteration_N_output.txt` — agent output
- `ralph/artifacts/iteration_N_diff.patch` — changes made
- `ralph/artifacts/iteration_N_tests.txt` — test results

## Step 4: Check Completion Sentinel

Search agent output for completion sentinel:

```
<promise>COMPLETE</promise>
```

Record: `sentinel_found = true/false`

## Step 5: Analyze Test Results

Parse test output for:
- Total tests run
- Tests passed
- Tests failed
- Error messages (if any)

Record: `tests_passed = true/false`

## Step 6: Validate Against Acceptance Criteria

Cross-reference changes (diff) with current story's acceptance criteria:
- Which criteria appear satisfied?
- Which criteria have no evidence of completion?
- Any scope creep (changes outside story scope)?

## Step 7: Make Decision

Apply decision matrix:

| Sentinel | Tests | Criteria | Decision |
|----------|-------|----------|----------|
| YES | PASS | MET | CONTINUE or COMPLETE |
| YES | FAIL | - | RETRY |
| NO | PASS | MET | RETRY (missing sentinel) |
| NO | FAIL | - | RETRY |
| - | - | 3+ failures | ESCALATE |

**CONTINUE**: Story complete, more stories remain in PRD
**COMPLETE**: All stories in PRD have `passes: true`
**RETRY**: Iteration failed, retry with error context (max 3 per story)
**ESCALATE**: Multiple failures, needs human review

## Step 8: Update State

### If CONTINUE:
1. Update PRD: Set current story `passes: true`
2. Append to progress.md:
   ```markdown
   ## <timestamp> — Iteration N
   **Story:** <story_id> - <title>
   **Result:** COMPLETE
   **Summary:** <brief description of changes>
   **Evidence:**
   - Tests: PASS (X/X)
   - Diff: +Y/-Z lines
   - Commit: <hash if available>
   ```
3. Generate next prompt for next story

### If RETRY:
1. Increment failure counter in progress log
2. Generate retry prompt with:
   - Original story requirements
   - Error messages from tests
   - What was attempted
   - Specific guidance to fix

### If ESCALATE:
1. Append escalation entry to progress.md
2. Create `ralph/ESCALATED.md` with:
   - Story that failed
   - Failure history
   - Suggested human actions

### If COMPLETE:
1. Update progress.md with completion summary
2. Create `ralph/READY_TO_MERGE.md`

## Step 9: Output Decision Report

```markdown
# Validation Report — Iteration N

## Status: <DECISION>

### Analysis
- Completion sentinel: <found/not found>
- Tests: <PASS/FAIL> (X passed, Y failed)
- Acceptance criteria: <N/M met>
- Scope check: <clean/scope creep detected>

### Current Story
- ID: <id>
- Title: <title>
- Status: <complete/incomplete>
- Failure count: <N/3>

### PRD Progress
- Stories complete: X/Y
- Current story: <id>
- Remaining: <list>

### Next Action
<description of what happens next>

### Files Updated
- <list of modified files>
```

## Error Handling

- If artifacts missing: Output what's missing, suggest re-running iteration
- If PRD missing: Output error, cannot validate without PRD
- If config missing: Use defaults, warn user
