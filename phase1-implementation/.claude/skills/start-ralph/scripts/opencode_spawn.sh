#!/bin/bash
# Spawn OpenCode agent in background
# Usage: ./opencode_spawn.sh <work_id> <worktree_path> <prompt_file> <attempt>

WORK_ID=$1
WORKTREE_PATH=$2
PROMPT_FILE=$3
ATTEMPT=${4:-1}

if [ -z "$WORK_ID" ] || [ -z "$WORKTREE_PATH" ] || [ -z "$PROMPT_FILE" ]; then
  echo "ERROR: Missing required arguments"
  echo "Usage: $0 <work_id> <worktree_path> <prompt_file> [attempt]"
  exit 1
fi

# Create run directory
RUN_DIR=".autoralph/runs/task-$WORK_ID/attempt-$ATTEMPT"
mkdir -p "$RUN_DIR"

EVENTS_FILE="$RUN_DIR/events.jsonl"
STDOUT_FILE="$RUN_DIR/stdout.log"
STDERR_FILE="$RUN_DIR/stderr.log"
PID_FILE="$RUN_DIR/pid"

# Check if prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
  echo "ERROR: Prompt file not found: $PROMPT_FILE"
  exit 1
fi

# Check if worktree exists
if [ ! -d "$WORKTREE_PATH" ]; then
  echo "ERROR: Worktree not found: $WORKTREE_PATH"
  exit 1
fi

# Build OpenCode command
# Phase 1: Simple version without attach (can add --attach later)
CMD="timeout 30m opencode run \
  -f \"$PROMPT_FILE\" \
  --format json \
  --cwd \"$WORKTREE_PATH\" \
  --maxSteps 10"

# Execute in background, redirect output
$CMD > "$EVENTS_FILE" 2> "$STDERR_FILE" &
PID=$!

# Save PID
echo $PID > "$PID_FILE"

# Log start
echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") - Spawned OpenCode agent" > "$STDOUT_FILE"
echo "PID: $PID" >> "$STDOUT_FILE"
echo "Work ID: $WORK_ID" >> "$STDOUT_FILE"
echo "Worktree: $WORKTREE_PATH" >> "$STDOUT_FILE"
echo "Prompt: $PROMPT_FILE" >> "$STDOUT_FILE"
echo "Max steps: 10" >> "$STDOUT_FILE"
echo "Timeout: 30 minutes" >> "$STDOUT_FILE"

# Output PID for capture
echo $PID
