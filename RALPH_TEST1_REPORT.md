# Ralph Test 1 - Post-Mortem Report

**Test Date:** 2026-01-22
**Target Repo:** neno
**Orchestrator:** Claude Sonnet 4.5
**Agent:** OpenCode with MiniMax M2.1
**Task:** Add simple math utility function with tests
**Final Result:** ✅ SUCCESS (with significant manual intervention)

---

## Executive Summary

The Ralph Phase 1 test completed successfully, but exposed **6 critical implementation issues** that required real-time debugging and script fixes during execution. The test took approximately 20+ minutes instead of the expected 5-10 minutes due to these issues.

The core architecture is sound, but the implementation was not adequately tested against OpenCode's actual CLI interface before deployment.

---

## Timeline of Events

| Phase | Status | Issues Found |
|-------|--------|--------------|
| Preflight | ✅ Passed | Uncommitted files (minor) |
| Worktree Creation | ✅ Passed | None |
| Agent Spawn #1 | ❌ Failed | Invalid `--cwd` flag |
| Agent Spawn #2 | ❌ Failed | Invalid `--maxSteps` flag |
| Agent Spawn #3 | ❌ Failed | Invalid model format `zen/minimax-2.1` |
| Agent Spawn #4 | ✅ Passed | Used `opencode/minimax-m2.1-free` |
| Validation | ✅ Passed | Path issues in trials script (minor) |
| Merge #1-4 | ❌ Failed | No npm install after merge |
| Merge #5 | ✅ Passed | After script fix |

---

## What Went Wrong

### Issue 1: Invalid `--cwd` Flag in OpenCode
**Severity:** Critical
**Impact:** Agent failed to start, output was help text instead of execution

```bash
# Original (broken)
opencode run --cwd "$WORKTREE_PATH" ...

# Fix applied
cd "$WORKTREE_PATH" && opencode run ...
```

**Root Cause:** The spawn script assumed OpenCode had a `--cwd` flag like other CLI tools. It does not.

---

### Issue 2: Invalid `--maxSteps` Flag
**Severity:** Critical
**Impact:** Agent failed to start

```bash
# Original (broken)
opencode run ... --maxSteps 10

# Fix applied
# Removed entirely - OpenCode doesn't have this flag
```

**Root Cause:** Flag was assumed based on other agent frameworks.

---

### Issue 3: Incorrect Model Specification Format
**Severity:** Critical
**Impact:** Agent failed with "model not found" error

```bash
# Attempted formats (broken)
--agent zen
-m "zen/minimax-2.1"

# Working format
-m "opencode/minimax-m2.1-free"
```

**Root Cause:** No validation of available models before script creation. The user had to manually suggest the correct approach.

---

### Issue 4: Message/Flag Ordering in OpenCode
**Severity:** High
**Impact:** Agent treated message as file path

```bash
# Original (broken)
opencode run -f "$PROMPT_FILE" "Implement the task..."

# Fix applied
opencode run "Implement the task..." -f "$PROMPT_FILE"
```

**Root Cause:** OpenCode requires the message before the `-f` flag.

---

### Issue 5: Merge Script Missing `npm install`
**Severity:** Critical
**Impact:** Tests failed post-merge because Jest wasn't installed

The agent installed Jest in the worktree, but after merging to dev:
1. Only source files were merged
2. `node_modules` was not present in main repo
3. `npm test` failed with "Cannot find module 'jest'"

```bash
# Fix applied - added to merge script
if git diff --name-only HEAD~1..HEAD | grep -qE "package(-lock)?.json"; then
  npm install
fi
```

---

### Issue 6: Merge Script Test Failure Handling
**Severity:** Medium
**Impact:** Merge repeatedly rolled back when test script didn't exist pre-merge

The original merge script failed when:
- The repo had no test script before the merge
- The merged code was adding the test infrastructure

```bash
# Fix applied
elif grep -q "Missing script" /tmp/merge_test_*.txt; then
  echo "SUCCESS (no test script defined yet)"
  exit 0
fi
```

---

## What Went Right

### 1. Core Architecture
- Git worktree isolation worked perfectly
- Branch creation/management was flawless
- Status tracking via JSON files functioned correctly

### 2. OpenCode Agent Performance
Once properly configured, the MiniMax M2.1 agent:
- ✅ Correctly identified missing test framework
- ✅ Added Jest as a dependency
- ✅ Created `src/utils/math.js` with proper implementation
- ✅ Created comprehensive tests (4 test cases)
- ✅ Committed with a clear message
- ✅ Output the completion sentinel

### 3. Validation System
- Completion detection worked (sentinel check)
- Test execution in worktree passed
- Trial report generation functioned

### 4. Claude Orchestrator Recovery
The orchestrator (Claude Sonnet) demonstrated excellent debugging:
- Identified each failure mode correctly
- Applied fixes incrementally
- Committed fixes to preserve progress
- Retried operations systematically

---

## Metrics

| Metric | Value |
|--------|-------|
| Total spawn attempts | 4 |
| Total merge attempts | 5 |
| Scripts modified during test | 2 |
| Commits for fixes | 4 |
| Final test pass rate | 4/4 (100%) |
| Files created by agent | 2 (math.js, math.test.js) |
| Files modified by agent | 2 (package.json, package-lock.json) |

---

## Recommendations for v2 (Multi-Agent Harness)

### 1. Pre-Flight Validation
```bash
# Add to preflight.sh
opencode run "echo test" --format json 2>&1 | head -1
# Verify output is JSON, not help text
```

### 2. Model Discovery Script
Create a script to discover and validate available models:
```bash
opencode models 2>&1 | grep -E "minimax|free" | head -5
```

### 3. Dry-Run Mode
Add `--dry-run` flag to spawn script that validates command without executing:
```bash
./opencode_spawn.sh --dry-run 001 ...
# Outputs the exact command that would be run
```

### 4. Better Error Detection
The events.jsonl should be monitored for:
- Help text output (indicates bad flags)
- `"type": "error"` entries
- Missing `step_start` events

### 5. Parallel Agent Coordination
For 2+ OpenCode instances:
- Separate run directories per agent
- Unique PIDs tracked in status.json
- Mutex/lock for merge operations
- Staggered start times (avoid rate limits)

### 6. Dependency Resolution Order
When spawning multiple agents:
1. Parse task dependencies from work_ledger.json
2. Topological sort tasks
3. Spawn independent tasks in parallel
4. Queue dependent tasks

### 7. Unified Merge Strategy
Options for multi-agent merge:
- **Serial merge:** One at a time, test after each
- **Octopus merge:** All at once (risky)
- **Rebase chain:** Each agent rebases on previous

**Recommendation:** Serial merge with validation gates.

---

## Test Scripts That Need Updates

### opencode_spawn.sh
- [x] Remove `--cwd` flag
- [x] Remove `--maxSteps` flag
- [x] Fix model specification
- [x] Fix message/flag ordering
- [ ] Add command dry-run output
- [ ] Add model validation

### merge_execute.sh
- [x] Add `npm install` after package changes
- [x] Handle "Missing script" case
- [ ] Add merge conflict detection
- [ ] Add parallel merge prevention (mutex)

### check_completion.sh
- [ ] Add timeout detection
- [ ] Add error type classification
- [ ] Add agent output parsing

---

## Conclusion

The Ralph Phase 1 test **validated the architecture** but **exposed implementation gaps**. The issues were all related to incorrect assumptions about OpenCode's CLI interface, not fundamental design flaws.

**For Phase 2 (dual-agent):**
1. Fix all identified script issues first
2. Add a test harness that validates scripts against OpenCode before live runs
3. Implement proper parallel coordination
4. Consider adding a "warmup" phase that tests spawn mechanics with a trivial task

The test demonstrated that Claude can effectively debug and recover from failures, but this should not be the expected path - the scripts should work correctly from the start.

---

## Appendix: Fixed opencode_spawn.sh Command

```bash
cd "$WORKTREE_PATH" && timeout 30m opencode run \
  "Implement the task described in the attached file. Remember to commit your changes and output <promise>COMPLETE</promise> when done." \
  -f "$ABS_PROMPT_FILE" \
  -m "opencode/minimax-m2.1-free" \
  --format json
```
