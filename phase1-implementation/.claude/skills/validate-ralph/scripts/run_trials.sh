#!/bin/bash
# Run validation trials in worktree
# Usage: ./run_trials.sh <work_id>

WORK_ID=$1

if [ -z "$WORK_ID" ]; then
  echo "ERROR: work_id required"
  exit 1
fi

WORKTREE_PATH=".autoralph/worktrees/task-$WORK_ID"
TRIAL_FILE=".autoralph/trials/task_${WORK_ID}.md"

# Check if worktree exists
if [ ! -d "$WORKTREE_PATH" ]; then
  echo "ERROR: Worktree not found: $WORKTREE_PATH"
  exit 1
fi

# Create trials directory if needed
mkdir -p ".autoralph/trials"

# Enter worktree
cd "$WORKTREE_PATH" || exit 1

# Initialize trial file
cat > "../../$TRIAL_FILE" <<EOF
# Validation Trial: Task $WORK_ID

**Timestamp:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Worktree:** $WORKTREE_PATH
**Branch:** $(git branch --show-current)
**Base Branch:** dev

## Tests

**Command:** \`npm test\`

EOF

# Run tests
echo "Running tests in worktree..."
if npm test > /tmp/test_output_${WORK_ID}_$$.txt 2>&1; then
  TEST_EXIT_CODE=0
  echo "**Exit Code:** 0" >> "../../$TRIAL_FILE"
  echo "**Result:** ✅ PASSED" >> "../../$TRIAL_FILE"
  echo "" >> "../../$TRIAL_FILE"
  echo '```' >> "../../$TRIAL_FILE"
  tail -30 /tmp/test_output_${WORK_ID}_$$.txt >> "../../$TRIAL_FILE"
  echo '```' >> "../../$TRIAL_FILE"

  # Output result for capture
  echo "PASSED"
else
  TEST_EXIT_CODE=$?
  echo "**Exit Code:** $TEST_EXIT_CODE" >> "../../$TRIAL_FILE"
  echo "**Result:** ❌ FAILED" >> "../../$TRIAL_FILE"
  echo "" >> "../../$TRIAL_FILE"
  echo '```' >> "../../$TRIAL_FILE"
  tail -50 /tmp/test_output_${WORK_ID}_$$.txt >> "../../$TRIAL_FILE"
  echo '```' >> "../../$TRIAL_FILE"

  # Output result for capture
  echo "FAILED"
fi

# Cleanup temp file
rm -f /tmp/test_output_${WORK_ID}_$$.txt

exit $TEST_EXIT_CODE
