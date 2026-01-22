# Ralph Phase 1 - Test Guide

> **⚠️ OUTDATED:** This guide is for the original Phase 1 implementation with known issues.
>
> **For Phase 2 with all fixes, see [PHASE2_TEST_GUIDE.md](PHASE2_TEST_GUIDE.md)**
>
> Phase 1 had 6 critical issues that are now fixed in Phase 2. This guide is kept for historical reference.

---

**Goal:** Validate the entire Ralph multi-agent workflow with ONE simple task

## What You'll Test

1. **start-ralph** skill creates worktree and spawns OpenCode agent
2. **validate-ralph** skill checks completion and runs tests
3. **merge-agent** skill merges the validated branch into dev

## Prerequisites

### System Requirements

- ✅ Git >= 2.5
- ✅ Node.js >= 18 (with npm)
- ✅ OpenCode installed
- ✅ Claude Code installed

### Verify Installation

```bash
git --version
node --version
npm --version
opencode --version
claude --version
```

## Setup Steps

### 1. Copy Files to Your Test Repo

Copy the entire `phase1-implementation` directory into a test repository:

```bash
# In your test repo
cp -r path/to/phase1-implementation/.claude .
cp -r path/to/phase1-implementation/.autoralph .
cp path/to/phase1-implementation/.gitignore .
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
git push -u origin dev
```

### 4. Customize Config

Edit `.autoralph/config.yaml` to match your project:

```yaml
validate_cmd: npm test  # or your test command
merge_test_cmd: npm test
```

### 5. Make Scripts Executable

```bash
chmod +x .claude/skills/*/scripts/*.sh
```

## Running the Test

### Step 1: Start OpenCode Server (Optional but Recommended)

In a separate terminal:

```bash
opencode serve --port 4096
```

If using the server, uncomment this line in `.autoralph/config.yaml`:
```yaml
attach_url: http://localhost:4096
```

### Step 2: Start Claude Interactive Session

```bash
claude
```

### Step 3: Invoke start-ralph

In the Claude prompt:

```
/start-ralph
```

**Expected Output:**

```
✅ Ralph orchestration started (Phase 1)

Selected task:
  • Task 001: Add simple utility function (priority: 10)

Worktree created:
  • .autoralph/worktrees/task-001 → ralph/task-001

OpenCode agent spawned:
  • PID: 12345
  • Timeout: 30 minutes
  • Max steps: 10

Monitor progress:
  tail -f .autoralph/runs/task-001/attempt-1/events.jsonl

When the agent completes (2-5 minutes), run:
  /validate-ralph
```

### Step 4: Monitor Progress (Optional)

In another terminal:

```bash
# Watch the OpenCode output
tail -f .autoralph/runs/task-001/attempt-1/events.jsonl | jq .

# Or watch process status
watch -n 2 'ps aux | grep opencode'

# Or check status file
watch -n 5 'cat .autoralph/status.json | jq .'
```

### Step 5: Wait for Completion

Wait 2-5 minutes for the OpenCode agent to:
1. Read the task spec
2. Create `src/utils/math.js`
3. Create `src/utils/math.test.js`
4. Run tests
5. Commit changes
6. Output `<promise>COMPLETE</promise>`

### Step 6: Validate Results

In Claude:

```
/validate-ralph
```

**Expected Output (Success):**

```
✅ Validation PASSED - Task 001

Process Status: Completed
Completion Marker: ✅ Found
Commits: 2 commits on ralph/task-001
Duration: 3m 45s

Validation Trials:
  ✅ Tests: PASSED (4/4 tests)

Overall: ✅ PASSED - Ready for merge

See details: .autoralph/trials/task_001.md

Next: Run /merge-agent to merge this task into dev
```

**If Still Running:**

```
⏳ Agent still running

Task 001 is still executing.
Check again in a few minutes with /validate-ralph
```

Wait and try again.

**If Failed:**

```
❌ Validation FAILED - Task 001

Validation Trials:
  ❌ Tests: FAILED

[Error details shown]

Phase 1 does not include automatic retry.
```

Debug manually in the worktree.

### Step 7: Merge Changes

In Claude:

```
/merge-agent
```

You'll see a merge plan and confirmation prompt.

**Respond:** "Yes, merge now"

**Expected Output (Success):**

```
✅ Merge Complete (Phase 1)

Merged Task:
  ✅ Task 001: Add simple utility function

Branch merged: ralph/task-001 → dev
Merge commit: abc123def456
Files changed: 2
Tests: ✅ PASSED

Summary:
  - 1 task merged successfully
  - Tests passed after merge
  - Worktree preserved for inspection

Next Steps:
  - Review changes: git show HEAD
  - Push to remote: git push origin dev
```

### Step 8: Verify Results

```bash
# Check git log
git log --oneline -5

# Show merged changes
git show HEAD

# Verify files exist
ls -la src/utils/

# Run tests
npm test

# Check worktree (should still exist)
ls -la .autoralph/worktrees/task-001/
```

## Success Criteria

✅ All 3 skills executed without errors
✅ Worktree created successfully
✅ OpenCode agent completed and committed changes
✅ Tests passed in worktree
✅ Merge succeeded
✅ Tests passed after merge
✅ Git history shows merge commit

## Common Issues

### Issue: "opencode: command not found"

**Solution:** Install OpenCode or add to PATH

```bash
# Check installation
which opencode

# Install if missing
# Visit: https://opencode.ai
```

### Issue: "Repository has uncommitted changes"

**Solution:** Commit or stash changes

```bash
git status
git add .
git commit -m "Checkpoint before Ralph test"
```

### Issue: "dev branch does not exist"

**Solution:** Create dev branch

```bash
git checkout -b dev
git push -u origin dev
```

### Issue: Agent takes too long or seems stuck

**Solution:** Check the output file

```bash
tail -100 .autoralph/runs/task-001/attempt-1/events.jsonl
```

Look for errors or permission prompts.

### Issue: Tests fail in validation

**Solution:** Debug in the worktree

```bash
cd .autoralph/worktrees/task-001
npm test
# Fix issues
git add .
git commit -m "Fix tests"
cd ../..
# Run /validate-ralph again
```

### Issue: Merge conflict

**Solution:** Resolve manually

```bash
git checkout dev
git merge ralph/task-001
# Resolve conflicts
git add .
git commit
# Update work_ledger.json manually
```

## What Gets Created

After successful run:

```
.autoralph/
├── config.yaml (configured)
├── work_ledger.json (updated with status="merged")
├── work_docs/
│   └── task_001.md
├── prompts/
│   └── task_001_attempt_1.md (generated prompt)
├── runs/
│   └── task-001/
│       └── attempt-1/
│           ├── events.jsonl (OpenCode output)
│           ├── stdout.log
│           ├── stderr.log
│           └── pid
├── trials/
│   └── task_001.md (validation results)
├── merge/
│   └── plan.md (merge plan)
└── worktrees/
    └── task-001/ (git worktree - preserved)

src/
└── utils/
    ├── math.js (created by agent)
    └── math.test.js (created by agent)
```

## Next Steps After Phase 1

Once Phase 1 works successfully:

### Phase 2: Two Tasks in Parallel

1. Add another task to work_ledger.json
2. Update config: `max_parallel_agents: 2`, `count: 2`
3. Test with 2 independent tasks
4. Verify both agents run simultaneously
5. Validate and merge both

### Phase 3: Complex Tasks

1. Test with tasks that have dependencies
2. Test with tasks that modify same files (conflict detection)
3. Test retry logic (manually trigger failures)
4. Stress test with 3-4 parallel agents

### Phase 4: Production Features

1. Add heartbeat monitoring
2. Implement automatic retry with error context
3. Add cost tracking
4. Build monitoring dashboard
5. Integrate with CI/CD

## Troubleshooting Commands

```bash
# Check if OpenCode process is running
ps aux | grep opencode

# Kill stuck process
kill <PID>

# Remove worktree manually
git worktree remove .autoralph/worktrees/task-001

# Delete branch manually
git branch -D ralph/task-001

# Reset to clean state
rm -rf .autoralph/worktrees
rm -rf .autoralph/runs
rm -rf .autoralph/trials
rm -rf .autoralph/merge
```

## Getting Help

If you encounter issues:

1. Check logs in `.autoralph/runs/task-001/attempt-1/`
2. Review status.json for agent state
3. Manually test OpenCode command:
   ```bash
   opencode run -f .autoralph/prompts/task_001_attempt_1.md --format json
   ```
4. Verify git worktree:
   ```bash
   git worktree list
   ```

## Expected Timeline

- **Setup:** 5-10 minutes
- **start-ralph:** < 30 seconds
- **Agent execution:** 2-5 minutes
- **validate-ralph:** 30-60 seconds
- **merge-agent:** 30-60 seconds
- **Total:** ~10 minutes end-to-end

## Success Message

When everything works, you should see:

✅ Created worktree and branch
✅ Spawned OpenCode agent
✅ Agent implemented feature and committed
✅ Validation passed
✅ Merge succeeded
✅ Tests pass on dev branch

**Congratulations! Ralph Phase 1 is working!** 🎉

You can now:
- Scale to multiple parallel tasks (Phase 2)
- Test with real work items from your projects
- Add production features (retry, monitoring, cost tracking)

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `/start-ralph` | Select tasks and spawn agents |
| `/validate-ralph` | Check completion and run trials |
| `/merge-agent` | Merge validated branches |
| `tail -f .autoralph/runs/*/attempt-*/events.jsonl` | Monitor agent |
| `git worktree list` | List all worktrees |
| `ps aux \| grep opencode` | Check running processes |
| `cat .autoralph/status.json \| jq .` | View state |

Good luck with your test! 🚀
