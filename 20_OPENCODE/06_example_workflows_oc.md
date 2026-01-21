# Example Workflows – OpenCode

This section outlines sample workflows for using OpenCode in a Ralph loop.  Adapt these patterns to suit your project.

## Workflow: Implement stories from a PRD

1. **Initial setup**
   * Write a `prd.json` describing user stories with `passes: false`.
   * Create a `progress.md` file to log iterations.
   * Define an agent profile in `opencode.json` with an appropriate `maxSteps` (e.g. 10) and permissions.
   * Optionally prepare skills (e.g. planning, review) in `.opencode/skills/`.

2. **Start a headless server**
   ```bash
   opencode serve --port 4096 --hostname 127.0.0.1
   export OPENCODE_SERVER_PASSWORD=secret
   ```
   The server stays running in the background.  All subsequent runs attach via `--attach http://127.0.0.1:4096` to avoid cold starts【674709478433772†L420-L449】.

3. **Loop through stories**
   ```bash
   iter=0
   while true; do
     ((iter++))
     # Build the prompt for the current story
     ./scripts/build_prompt.py --prd prd.json --progress progress.md --out prompts/iter_$iter.md
     # Run the agent
     opencode run -f prompts/iter_$iter.md --format json --attach http://127.0.0.1:4096 \
       > artifacts/iter_$iter.jsonl
     # Parse output and update PRD/progress
     ./scripts/post_process.py --events artifacts/iter_$iter.jsonl --prd prd.json --progress progress.md
     # Stop if sentinel detected or all stories complete
     if jq -r 'select(.result | test("<promise>COMPLETE</promise>"))' < artifacts/iter_$iter.jsonl; then
       echo "All stories complete after $iter iterations" >> progress.md
       break
     fi
     if (( iter >= 50 )); then
       echo "Max iterations reached" >> progress.md
       break
     fi
   done
   ```

4. **Review and commit**
   * Inspect diffs and progress log entries to verify changes.
   * Commit `prd.json`, updated code and `progress.md`.
   * Optionally run a `review` skill or another agent (e.g., Claude) to audit the work.

## Workflow: Planning phase using skills

OpenCode’s skill system can generate detailed plans before coding.  For example, a `create-plan` skill might break high‑level requirements into stories.  The harness can:

1. Invoke the skill via the `skill` tool: `skill({ name: "create-plan" })` within a planning prompt.
2. Save the generated plan to `prd.json` and commit.
3. Switch to the implementation loop described above.

By separating planning and implementation into distinct iterations (and possibly different agents), you reduce context usage and improve reliability.
