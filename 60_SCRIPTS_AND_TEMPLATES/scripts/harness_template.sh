#!/bin/bash
# Harness template for orchestrating a Ralph loop across different engines.
#
# This script illustrates how a wrapper might call into the normalized
# `run_agent` function (see 30_TOOL_ADAPTER_SPEC.md) to execute a prompt
# against OpenCode, Codex CLI or Claude Code.  It manages iterations,
# budgets, validation and escalation.

set -euo pipefail

# Configuration defaults.  Override via environment variables or CLI flags.
MAX_ITERATIONS=${MAX_ITERATIONS:-10}
MAX_FAILURES=${MAX_FAILURES:-3}
ALLOWED_TOOLS=${ALLOWED_TOOLS:-"Read,Edit,Bash"}
MODE=${MODE:-"default"}               # agent/model name
TOOL=${TOOL:-"opencode"}             # one of: opencode, codex, claude

failures=0
for iter in $(seq 1 "$MAX_ITERATIONS"); do
  echo "[Ralph] Starting iteration $iter for $TOOL" >&2
  prompt_path="prompts/iteration_${iter}.md"
  output_path="artifacts/iteration_${iter}_events.jsonl"
  repo_path="."
  # TODO: generate or update $prompt_path based on your PRD and progress log
  # Here we assume the prompt already exists.

  # Call the normalized run_agent function via Python.  The Python module
  # should implement the adapter logic for each tool as described in the
  # tool adapter spec.  Adjust the import path as needed.  Environment
  # variables are exported inline for convenience.
  PROMPT_PATH="$prompt_path" OUTPUT_PATH="$output_path" REPO_PATH="$repo_path" MODE="$MODE" ALLOWED_TOOLS="$ALLOWED_TOOLS" \
    python - <<'PY'
import json, os
from harness import run_agent  # implement this module in your project

prompt_path = os.environ['PROMPT_PATH']
output_path = os.environ['OUTPUT_PATH']
repo_path = os.environ['REPO_PATH']
mode = os.environ.get('MODE') or None
allowed = os.environ.get('ALLOWED_TOOLS')
allowed_list = allowed.split(',') if allowed else None

result = run_agent(
    prompt_path=prompt_path,
    output_path=output_path,
    repo_path=repo_path,
    mode=mode,
    allowed_tools=allowed_list,
    permissions=None,
    max_steps=None,
)

with open(output_path, 'w') as f:
    # Save raw output; adapt run_agent to write JSON as needed
    f.write(result.get('raw_output', ''))
print(json.dumps(result))
PY

  # Parse the output file for the completion sentinel
  if grep -q '<promise>COMPLETE</promise>' "$output_path"; then
    echo "Iteration $iter complete" >&2
    failures=0
    # Run validation tests externally (customise this command)
    if ./run_tests.sh; then
      echo "Tests passed" >&2
    else
      echo "Tests failed" >&2
      failures=$((failures+1))
    fi
  else
    echo "Sentinel not found in iteration $iter" >&2
    failures=$((failures+1))
  fi

  # Write a progress log entry (simplified)
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  printf '\n## %s – Iteration %s (%s)\n' "$timestamp" "$iter" "$TOOL" >> progress.md
  printf '**Result:** %s\n' "$(grep -q '<promise>COMPLETE</promise>' "$output_path" && echo COMPLETE || echo FAILED)" >> progress.md
  printf '**Evidence:** events: %s\n' "$output_path" >> progress.md

  # Escalation logic
  if [ "$failures" -ge "$MAX_FAILURES" ]; then
    echo "Too many failures; escalating after $iter iterations" >&2
    break
  fi
done
exit 0