---
name: merge-agent
description: "Merge validated Ralph branches (Phase 1)"
user-invocable: true
disable-model-invocation: false
allowed-tools:
  - Read
  - Write
  - Bash
  - Grep
---

# Merge Ralph Agent Results (Phase 1)

**Phase 1 Scope:** Merge single validated branch with basic conflict handling

## Prerequisites

- Task has been validated and state="passed"
- Dev branch is clean
- No uncommitted changes

## Usage

After validation passes:

```
/merge-agent
```

## Instructions for Claude

### Step 1: Verify Preconditions

Read `.autoralph/status.json`.

Check:
1. At least ONE run has `state="passed"`
2. No runs have `state="running"` or `state="retrying"`

If any check fails, **stop** and show:
```
Cannot merge yet:
  - ${reason}

Run /validate-ralph first to check validation status.
```

Check git status:
```bash
git status --porcelain
```

If output is not empty:
```
Repository has uncommitted changes. Please commit or stash them first.
```

STOP.

### Step 2: Generate Merge Plan

For Phase 1, the merge plan is simple (only one branch).

Read the run metadata from status.json to get:
- `work_id`
- `branch` (e.g., "ralph/task-001")
- `worktree_path`

Analyze what files changed:
```bash
git diff --name-only dev...${branch}
```

Count changes:
```bash
git diff --stat dev...${branch}
```

Create `.autoralph/merge/plan.md`:

```markdown
# Merge Plan (Phase 1)

**Generated:** ${timestamp}
**Base Branch:** dev
**Current Commit:** ${git_rev_parse_HEAD}

## Task to Merge

| Work ID | Title | Branch | Files Changed |
|---------|-------|--------|---------------|
| ${work_id} | ${title} | ${branch} | ${file_count} |

## Changed Files

${list_of_changed_files}

## Statistics

${git_diff_stat}

## Strategy

Phase 1 simple merge:
1. Checkout dev
2. Merge ${branch} with --no-ff
3. Run npm test
4. If success: keep merge
5. If failure: rollback (git reset --hard)

## Rollback Plan

Pre-merge commit saved. On failure:
```bash
git reset --hard ${pre_merge_sha}
```
```

### Step 3: Show Plan

Read the plan you just created and summarize for user:

```
Merge Plan Generated
━━━━━━━━━━━━━━━━━━━━

Task: ${work_id} - ${title}
Branch: ${branch}
Files changed: ${count}

Changed files:
${first_10_files}

Strategy: Merge into dev with --no-ff, then run tests

Plan saved: .autoralph/merge/plan.md

Ready to proceed? (yes/no)
```

Use the AskUserQuestion tool to get confirmation:

```
question: "Proceed with merge?"
options:
  - label: "Yes, merge now"
    description: "Merge the branch into dev and run tests"
  - label: "No, cancel"
    description: "Stop without merging"
```

If user says "No" → STOP and show "Merge cancelled by user"

### Step 4: Execute Merge

Execute:
```bash
./.claude/skills/merge-agent/scripts/merge_execute.sh ${branch}
```

This script will:
1. Record pre-merge SHA
2. Checkout dev
3. Merge the branch
4. Run npm test
5. Return "SUCCESS", "CONFLICT", or "TEST_FAILED"

Capture the output.

### Step 5: Handle Merge Result

**If "SUCCESS":**

Proceed to Step 6 (success path).

**If "CONFLICT":**

Create `.autoralph/merge/failure.md`:

```markdown
# Merge Failure: Conflict

**Timestamp:** ${timestamp}
**Task:** ${work_id}
**Branch:** ${branch}

## Conflict Details

Git merge resulted in conflicts. The merge was aborted.

Conflicting files:
${list_conflicts_if_available}

## Resolution Steps

1. Manually merge the branch:
   ```bash
   git checkout dev
   git merge ${branch}
   ```

2. Resolve conflicts in the files

3. After resolving:
   ```bash
   git add .
   git commit
   ```

4. Update work_ledger.json to mark task as "merged"

5. Clean up worktree:
   ```bash
   git worktree remove ${worktree_path}
   ```

## Branch Preserved

The branch ${branch} and worktree ${worktree_path} have been preserved for debugging.
```

Show error message:
```
❌ Merge Failed: Conflict

The merge resulted in conflicts. See details:
  .autoralph/merge/failure.md

The branch and worktree have been preserved for manual resolution.

To resolve manually:
  1. git checkout dev
  2. git merge ${branch}
  3. Fix conflicts
  4. git commit
  5. Update work_ledger.json
```

STOP.

**If "TEST_FAILED":**

Create `.autoralph/merge/failure.md`:

```markdown
# Merge Failure: Tests Failed

**Timestamp:** ${timestamp}
**Task:** ${work_id}
**Branch:** ${branch}

## Failure Details

Branch was merged successfully, but tests failed.
The merge has been rolled back.

## Test Output

${excerpt_of_test_failures}

## Recovery

Dev branch has been restored to: ${pre_merge_sha}

The worktree and branch are preserved for investigation.

## Next Steps

1. Investigate test failures in worktree:
   ```bash
   cd ${worktree_path}
   npm test
   ```

2. Fix issues

3. Revalidate: /validate-ralph

4. Retry merge: /merge-agent
```

Show error message:
```
❌ Merge Failed: Tests Failed

The merge succeeded but tests failed. Merge has been rolled back.
See details: .autoralph/merge/failure.md

Dev branch restored to: ${pre_merge_sha}
Branch and worktree preserved for debugging.

Next: Investigate failures in ${worktree_path}
```

STOP.

### Step 6: Update State (Success Path)

Update status.json:
```json
{
  "runs": {
    "${work_id}": {
      ...existing fields...,
      "state": "merged",
      "merged_at": "${current_timestamp}",
      "merge_commit": "${git_rev_parse_HEAD}"
    }
  },
  "status": "complete"
}
```

Update work_ledger.json:
```json
{
  "tasks": [
    {
      "id": "${work_id}",
      ...existing fields...,
      "status": "merged",
      "merged_at": "${current_timestamp}"
    }
  ]
}
```

### Step 7: Cleanup

For Phase 1, we'll be conservative and KEEP the worktree and branch for inspection.

Just show a message:
```
Note: Worktree and branch preserved for inspection.
To clean up manually:
  git worktree remove ${worktree_path}
  git branch -d ${branch}
```

### Step 8: Show Success Summary

```
✅ Merge Complete (Phase 1)

Merged Task:
  ✅ Task ${work_id}: ${title}

Branch merged: ${branch} → dev
Merge commit: ${git_rev_parse_HEAD}
Files changed: ${file_count}
Tests: ✅ PASSED

Summary:
  - 1 task merged successfully
  - Tests passed after merge
  - Worktree preserved for inspection

Next Steps:
  - Review changes: git show HEAD
  - Push to remote: git push origin dev
  - Clean up: git worktree remove ${worktree_path}

  If you have more tasks, run /start-ralph again
```

## Error Handling

- If preconditions fail → show which precondition failed
- If merge conflict → abort, preserve state, show resolution steps
- If tests fail → rollback, preserve state, show investigation steps
- All failures logged to `.autoralph/merge/failure.md`

## Notes

This is Phase 1 simplified merge:
- Only merges ONE branch
- Basic conflict detection (git native)
- Simple test-after-merge
- Conservative (keeps worktree/branch)
- No parallel merging

Phase 2 will add:
- Multiple branch merge sequencing
- Advanced conflict analysis
- Automatic worktree cleanup
- Merge order optimization
