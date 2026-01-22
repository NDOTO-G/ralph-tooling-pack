#!/bin/bash
# Execute merge of a branch into dev
# Usage: ./merge_execute.sh <branch>

BRANCH=$1
BASE_BRANCH="dev"

if [ -z "$BRANCH" ]; then
  echo "ERROR: branch required"
  echo "Usage: $0 <branch>"
  exit 1
fi

# Extract work_id from branch name (e.g., ralph/task-001 -> 001)
WORK_ID=$(echo "$BRANCH" | sed 's/ralph\/task-//')

# Create merge directory if needed
mkdir -p ".autoralph/merge"

# Record pre-merge state
PRE_MERGE_SHA=$(git rev-parse HEAD)
echo "$PRE_MERGE_SHA" > ".autoralph/merge/pre_merge_sha_${WORK_ID}"

echo "Pre-merge commit: $PRE_MERGE_SHA"
echo "Switching to $BASE_BRANCH..."

# Switch to base branch
if ! git checkout "$BASE_BRANCH" 2>&1; then
  echo "ERROR: Failed to checkout $BASE_BRANCH"
  exit 1
fi

echo "Merging $BRANCH..."

# Attempt merge with --no-ff
if ! git merge --no-ff "$BRANCH" -m "Merge task $WORK_ID: $(git log -1 --pretty=%s $BRANCH)" 2>&1; then
  echo "CONFLICT"
  echo "Merge conflict detected. Aborting..."
  git merge --abort 2>&1
  exit 1
fi

echo "Merge successful. Running tests..."

# Run tests
if npm test > /tmp/merge_test_${WORK_ID}_$$.txt 2>&1; then
  echo "SUCCESS"
  rm -f /tmp/merge_test_${WORK_ID}_$$.txt
  exit 0
else
  echo "TEST_FAILED"
  echo "Tests failed. Rolling back..."

  # Rollback - reset to pre-merge state
  git reset --hard "$PRE_MERGE_SHA" 2>&1

  echo "Rollback complete. Dev branch restored to $PRE_MERGE_SHA"

  # Save test output for debugging
  cp /tmp/merge_test_${WORK_ID}_$$.txt ".autoralph/merge/test_failure_${WORK_ID}.txt" 2>/dev/null
  rm -f /tmp/merge_test_${WORK_ID}_$$.txt

  exit 2
fi
