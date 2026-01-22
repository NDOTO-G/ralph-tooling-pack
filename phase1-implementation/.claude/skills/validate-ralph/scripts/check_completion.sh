#!/bin/bash
# Check if OpenCode agent has completed
# Usage: ./check_completion.sh <work_id> <attempt>

WORK_ID=$1
ATTEMPT=${2:-1}

if [ -z "$WORK_ID" ]; then
  echo '{"status":"error","error":"work_id required"}'
  exit 1
fi

RUN_DIR=".autoralph/runs/task-$WORK_ID/attempt-$ATTEMPT"
PID_FILE="$RUN_DIR/pid"
EVENTS_FILE="$RUN_DIR/events.jsonl"

# Check if PID file exists
if [ ! -f "$PID_FILE" ]; then
  echo '{"status":"error","error":"PID file not found"}'
  exit 1
fi

PID=$(cat "$PID_FILE")

# Check if process is still running
if kill -0 $PID 2>/dev/null; then
  echo '{"status":"running","pid":'$PID'}'
  exit 0
fi

# Process has finished
# Check for completion sentinel
if [ -f "$EVENTS_FILE" ]; then
  if grep -q '<promise>COMPLETE</promise>' "$EVENTS_FILE" 2>/dev/null; then
    SENTINEL_FOUND=true
  else
    SENTINEL_FOUND=false
  fi
else
  SENTINEL_FOUND=false
fi

# Try to get exit code (may not work on all systems)
# This is best-effort
EXIT_CODE=0

echo '{"status":"completed","sentinel_found":'$SENTINEL_FOUND',"exit_code":'$EXIT_CODE'}'
