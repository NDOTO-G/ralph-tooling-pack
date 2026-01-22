#!/bin/bash
# Create git worktree for a task
# Usage: ./worktree_create.sh <work_id>

WORK_ID=$1

if [ -z "$WORK_ID" ]; then
  echo "ERROR: work_id required"
  echo "Usage: $0 <work_id>"
  exit 1
fi

WORKTREE_PATH=".autoralph/worktrees/task-$WORK_ID"
BRANCH_NAME="ralph/task-$WORK_ID"
BASE_BRANCH="dev"

# Check if worktree already exists
if [ -d "$WORKTREE_PATH" ]; then
  echo "ERROR: Worktree already exists: $WORKTREE_PATH"
  echo "Remove it first: git worktree remove $WORKTREE_PATH"
  exit 1
fi

# Check if branch already exists
if git show-ref --verify --quiet refs/heads/"$BRANCH_NAME"; then
  echo "ERROR: Branch already exists: $BRANCH_NAME"
  echo "Delete it first: git branch -D $BRANCH_NAME"
  exit 1
fi

# Create worktree from dev branch
if ! git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME" "$BASE_BRANCH" 2>&1; then
  echo "ERROR: Failed to create worktree"
  exit 1
fi

# Output worktree path (for capture by caller)
echo "$WORKTREE_PATH"
