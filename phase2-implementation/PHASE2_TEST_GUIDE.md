# Ralph Phase 2 - Test Guide

**Goal:** Validate the Ralph multi-agent workflow with TWO tasks running in parallel

## What You'll Test

1. **start-ralph** skill creates 2 worktrees and spawns 2 OpenCode agents in parallel
2. **validate-ralph** skill checks completion of both agents and runs tests
3. **merge-agent** skill merges each validated branch into dev (run twice)

## Prerequisites

### System Requirements

- ✅ Git >= 2.5
- ✅ Node.js >= 18 (with npm)
- ✅ OpenCode installed
- ✅ Claude Code installed
- ✅ jq (for JSON parsing)

### Verify Installation

```bash
git --version
node --version
npm --version
opencode --version
claude --version
jq --version
```

## What's New in Phase 2

### Critical Fixes from Phase 1
1. ✅ Fixed OpenCode command syntax (no `--cwd` or `--maxSteps`)
2. ✅ Correct model format (`anthropic/claude-sonnet-4-5`)
3. ✅ Proper message/flag ordering
4. ✅ Automatic npm install after merge
5. ✅ Graceful handling of missing test scripts

### New Features
1. ✅ Parallel execution of 2 independent tasks
2. ✅ Task selection logic
3. ✅ 5-second stagger between agent starts
4. ✅ Merge mutex (sequential merges)
5. ✅ Support for checking all running agents

## Setup Steps

### 1. Copy Files to Your Test Repo

Copy the entire `phase2-implementation` directory into a test repository:

```bash
# In your test repo
cp -r path/to/phase2-implementation/.claude .
cp -r path/to/phase2-implementation/.autoralph .
cp path/to/phase2-implementation/.gitignore .
```

### 2. Initialize Test Project (if needed)

If you don't have an existing Node.js project:

```bash
# Create package.json
npm init -y

# Install Jest for testing
npm install --save-dev jest

# Add test script to package.json
npm pkg set scripts.test="jest"

# Create src directory
mkdir -p src/utils
```

### 3. Create Dev Branch

```bash
git checkout -b dev
git add .
git commit -m "Initial Ralph setup"
git push -u origin dev
```

### 4. Create TWO Independent Tasks

Edit `.autoralph/work_ledger.json` to have at least 2 independent tasks:

```json
{
  "schema_version": "2.0",
  "tasks": [
    {
      "id": "001",
      "title": "Add math utility functions",
      "status": "pending",
      "priority": 10,
      "dependencies": []
    },
    {
      "id": "002",
      "title": "Add string utility functions",
      "status": "pending",
      "priority": 9,
      "dependencies": []
    }
  ]
}
```

Create corresponding work docs:
- `.autoralph/work_docs/task_001.md`
- `.autoralph/work_docs/task_002.md`

### 5. Customize Config

Edit `.autoralph/config.yaml` to match your project:

```yaml
budgets:
  max_parallel_agents: 2  # Phase 2: run 2 agents
  max_total_time_hours: 4
  max_cost_usd: 20.0

selection:
  count: 2  # Select 2 tasks
  criteria: priority_and_unblocked
  min_priority: 1
  require_independent: true

validate_cmd: npm test
merge_test_cmd: npm test
```

### 6. Make Scripts Executable

```bash
chmod +x .claude/skills/*/scripts/*.sh
```

## Running the Test

### Step 1: Start Claude Interactive Session

```bash
claude
```

### Step 2: Invoke start-ralph

In the Claude prompt:

```
/start-ralph
```

**Expected Output:**

```
✅ Ralph orchestration started (Phase 2)

Selected tasks: 2 task(s)
  • Task 001: Add math utility functions (priority: 10)
  • Task 002: Add string utility functions (priority: 9)

Worktrees created:
  • .autoralph/worktrees/task-001 → ralph/task-001
  • .autoralph/worktrees/task-002 → ralph/task-002

OpenCode agents spawned:
  • Agent 1 - PID: 12345 (Task 001)
  • Agent 2 - PID: 12367 (Task 002)
  • Model: anthropic/claude-sonnet-4-5
  • Timeout: 30 minutes each

Monitor progress:
  tail -f .autoralph/runs/task-001/attempt-1/events.jsonl
  tail -f .autoralph/runs/task-002/attempt-1/events.jsonl

Check status:
  cat .autoralph/status.json

When agents complete (5-10 minutes), run:
  /validate-ralph
```

### Step 3: Monitor Progress (Optional)

In separate terminals:

```bash
# Terminal 1: Watch agent 1
tail -f .autoralph/runs/task-001/attempt-1/events.jsonl | jq .

# Terminal 2: Watch agent 2
tail -f .autoralph/runs/task-002/attempt-1/events.jsonl | jq .

# Terminal 3: Watch both process statuses
watch -n 2 'ps aux | grep opencode'

# Terminal 4: Watch status file
watch -n 5 'cat .autoralph/status.json | jq .'
```

### Step 4: Wait for Completion

Wait 5-10 minutes for BOTH OpenCode agents to:
1. Read their task specs
2. Create files as specified
3. Create tests
4. Run tests
5. Commit changes
6. Output `<promise>COMPLETE</promise>`

**Note:** Agents are staggered by 5 seconds to prevent rate limiting.

### Step 5: Validate Results

In Claude:

```
/validate-ralph
```

**Expected Output (Success):**

```
✅ Validation Results - Phase 2

Task 001: ✅ PASSED
  Process Status: Completed
  Completion Marker: ✅ Found
  Commits: 2 commits on ralph/task-001
  Duration: 4m 15s
  Tests: ✅ PASSED (4/4 tests)

Task 002: ✅ PASSED
  Process Status: Completed
  Completion Marker: ✅ Found
  Commits: 2 commits on ralph/task-002
  Duration: 3m 52s
  Tests: ✅ PASSED (3/3 tests)

Overall: ✅ 2/2 tasks PASSED - Ready for merge

Next: Run /merge-agent twice (once per task) to merge into dev
```

**If One Agent Is Still Running:**

```
⏳ Mixed Status

Task 001: ✅ PASSED
Task 002: ⏳ Still running

Check again in a few minutes with /validate-ralph
```

Wait and try again.

**If Both Failed:**

```
❌ Validation FAILED

Task 001: ❌ FAILED
  [Error details]

Task 002: ❌ FAILED
  [Error details]

Phase 2 does not include automatic retry.
Debug manually in the worktrees.
```

### Step 6: Merge First Task

In Claude:

```
/merge-agent
```

Claude will ask which task to merge. Respond with:

```
Task 001
```

You'll see a merge plan and confirmation prompt.

**Respond:** "Yes, merge now"

**Expected Output (Success):**

```
✅ Merge Complete

Merged Task:
  ✅ Task 001: Add math utility functions

Branch merged: ralph/task-001 → dev
Merge commit: abc123def456
Files changed: 2
Package changes detected: No
Tests: ✅ PASSED

Merge lock acquired: ✅
Merge lock released: ✅

Next: Run /merge-agent again to merge task 002
```

### Step 7: Merge Second Task

In Claude:

```
/merge-agent
```

Respond with:

```
Task 002
```

Confirm the merge plan: "Yes, merge now"

**Expected Output (Success):**

```
✅ Merge Complete

Merged Task:
  ✅ Task 002: Add string utility functions

Branch merged: ralph/task-002 → dev
Merge commit: def456ghi789
Files changed: 2
Package changes detected: No
Tests: ✅ PASSED

Merge lock acquired: ✅
Merge lock released: ✅

Summary:
  - 2 tasks merged successfully
  - Tests passed after both merges
  - Worktrees preserved for inspection
```

### Step 8: Verify Results

```bash
# Check git log
git log --oneline -10

# Show both merge commits
git show HEAD~1
git show HEAD

# Verify files exist
ls -la src/utils/

# Run tests
npm test

# Check both worktrees (should still exist)
ls -la .autoralph/worktrees/
git worktree list
```

## Success Criteria

✅ 2 independent tasks selected
✅ 2 worktrees created successfully
✅ 2 OpenCode agents spawned with 5-second stagger
✅ Both agents completed and committed changes
✅ Both passed validation
✅ First merge acquired lock and succeeded
✅ Second merge waited for lock (if needed) and succeeded
✅ Tests passed after both merges
✅ Git history shows 2 merge commits
✅ No merge conflicts

## Common Issues

### Issue: "No pending independent tasks available"

**Solution:** Ensure work_ledger.json has at least 2 tasks with `dependencies: []`

```bash
# Check your work ledger
cat .autoralph/work_ledger.json | jq '.tasks[] | {id, dependencies}'
```

### Issue: "Merge lock timeout"

**Solution:** Previous merge crashed without releasing lock

```bash
# Manually remove lock
rm -rf .autoralph/merge/.lock

# Try merge again
```

### Issue: One agent succeeds, one fails

**Solution:** This is expected behavior - merge the successful one

```bash
# In Claude
/merge-agent
# Choose the successful task

# Debug failed task manually
cd .autoralph/worktrees/task-00X
npm test
# Fix issues, commit
cd ../..
# Run /validate-ralph again
```

### Issue: "npm install failed" during merge

**Solution:** package.json changes caused dependency issue

```bash
# Check the error
cat .autoralph/merge/test_failure_00X.txt

# Manually fix in worktree
cd .autoralph/worktrees/task-00X
npm install
# Fix package.json if needed
git add package.json
git commit -m "Fix dependencies"
cd ../..

# Try merge again
```

### Issue: Merge conflict between two tasks

**Solution:** Tasks weren't truly independent

```bash
# This shouldn't happen in Phase 2 with proper task selection
# If it does, tasks weren't independent

# Manually resolve
git checkout dev
git merge ralph/task-001  # First merge succeeds
git merge ralph/task-002  # Conflict!
# Resolve conflicts
git add .
git commit
```

### Issue: Second agent never starts

**Solution:** Check first agent spawn didn't fail

```bash
# Check logs
cat .autoralph/runs/task-001/attempt-1/stderr.log
cat .autoralph/runs/task-002/attempt-1/stderr.log

# Check PIDs
ps aux | grep opencode

# Check status file
cat .autoralph/status.json | jq '.runs'
```

## What Gets Created

After successful run:

```
.autoralph/
├── config.yaml (configured for 2 agents)
├── work_ledger.json (both tasks updated with status="merged")
├── work_docs/
│   ├── task_001.md
│   └── task_002.md
├── prompts/
│   ├── task_001_attempt_1.md
│   └── task_002_attempt_1.md
├── runs/
│   ├── task-001/
│   │   └── attempt-1/
│   │       ├── events.jsonl (OpenCode output)
│   │       ├── stdout.log
│   │       ├── stderr.log
│   │       └── pid
│   └── task-002/
│       └── attempt-1/
│           ├── events.jsonl
│           ├── stdout.log
│           ├── stderr.log
│           └── pid
├── trials/
│   ├── task_001.md (validation results)
│   └── task_002.md
├── merge/
│   ├── plan.md (merge plans)
│   └── pre_merge_sha_* (rollback points)
└── worktrees/
    ├── task-001/ (git worktree - preserved)
    └── task-002/ (git worktree - preserved)

src/
└── utils/
    ├── math.js (created by agent 1)
    ├── math.test.js
    ├── string.js (created by agent 2)
    └── string.test.js
```

## Debugging Commands

### Check Agent Status

```bash
# Check if both processes are running
ps aux | grep opencode

# View status of all agents
cat .autoralph/status.json | jq '.runs'

# Check completion for all agents
./.claude/skills/validate-ralph/scripts/check_completion.sh --all
```

### View Agent Output

```bash
# View events from both agents
tail -n 50 .autoralph/runs/task-001/attempt-1/events.jsonl
tail -n 50 .autoralph/runs/task-002/attempt-1/events.jsonl

# Check for errors
grep -i error .autoralph/runs/task-*/attempt-1/stderr.log
```

### Check Merge Lock

```bash
# See if lock exists
ls -la .autoralph/merge/.lock

# Remove stuck lock
rm -rf .autoralph/merge/.lock
```

### Manual Testing in Worktrees

```bash
# Test in first worktree
cd .autoralph/worktrees/task-001
npm test
git log --oneline
cd ../../..

# Test in second worktree
cd .autoralph/worktrees/task-002
npm test
git log --oneline
cd ../../..
```

## Expected Timeline

- **Setup:** 10-15 minutes
- **start-ralph:** < 60 seconds (includes 5-second stagger)
- **Agent 1 execution:** 3-7 minutes
- **Agent 2 execution:** 3-7 minutes (parallel)
- **validate-ralph:** 60-90 seconds
- **merge-agent (first):** 30-60 seconds
- **merge-agent (second):** 30-60 seconds
- **Total:** ~20-30 minutes end-to-end

## Phase 2 vs Phase 1 Differences

| Aspect | Phase 1 | Phase 2 |
|--------|---------|---------|
| **Parallel Agents** | 1 | 2 |
| **Task Selection** | Manual | Automatic (`task_selector.sh`) |
| **OpenCode Command** | ❌ Broken | ✅ Fixed |
| **Agent Stagger** | N/A | 5 seconds |
| **Merge Mutex** | No | Yes |
| **npm install** | No | Yes (automatic) |
| **Test Script Handling** | Basic | Graceful fallback |
| **Timeline** | ~10 min | ~20-30 min |

## Success Message

When everything works, you should see:

✅ Created 2 worktrees and branches
✅ Spawned 2 OpenCode agents with stagger
✅ Both agents implemented features and committed
✅ Both validations passed
✅ First merge succeeded with lock
✅ Second merge succeeded with lock
✅ Tests pass on dev branch after both merges
✅ No merge conflicts

**Congratulations! Ralph Phase 2 is working!** 🎉

You can now:
- Scale to more parallel tasks (3-4 agents)
- Test with real work items from your projects
- Add production features (retry, monitoring, cost tracking)

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `/start-ralph` | Select 2 tasks and spawn 2 agents |
| `/validate-ralph` | Check completion of both agents |
| `/merge-agent` | Merge validated branch (run twice) |
| `tail -f .autoralph/runs/task-*/attempt-*/events.jsonl` | Monitor agents |
| `git worktree list` | List all worktrees |
| `ps aux \| grep opencode` | Check running processes |
| `cat .autoralph/status.json \| jq .` | View state |
| `ls .autoralph/merge/.lock` | Check merge lock |
| `./.claude/skills/validate-ralph/scripts/check_completion.sh --all` | Check all agents |

## Troubleshooting Checklist

Before asking for help:

1. ✅ Both tasks have `dependencies: []` in work_ledger.json
2. ✅ Config has `max_parallel_agents: 2` and `selection.count: 2`
3. ✅ Scripts are executable (`chmod +x .claude/skills/*/scripts/*.sh`)
4. ✅ Dev branch exists and is clean
5. ✅ OpenCode is installed and in PATH
6. ✅ Both worktrees were created
7. ✅ Both PIDs are in status.json
8. ✅ events.jsonl files exist for both agents
9. ✅ No merge lock is stuck (`.autoralph/merge/.lock` doesn't exist)
10. ✅ Tests pass in both worktrees

Good luck with Phase 2 testing! 🚀
