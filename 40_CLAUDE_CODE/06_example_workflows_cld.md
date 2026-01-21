# Example Workflows (Claude Code)

This section demonstrates how a Ralph harness can orchestrate Claude Code to deliver repeatable, unattended work.  The examples assume you have defined a PRD file (`prd.json`) and a progress log (`progress.md`) in your repository.

## Single‑iteration pattern

1. **Write the prompt file** (e.g., `prompts/iteration_01.md`) containing:

   * Pointers to the PRD and progress files (e.g., “read the PRD at `prd.json` and the progress log at `progress.md`”).
   * Instructions to select the highest‑priority incomplete task, implement it using allowed tools, run tests, update the PRD and progress log, commit the changes and return `<promise>COMPLETE</promise>` when finished.

2. **Run Claude headlessly** using the adapter or directly:

   ```bash
   claude -p -f prompts/iteration_01.md \
     --output-format stream-json \
     --model anthropic/claude-3-5-sonnet-20241022 \
     --allowedTools "Read,Edit,Bash"
   ```

   Redirect the JSON stream to `artifacts/iteration_01_events.jsonl` for later parsing.

3. **Parse the JSON output** to extract events.  Identify the final assistant message and check for `<promise>COMPLETE</promise>`.  If missing, treat the run as a failure or continuation.

4. **Run validation scripts** (e.g., `./run_tests.sh`) on the repository to double‑check that the feature works.  Record success or failure.

5. **Update `progress.md`** with a new entry summarising the iteration, including a hash of the prompt file, the allowed tools, result status, and pointers to the artifact files.

6. **Determine next action:**

   * If complete and validations pass, proceed to the next task.
   * If validation fails, update the PRD or prompt with new instructions and start another iteration.
   * If repeated failures occur or budgets are exceeded, switch to a different model (e.g., Opus) or hand over to a human.

## Multi‑iteration loop (pseudocode)

The following shell pseudocode illustrates how a Ralph harness might wrap Claude in a loop.  See `60_SCRIPTS_AND_TEMPLATES/scripts/harness_template.sh` for a more concrete template.

```bash
#!/bin/bash
set -euo pipefail
MAX_ITERS=10
FAILURES=0
for ITER in $(seq 1 "$MAX_ITERS"); do
  PROMPT_FILE="prompts/iteration_${ITER}.md"
  # generate or update prompt file here (e.g., using a Python script)
  OUTPUT_FILE="artifacts/iteration_${ITER}_events.jsonl"
  claude -p -f "$PROMPT_FILE" \
    --output-format stream-json \
    --model anthropic/claude-3-5-sonnet-20241022 \
    --allowedTools "Read,Edit,Bash" >"$OUTPUT_FILE"
  # parse JSON to detect completion and errors
  if grep -q '<promise>COMPLETE</promise>' "$OUTPUT_FILE"; then
    echo "Iteration $ITER complete"
    # run tests, update progress log, commit
    if ./run_tests.sh; then
      FAILURES=0
    else
      ((FAILURES++))
    fi
  else
    ((FAILURES++))
  fi
  # escalation conditions
  if [[ $FAILURES -ge 3 ]]; then
    echo "Too many failures; escalating"
    break
  fi
done
```

## Notes

* Always run Claude in a clean environment or container to avoid unintended side effects.
* Adjust `--allowedTools` and the model version per iteration based on the complexity of the task and your budgets.
* For larger projects, break down the PRD into smaller batches and run separate loops per batch.
* Consider using a subagent via `context: fork` in skills for exploratory tasks or long‑running analyses.