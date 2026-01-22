# Ralph Multi-Agent Skills - Complete Specification

## Overview

This specification defines a multi-agent orchestration system using Claude Code skills to spawn and manage parallel OpenCode agents. The system enables:

1. **Interactive Claude session** spawns headless OpenCode agents via background bash
2. **Parallel execution** of 4 OpenCode agents working on separate git worktrees
3. **Manual validation** via `/validate-ralph` skill after OpenCode agents complete
4. **Manual merging** via `/merge-ralph` skill when all work is validated

---

## Directory Structure

```
your-repo/
├── .claude/
│   ├── skills/
│   │   ├── start-ralph/
│   │   │   ├── SKILL.md
│   │   │   └── scripts/
│   │   │       ├── spawn_agents.sh
│   │   │       ├── build_prompts.py
│   │   │       └── setup_worktrees.sh
│   │   ├── validate-ralph/
│   │   │   ├── SKILL.md
│   │   │   └── scripts/
│   │   │       ├── check_completion.sh
│   │   │       ├── run_trials.py
│   │   │       └── analyze_results.py
│   │   └── merge-ralph/
│   │       ├── SKILL.md
│   │       └── scripts/
│   │           ├── merge_worktrees.sh
│   │           ├── run_tests.sh
│   │           └── cleanup_worktrees.sh
│   └── state/
│       ├── autoapp_status.json      # Execution state & agent tracking
│       ├── work_ledger.json         # Task list (PRD-like)
│       ├── work_docs/               # Detailed specs per task
│       │   ├── task_001.md
│       │   ├── task_002.md
│       │   └── ...
│       ├── trials/                  # Validation results
│       │   ├── trial_001.json
│       │   └── ...
│       ├── agents/                  # Agent memory/state per worktree
│       │   ├── agent_1/
│       │   │   ├── PROGRESS.md
│       │   │   └── memory.md
│       │   └── ...
│       └── MAIN_PROGRESS.md         # Overall progress log
├── .opencode/
│   ├── opencode.json                # OpenCode configuration
│   └── skills/                      # Optional: OpenCode-specific skills
└── run_tests.sh                     # Your existing test suite
```

---

## State File Schemas

### 1. autoapp_status.json

Tracks overall execution state, running agents, and orchestration metadata.

```json
{
  "version": "1.0.0",
  "status": "running",
  "current_iteration": 3,
  "started_at": "2026-01-22T10:30:00Z",
  "updated_at": "2026-01-22T11:45:00Z",
  "agents": [
    {
      "id": "agent_1",
      "task_id": "001",
      "worktree_path": "../worktrees/ralph-task-001",
      "branch_name": "ralph/task-001",
      "pid": 12345,
      "status": "running",
      "output_file": ".claude/state/agents/agent_1/output.jsonl",
      "heartbeat_file": ".claude/state/agents/agent_1/heartbeat",
      "started_at": "2026-01-22T10:35:00Z",
      "last_heartbeat": "2026-01-22T11:44:00Z",
      "max_tries": 3,
      "current_try": 1,
      "prompt_file": ".claude/state/agents/agent_1/prompt.md"
    },
    {
      "id": "agent_2",
      "task_id": "002",
      "worktree_path": "../worktrees/ralph-task-002",
      "branch_name": "ralph/task-002",
      "pid": 12346,
      "status": "completed",
      "output_file": ".claude/state/agents/agent_2/output.jsonl",
      "started_at": "2026-01-22T10:35:00Z",
      "completed_at": "2026-01-22T11:20:00Z",
      "exit_code": 0,
      "validation_status": "pending"
    },
    {
      "id": "agent_3",
      "task_id": "003",
      "worktree_path": "../worktrees/ralph-task-003",
      "branch_name": "ralph/task-003",
      "pid": null,
      "status": "failed",
      "output_file": ".claude/state/agents/agent_3/output.jsonl",
      "started_at": "2026-01-22T10:35:00Z",
      "failed_at": "2026-01-22T11:10:00Z",
      "exit_code": 1,
      "error": "Max steps exceeded",
      "validation_status": "failed"
    },
    {
      "id": "agent_4",
      "task_id": "004",
      "worktree_path": "../worktrees/ralph-task-004",
      "branch_name": "ralph/task-004",
      "status": "pending"
    }
  ],
  "opencode_server": {
    "url": "http://127.0.0.1:4096",
    "pid": 12300,
    "started_at": "2026-01-22T10:30:00Z",
    "status": "running"
  },
  "budgets": {
    "max_parallel_agents": 4,
    "max_iterations_per_agent": 3,
    "max_total_time_hours": 8,
    "max_cost_usd": 50.0
  },
  "next_actions": [
    "wait_for_agent_1_completion",
    "validate_agent_2_results"
  ]
}
```

### 2. work_ledger.json

PRD-like task list following Ralph primitives. This is what you **already have** in your repo.

```json
{
  "project": "my-awesome-app",
  "base_branch": "main",
  "target_branch": "dev",
  "created_at": "2026-01-20T00:00:00Z",
  "updated_at": "2026-01-22T11:45:00Z",
  "tasks": [
    {
      "id": "001",
      "title": "Add user authentication",
      "priority": 10,
      "status": "in_progress",
      "assigned_agent": "agent_1",
      "work_doc": "work_docs/task_001.md",
      "acceptance_criteria": [
        "Login form accepts email and password",
        "JWT tokens are generated and validated",
        "Protected routes redirect to login"
      ],
      "validation": {
        "tests_passing": false,
        "linting_passing": false,
        "manual_review": false
      },
      "trials": [],
      "created_at": "2026-01-20T00:00:00Z",
      "started_at": "2026-01-22T10:35:00Z"
    },
    {
      "id": "002",
      "title": "Implement user profile API",
      "priority": 8,
      "status": "completed",
      "assigned_agent": "agent_2",
      "work_doc": "work_docs/task_002.md",
      "acceptance_criteria": [
        "GET /api/profile returns user data",
        "PUT /api/profile updates user data",
        "Validation errors return 400"
      ],
      "validation": {
        "tests_passing": true,
        "linting_passing": true,
        "manual_review": false
      },
      "trials": ["trial_001"],
      "created_at": "2026-01-20T00:00:00Z",
      "started_at": "2026-01-22T10:35:00Z",
      "completed_at": "2026-01-22T11:20:00Z"
    },
    {
      "id": "003",
      "title": "Add password reset flow",
      "priority": 7,
      "status": "failed",
      "assigned_agent": "agent_3",
      "work_doc": "work_docs/task_003.md",
      "validation": {
        "tests_passing": false,
        "linting_passing": false,
        "manual_review": false
      },
      "trials": [],
      "failure_reason": "Agent exceeded max steps",
      "requires_escalation": true
    },
    {
      "id": "004",
      "title": "Email verification system",
      "priority": 6,
      "status": "pending",
      "work_doc": "work_docs/task_004.md"
    }
  ]
}
```

### 3. work_docs/task_NNN.md

Detailed specification for each task. This is what you **already have** in your repo.

```markdown
# Task 001: Add User Authentication

## Overview
Implement a complete user authentication system using JWT tokens.

## Technical Requirements
- Use bcrypt for password hashing
- JWT tokens expire after 24 hours
- Refresh tokens stored in httpOnly cookies
- Rate limiting on login endpoint (5 attempts per 15 minutes)

## Files to Create
- `src/auth/login.ts`
- `src/auth/jwt.ts`
- `src/middleware/authenticate.ts`

## Files to Modify
- `src/routes/index.ts` - Add auth routes
- `src/app.ts` - Add authentication middleware

## Acceptance Criteria
1. Login form accepts email and password
2. JWT tokens are generated and validated
3. Protected routes redirect to login
4. Tests cover happy path and error cases

## Context
See `docs/architecture/auth.md` for overall auth strategy.
Related to task 002 (user profile needs auth).

## Validation
Run: `npm test -- auth`
Check: ESLint passes on new files
```

### 4. trials/trial_NNN.json

Validation results for completed work.

```json
{
  "trial_id": "trial_001",
  "task_id": "002",
  "agent_id": "agent_2",
  "created_at": "2026-01-22T11:25:00Z",
  "type": "automated",
  "tests": {
    "command": "npm test -- profile",
    "exit_code": 0,
    "duration_seconds": 12.3,
    "output_file": ".claude/state/trials/trial_001_test_output.txt",
    "passed": true
  },
  "linting": {
    "command": "npm run lint",
    "exit_code": 0,
    "passed": true
  },
  "type_check": {
    "command": "npm run type-check",
    "exit_code": 0,
    "passed": true
  },
  "manual_checks": [
    {
      "check": "API returns 401 for unauthenticated requests",
      "status": "passed",
      "notes": "Tested with curl, works correctly"
    }
  ],
  "overall_result": "passed",
  "next_action": "ready_for_merge"
}
```

---

## Skill Definitions

### Skill 1: start-ralph

**Purpose:** Orchestrator skill that reads work ledger, selects best tasks, creates worktrees, spawns OpenCode agents in background.

**File: `.claude/skills/start-ralph/SKILL.md`**

```markdown
---
name: start-ralph
description: "Start parallel OpenCode agents for Ralph tasks"
user-invocable: true
disable-model-invocation: true
allowed-tools:
  - Read
  - Write
  - Bash
---

# Start Ralph Agent Orchestration

This skill initiates the Ralph multi-agent workflow by:

1. Reading the work ledger and autoapp status
2. Determining the best 4 tasks to work on next (by priority and dependencies)
3. Creating git worktrees for each task
4. Building prompts from work docs
5. Spawning headless OpenCode agents in background
6. Updating autoapp status with agent PIDs and metadata

## Prerequisites

Before invoking this skill, ensure:
- OpenCode server is running: `opencode serve --port 4096`
- Work ledger exists: `.claude/state/work_ledger.json`
- Work docs exist for all tasks
- Tests are passing on main branch

## Usage

In interactive Claude session:
```
/start-ralph
```

## What Happens

1. **Validation**: Checks that environment is ready
2. **Selection**: Picks up to 4 high-priority tasks with status "pending"
3. **Worktree setup**: Creates isolated git worktrees from dev branch
4. **Prompt building**: Generates prompts from work docs
5. **Agent spawning**: Launches OpenCode agents with timeouts and limits
6. **Status update**: Writes agent metadata to autoapp_status.json

## Expected Output

```
✓ Read work ledger: 8 tasks found
✓ Selected 4 tasks: [001, 002, 003, 004]
✓ Created worktree: ../worktrees/ralph-task-001
✓ Created worktree: ../worktrees/ralph-task-002
✓ Created worktree: ../worktrees/ralph-task-003
✓ Created worktree: ../worktrees/ralph-task-004
✓ Built prompts for all tasks
✓ Spawned agent_1 (PID: 12345) for task 001
✓ Spawned agent_2 (PID: 12346) for task 002
✓ Spawned agent_3 (PID: 12347) for task 003
✓ Spawned agent_4 (PID: 12348) for task 004
✓ Updated autoapp_status.json

All agents running in background. Use /validate-ralph to check progress.
```

## Safety

- Only starts agents if work ledger is valid
- Limits to 4 parallel agents (configurable)
- Uses timeouts to prevent runaway processes
- Each agent has maxSteps=10 limit
- Output captured to files for debugging
```

**Supporting Scripts:**

**`.claude/skills/start-ralph/scripts/setup_worktrees.sh`**
- Validates git state (clean working directory)
- Creates worktree from dev branch
- Sets up branch name: `ralph/task-NNN`
- Returns worktree path

**`.claude/skills/start-ralph/scripts/build_prompts.py`**
- Reads work_ledger.json and work_docs/task_NNN.md
- Generates formatted prompt for OpenCode agent
- Includes: task description, acceptance criteria, validation requirements, context files
- Injects Ralph sentinel: `<promise>COMPLETE</promise>`
- Outputs to `.claude/state/agents/agent_N/prompt.md`

**`.claude/skills/start-ralph/scripts/spawn_agents.sh`**
- Takes: task_id, worktree_path, prompt_file, max_steps
- Launches OpenCode with: `opencode run -f {prompt} --format json --attach http://127.0.0.1:4096 --maxSteps {max_steps} --cwd {worktree}`
- Uses timeout: `timeout 30m`
- Redirects output to: `.claude/state/agents/agent_N/output.jsonl`
- Captures PID and writes to autoapp_status.json
- Sets up heartbeat: `while kill -0 $PID; do touch heartbeat; sleep 60; done &`

---

### Skill 2: validate-ralph

**Purpose:** Checks OpenCode agent completion status, runs validation trials, determines next actions.

**File: `.claude/skills/validate-ralph/SKILL.md`**

```markdown
---
name: validate-ralph
description: "Validate completed Ralph agents and determine next steps"
user-invocable: true
disable-model-invocation: false
allowed-tools:
  - Read
  - Write
  - Bash
  - Grep
---

# Validate Ralph Agent Results

This skill checks the status of running OpenCode agents and validates their work:

1. Reads autoapp_status.json to get agent metadata
2. Checks process status (running/completed/failed)
3. Parses output files for completion sentinel
4. Runs validation trials (tests, linting, type checks)
5. Updates work_ledger.json with results
6. Determines next actions (retry, escalate, proceed to merge)

## Usage

After spawning agents with `/start-ralph`, wait for them to complete, then:

```
/validate-ralph
```

## Validation Steps

For each agent:

1. **Process check**: Is the process still running?
2. **Output parse**: Does output contain `<promise>COMPLETE</promise>`?
3. **Exit code**: Did the process exit successfully?
4. **Test run**: Run test suite in the worktree
5. **Linting**: Run ESLint/Prettier
6. **Type check**: Run TypeScript compiler
7. **Manual checks**: Verify acceptance criteria

## Outcomes

- **PASSED**: All validations passed → ready for merge
- **FAILED**: Validation failed → analyze logs, prepare retry prompt
- **RUNNING**: Agent still executing → wait and check again
- **ESCALATED**: Agent stuck or exceeded retries → human review needed

## Expected Output

```
Checking agent_1 (task 001)...
  ✓ Process completed (exit code: 0)
  ✓ Found completion sentinel
  ✓ Tests passed (12/12)
  ✓ Linting passed
  ✓ Type check passed
  → Status: PASSED

Checking agent_2 (task 002)...
  ✓ Process completed (exit code: 0)
  ✓ Found completion sentinel
  ✗ Tests failed (2/8 failing)
  → Status: FAILED
  → Next: Retry with error context

Checking agent_3 (task 003)...
  ⏳ Still running (45 minutes elapsed)
  → Status: RUNNING
  → Next: Wait or timeout

Checking agent_4 (task 004)...
  ✗ Process failed (exit code: 1)
  ✗ Max steps exceeded
  → Status: ESCALATED
  → Next: Human review required

Summary:
- 1 passed (ready for merge)
- 1 failed (will retry)
- 1 running (waiting)
- 1 escalated (needs review)

Use /validate-ralph again to recheck running agents.
When all agents pass, use /merge-ralph to merge changes.
```

## Retry Logic

If agent failed but is retryable:
1. Read error logs from output file
2. Update prompt with error context
3. Increment retry counter
4. Respawn agent with new prompt (up to max_tries)

## Scripts

- `check_completion.sh`: Parse output files and check process status
- `run_trials.py`: Execute test suite and capture results
- `analyze_results.py`: Determine pass/fail and next actions
```

**Supporting Scripts:**

**`.claude/skills/validate-ralph/scripts/check_completion.sh`**
- Takes: agent_id
- Checks: process status via `ps`, exit code, heartbeat timestamp
- Greps output file for `<promise>COMPLETE</promise>`
- Returns: JSON with status

**`.claude/skills/validate-ralph/scripts/run_trials.py`**
- Takes: task_id, worktree_path
- Changes to worktree directory
- Runs: tests, linting, type-check
- Captures: exit codes, stdout/stderr, timing
- Writes: trial result to `.claude/state/trials/trial_NNN.json`

**`.claude/skills/validate-ralph/scripts/analyze_results.py`**
- Takes: agent_id, trial_id
- Reads: output.jsonl, trial results, work doc
- Determines: passed/failed/retry/escalate
- Generates: retry prompt if needed (includes error context)
- Updates: autoapp_status.json and work_ledger.json

---

### Skill 3: merge-ralph

**Purpose:** Merges validated worktrees into dev branch, runs final tests, cleans up.

**File: `.claude/skills/merge-ralph/SKILL.md`**

```markdown
---
name: merge-ralph
description: "Merge validated Ralph worktrees into dev branch"
user-invocable: true
disable-model-invocation: true
allowed-tools:
  - Read
  - Write
  - Bash
  - Grep
---

# Merge Ralph Worktrees

This skill merges completed and validated work from worktrees into the dev branch:

1. Reads autoapp_status.json and work_ledger.json
2. Verifies all required tasks are validated
3. Determines optimal merge order (dependency-aware)
4. Merges each worktree sequentially
5. Runs full test suite after merge
6. Handles merge conflicts (abort and escalate if needed)
7. Cleans up worktrees
8. Updates ledger and checks for remaining work

## Prerequisites

Before merging:
- All agents must have status "completed" with validation "passed"
- No agents should be running
- Dev branch should be clean

## Usage

After all agents pass validation:

```
/merge-ralph
```

## Merge Strategy

1. **Topological sort**: Order tasks by dependencies (if any)
2. **Sequential merge**: Merge one worktree at a time
3. **Test after each**: Run tests after every merge
4. **Rollback on failure**: If merge breaks tests, abort and escalate

## Expected Output

```
✓ All agents validated and passed
✓ Determined merge order: [002, 001, 004, 003]

Merging task 002 (user profile API)...
  ✓ Switched to dev branch
  ✓ Merged ralph/task-002 (3 commits)
  ✓ Tests passed
  ✓ Updated work ledger

Merging task 001 (authentication)...
  ✓ Merged ralph/task-001 (5 commits)
  ✓ Tests passed
  ✓ Updated work ledger

Merging task 004 (email verification)...
  ✓ Merged ralph/task-004 (2 commits)
  ✓ Tests passed
  ✓ Updated work ledger

Merging task 003 (password reset)...
  ✗ Merge conflict in src/auth/routes.ts
  ✗ Aborting merge
  → ESCALATED: Manual conflict resolution needed

Summary:
- 3 tasks merged successfully
- 1 task needs manual merge
- Cleaned up 3 worktrees
- 4 tasks remaining in work ledger

Next: Resolve conflict in task 003, then rerun /merge-ralph
Or: Start new iteration with /start-ralph for remaining tasks
```

## Cleanup

After successful merge:
- Delete merged worktree: `git worktree remove`
- Delete remote branch (optional)
- Update work_ledger.json: set status to "merged"
- Append to MAIN_PROGRESS.md

## Escalation

If merge fails:
- Abort the merge: `git merge --abort`
- Log conflict details
- Set task status to "needs_manual_merge"
- Stop and request human intervention

## Scripts

- `merge_worktrees.sh`: Sequential merge with rollback on failure
- `run_tests.sh`: Full test suite execution
- `cleanup_worktrees.sh`: Remove completed worktrees
```

**Supporting Scripts:**

**`.claude/skills/merge-ralph/scripts/merge_worktrees.sh`**
- Takes: branch_name, task_id
- Switches to dev branch
- Runs: `git merge --no-ff {branch_name} -m "Merge task {task_id}: {title}"`
- Checks: merge conflicts
- Returns: exit code

**`.claude/skills/merge-ralph/scripts/run_tests.sh`**
- Runs full test suite: `npm test`
- Runs linting: `npm run lint`
- Runs type check: `npm run type-check`
- Returns: combined exit code

**`.claude/skills/merge-ralph/scripts/cleanup_worktrees.sh`**
- Takes: worktree_path, branch_name
- Removes worktree: `git worktree remove {worktree_path}`
- Optionally deletes branch: `git branch -d {branch_name}`

---

## Environment Prerequisites

### System Requirements

1. **Git version**: >= 2.5 (for `git worktree` support)
2. **Node.js**: >= 18 (or whatever your project requires)
3. **OpenCode**: Latest version
4. **Claude Code**: Latest version

### OpenCode Configuration

**File: `.opencode/opencode.json`**

```json
{
  "agents": {
    "ralph-executor": {
      "maxSteps": 10,
      "model": "claude-sonnet-4-5",
      "allowedTools": ["Read", "Write", "Edit", "Bash", "Grep", "Glob"],
      "permissions": {
        "bash": {
          "git *": "allow",
          "npm test": "allow",
          "npm run lint": "allow",
          "npm run type-check": "allow",
          "*": "ask"
        },
        "write": "allow",
        "read": "allow",
        "edit": "allow",
        "doom_loop": "deny",
        "external_directory": "deny"
      }
    }
  },
  "mcp": {
    "servers": {}
  }
}
```

### OpenCode Server

Start the OpenCode server before invoking `/start-ralph`:

```bash
# Start server in background (persistent)
opencode serve --port 4096 --hostname 127.0.0.1 &
export OPENCODE_SERVER_PID=$!
export OPENCODE_SERVER_PASSWORD="your-secret-password"

# Or use systemd/PM2 for production
```

### Budget Configuration

Set environment variables for cost control:

```bash
export OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX=8000
export OPENCODE_EXPERIMENTAL_BASH_MAX_OUTPUT_LENGTH=50000
export OPENCODE_EXPERIMENTAL_BASH_DEFAULT_TIMEOUT_MS=300000  # 5 minutes
```

### Repository Setup

Your repo must have:

1. **Work ledger**: `.claude/state/work_ledger.json`
2. **Work docs**: `.claude/state/work_docs/task_*.md` for each task
3. **Test suite**: Working `npm test` (or equivalent)
4. **Linting**: Working `npm run lint`
5. **Type checking**: Working `npm run type-check` (if TypeScript)
6. **Dev branch**: Clean `dev` branch for merging

---

## Testing Strategy

### Phase 1: Single Agent Test (Low Risk)

Test with ONE agent before going parallel:

```bash
# 1. Create test work ledger with 1 task
# 2. Run: /start-ralph
# 3. Wait for completion
# 4. Run: /validate-ralph
# 5. Run: /merge-ralph
```

**Success criteria:**
- Agent spawns successfully
- Output file contains valid JSON
- Completion sentinel detected
- Tests pass
- Merge succeeds

### Phase 2: Dual Agent Test (Medium Risk)

Test with 2 agents:

```bash
# 1. Create work ledger with 2 independent tasks
# 2. Run: /start-ralph
# 3. Monitor both agents
# 4. Run: /validate-ralph
# 5. Check for conflicts
# 6. Run: /merge-ralph
```

**Success criteria:**
- Both agents complete
- No resource conflicts
- Both worktrees merge cleanly

### Phase 3: Full Parallel Test (Production)

Test with 4 agents:

```bash
# 1. Create work ledger with 4 tasks
# 2. Run: /start-ralph
# 3. Monitor system resources
# 4. Test agent failure scenarios (kill one agent mid-run)
# 5. Run: /validate-ralph
# 6. Handle retries
# 7. Run: /merge-ralph
```

**Success criteria:**
- All 4 agents complete or retry successfully
- Failed agents are detected and retried
- Validation catches test failures
- Merge handles conflicts gracefully

### Testing Tools

**Monitor agents:**
```bash
watch -n 5 'ps aux | grep opencode'
watch -n 5 'tail -1 .claude/state/agents/*/heartbeat | xargs ls -lt'
```

**Check output:**
```bash
tail -f .claude/state/agents/agent_1/output.jsonl | jq .
```

**Validate state:**
```bash
jq . .claude/state/autoapp_status.json
```

---

## Validation Requirements

### Agent-Level Validation (in OpenCode Agent)

Each OpenCode agent should:
1. Run syntax checks after writing code
2. Run linters (ESLint, Prettier)
3. Fix issues iteratively
4. Run relevant tests
5. Emit `<promise>COMPLETE</promise>` only when all checks pass

### Trial-Level Validation (in validate-ralph)

After agent completion:
1. **Unit tests**: Run full test suite for changed files
2. **Integration tests**: If applicable
3. **Linting**: ESLint with `--max-warnings 0`
4. **Type checking**: TypeScript strict mode
5. **Manual checks**: Verify acceptance criteria from work doc

### Merge-Level Validation (in merge-ralph)

After merging each worktree:
1. **Full test suite**: All tests must pass
2. **No conflicts**: Git merge must be clean
3. **Build check**: `npm run build` succeeds
4. **Regression check**: No previously passing tests now fail

---

## Merge Strategy Details

### Dependency Detection

If your tasks have dependencies, the merge script should:

1. Parse work docs for dependency metadata
2. Build dependency graph
3. Perform topological sort
4. Merge in correct order

**Example work doc metadata:**
```yaml
---
depends_on: [001, 002]
---
```

### Conflict Resolution

On merge conflict:
1. Capture conflict markers
2. Log files with conflicts
3. Abort merge: `git merge --abort`
4. Update task status: "needs_manual_merge"
5. Provide guidance for manual resolution
6. STOP - human intervention required

### Rollback Strategy

If tests fail after merge:
1. Note the failing commit
2. Revert the merge: `git revert -m 1 HEAD`
3. Update task status: "merge_failed"
4. Log failure reason
5. Suggest retry with fix or escalation

---

## Risk Mitigation Summary

| Risk | Mitigation |
|------|------------|
| **Process orphaning** | Write PIDs to autoapp_status.json; use heartbeat files; implement cleanup in SessionEnd hook |
| **Resource exhaustion** | Limit to 4 parallel agents; use maxSteps=10; set timeout 30m; monitor system resources |
| **State corruption** | Use separate worktrees; atomic writes to JSON; lock mechanism in autoapp_status |
| **Lost output** | Append-only logs; structured output files; heartbeat monitoring |
| **No feedback loop** | tail -f output files; parse JSON events; status polling in validate-ralph |
| **Error propagation** | Capture exit codes; grep for errors; validate-ralph analyzes failures |
| **Cross-tool communication** | Standardized Ralph primitives (PRD, PROGRESS.md); documented schemas |
| **Git conflicts** | Sequential merging; abort on conflict; manual resolution required |
| **Test failures** | Validation at multiple levels; rollback on failure; escalation to human |

---

## Next Steps

1. **Review this spec** with your team
2. **Adjust schemas** to match your existing work_ledger format
3. **Create skill folders** in `.claude/skills/`
4. **Write scripts** incrementally (start with setup_worktrees.sh)
5. **Test with 1 agent** on a simple task
6. **Iterate** based on results
7. **Scale to 4 agents** once stable

---

## Questions to Resolve

1. **Work ledger format**: Does your existing format match the schema above, or should we adapt?
2. **Test commands**: What are your actual test/lint/type-check commands?
3. **Budget limits**: What are reasonable limits for max_steps, timeout, parallel agents?
4. **Escalation**: How should Claude notify you when human intervention is needed?
5. **Dependencies**: Do your tasks have dependencies, or are they always independent?

---

**This specification aligns with:**
- Ralph primitives (PRD, PROGRESS.md, validation)
- Claude Code skills system (SKILL.md, scripts, allowed-tools)
- OpenCode serve/run architecture (attach mode, JSON output)
- Tiered architecture (Claude orchestrates, OpenCode executes)
- Background execution pattern (spawn via bash, monitor via files)

Ready to implement when you approve this design! 🚀
