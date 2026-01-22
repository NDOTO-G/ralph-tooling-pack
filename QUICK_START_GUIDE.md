# Ralph Multi-Agent Skills - Quick Start Guide

## TL;DR

This system lets you:
1. Run `/start-ralph` in an interactive Claude session
2. Claude spawns 4 parallel headless OpenCode agents in separate git worktrees
3. Each agent works on a different task from your work ledger
4. Run `/validate-ralph` to check results and run validation trials
5. Run `/merge-ralph` to merge validated work into your dev branch

## Prerequisites Checklist

- [ ] Git >= 2.5 installed
- [ ] OpenCode installed and configured
- [ ] Claude Code installed
- [ ] Work ledger exists: `.claude/state/work_ledger.json`
- [ ] Work docs exist: `.claude/state/work_docs/task_*.md`
- [ ] Tests work: `npm test` (or equivalent)
- [ ] Clean dev branch exists

## Setup (One-time)

### 1. Start OpenCode Server

```bash
# Terminal 1: Start OpenCode server (keep running)
opencode serve --port 4096 --hostname 127.0.0.1
```

Set password:
```bash
export OPENCODE_SERVER_PASSWORD="your-secret-password"
```

### 2. Create Directory Structure

```bash
mkdir -p .claude/skills/{start-ralph,validate-ralph,merge-ralph}/scripts
mkdir -p .claude/state/{agents,trials,work_docs}
touch .claude/state/{autoapp_status.json,work_ledger.json,MAIN_PROGRESS.md}
```

### 3. Copy Skills

Copy the skill definitions from `RALPH_SKILLS_SPECIFICATION.md` into:
- `.claude/skills/start-ralph/SKILL.md`
- `.claude/skills/validate-ralph/SKILL.md`
- `.claude/skills/merge-ralph/SKILL.md`

### 4. Create Scripts

Implement the scripts specified in the spec (see Phase 1 below for minimal versions).

### 5. Initialize State Files

**`.claude/state/autoapp_status.json`:**
```json
{
  "version": "1.0.0",
  "status": "idle",
  "agents": [],
  "opencode_server": {
    "url": "http://127.0.0.1:4096",
    "status": "unknown"
  },
  "budgets": {
    "max_parallel_agents": 4,
    "max_iterations_per_agent": 3,
    "max_total_time_hours": 8
  }
}
```

**`.claude/state/work_ledger.json`:**
```json
{
  "project": "my-app",
  "base_branch": "main",
  "target_branch": "dev",
  "tasks": []
}
```

## Usage Workflow

### Step 1: Prepare Your Work

1. Add tasks to `.claude/state/work_ledger.json`
2. Create detailed specs in `.claude/state/work_docs/task_*.md`
3. Ensure dev branch is clean and up-to-date

### Step 2: Start Agents

```bash
# Terminal 2: Start interactive Claude session
claude

# In Claude prompt:
/start-ralph
```

Claude will:
- Read your work ledger
- Pick the 4 highest-priority tasks
- Create git worktrees
- Spawn OpenCode agents in background
- Show you the PIDs and status

### Step 3: Monitor Progress (Optional)

```bash
# Terminal 3: Watch agents
watch -n 5 'ps aux | grep opencode'

# Or tail output
tail -f .claude/state/agents/agent_1/output.jsonl | jq .

# Or check status
jq . .claude/state/autoapp_status.json
```

### Step 4: Validate Results

Wait for agents to complete (you'll see heartbeat files stop updating), then:

```bash
# In Claude prompt:
/validate-ralph
```

Claude will:
- Check which agents completed
- Parse output for completion sentinel
- Run tests in each worktree
- Update work ledger with validation status
- Show summary of pass/fail/retry/escalate

### Step 5: Merge Changes

When all agents pass validation:

```bash
# In Claude prompt:
/merge-ralph
```

Claude will:
- Merge worktrees sequentially
- Run tests after each merge
- Handle conflicts (abort and escalate)
- Clean up worktrees
- Update work ledger

### Step 6: Repeat or Review

If there are more tasks:
```bash
/start-ralph
```

If there are failures or conflicts:
- Review logs in `.claude/state/agents/*/output.jsonl`
- Fix issues manually
- Update work docs if needed
- Retry

## Testing Progression

### Phase 1: Single Agent (Recommended First Step)

**Goal:** Validate the entire workflow with ONE agent.

**Minimal scripts needed:**

`.claude/skills/start-ralph/scripts/setup_worktrees.sh`:
```bash
#!/bin/bash
TASK_ID=$1
WORKTREE_PATH="../worktrees/ralph-task-$TASK_ID"
BRANCH_NAME="ralph/task-$TASK_ID"

git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME" dev
echo "$WORKTREE_PATH"
```

`.claude/skills/start-ralph/scripts/spawn_agents.sh`:
```bash
#!/bin/bash
TASK_ID=$1
WORKTREE_PATH=$2
PROMPT_FILE=$3

OUTPUT_FILE=".claude/state/agents/agent_$TASK_ID/output.jsonl"
mkdir -p ".claude/state/agents/agent_$TASK_ID"

timeout 30m opencode run \
  -f "$PROMPT_FILE" \
  --format json \
  --attach http://127.0.0.1:4096 \
  --cwd "$WORKTREE_PATH" \
  > "$OUTPUT_FILE" 2>&1 &

echo $!
```

**Test work ledger (1 task):**
```json
{
  "project": "test",
  "tasks": [
    {
      "id": "001",
      "title": "Add a simple function",
      "priority": 10,
      "status": "pending",
      "work_doc": "work_docs/task_001.md"
    }
  ]
}
```

**Test work doc:**
```markdown
# Task 001: Add a Simple Function

Create a function `add(a, b)` that returns `a + b`.

## Files to Create
- `src/add.js`
- `src/add.test.js`

## Acceptance Criteria
- Function exists and works
- Tests pass
```

**Run test:**
1. Start OpenCode server
2. Run `/start-ralph` (should spawn 1 agent)
3. Wait 2-5 minutes
4. Run `/validate-ralph`
5. Run `/merge-ralph`

### Phase 2: Dual Agents

Same as Phase 1, but with 2 independent tasks.

### Phase 3: Full Parallel (4 Agents)

Same as Phase 2, but with 4 tasks.

## Troubleshooting

### OpenCode agents not spawning

**Check:**
```bash
# Is server running?
curl http://127.0.0.1:4096/health

# Can you run manually?
opencode run -f test.md --attach http://127.0.0.1:4096
```

### Agents running but not completing

**Debug:**
```bash
# Check output
tail -100 .claude/state/agents/agent_1/output.jsonl

# Check if process is alive
ps aux | grep $PID

# Check heartbeat
ls -lt .claude/state/agents/*/heartbeat
```

### Validation failing

**Check:**
```bash
# Go to worktree
cd ../worktrees/ralph-task-001

# Run tests manually
npm test

# Check git status
git status
git log
```

### Merge conflicts

**Resolve manually:**
```bash
git checkout dev
git merge ralph/task-001
# Fix conflicts
git add .
git commit
```

Then update work_ledger.json manually and rerun `/merge-ralph`.

## File Locations Reference

| File | Purpose |
|------|---------|
| `.claude/state/autoapp_status.json` | Current execution state |
| `.claude/state/work_ledger.json` | Task list (you provide this) |
| `.claude/state/work_docs/task_*.md` | Task specs (you provide these) |
| `.claude/state/agents/agent_*/output.jsonl` | OpenCode agent output |
| `.claude/state/agents/agent_*/prompt.md` | Generated prompts |
| `.claude/state/agents/agent_*/PROGRESS.md` | Agent-specific progress |
| `.claude/state/trials/trial_*.json` | Validation results |
| `.claude/state/MAIN_PROGRESS.md` | Overall progress log |
| `../worktrees/ralph-task-*` | Git worktrees (temporary) |

## Safety Features

- **PID tracking**: All agent PIDs saved to autoapp_status.json
- **Timeouts**: 30-minute max per agent
- **Max steps**: 10 tool calls per agent (configurable)
- **Heartbeats**: Touch file every 60 seconds while running
- **Atomic writes**: JSON files written atomically
- **Rollback**: Merge aborted on conflict
- **Escalation**: Failed agents marked for human review

## Cost Management

**Per agent:**
- Max steps: 10 (conservative)
- Model: claude-sonnet-4-5 (mid-tier)
- Timeout: 30 minutes
- Estimated cost: $0.50-$2.00 per agent

**For 4 parallel agents:**
- Total: $2-$8 per iteration
- Budget cap: Set in autoapp_status.json

## Next Steps

1. Read `RALPH_SKILLS_SPECIFICATION.md` for detailed design
2. Implement Phase 1 (single agent) scripts
3. Test with a simple task
4. Gradually add complexity
5. Scale to 4 parallel agents

## Support

If you encounter issues:
1. Check logs in `.claude/state/agents/*/output.jsonl`
2. Review autoapp_status.json for agent states
3. Manually test OpenCode commands
4. Verify git worktrees are set up correctly
5. Ensure OpenCode server is running and accessible

---

**Key Insight:** This system is just structured bash orchestration with file-based state management. The "magic" is in the coordination, not in any complex IPC or SDK calls.

Start simple, test thoroughly, scale gradually. 🚀
