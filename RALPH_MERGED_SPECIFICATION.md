# Ralph Multi-Agent Skills - Merged Specification (Stage A)

**Version:** 2.0 (Merged Best-of-Both)
**Status:** Production-Ready Design
**Target:** Interactive Claude Code orchestrating headless OpenCode agents

---

## Executive Summary

This specification merges two complementary approaches to create a production-ready multi-agent orchestration system:

- **Interactive Claude session** orchestrates via skills
- **Headless OpenCode agents** execute coding work in parallel
- **File-based coordination** through `.autoralph/` workspace
- **Configuration-driven** for portability across repos
- **Deterministic operations** via explicit commits and gated transitions

---

## Core Architecture

### Operating Model

1. User invokes `/start-ralph` in interactive Claude session
2. Claude reads config + work ledger, selects top tasks (default: 3)
3. Claude creates worktrees, generates prompts, spawns OpenCode agents in background
4. OpenCode agents work independently, emit JSON events, **commit their changes**
5. User invokes `/validate-ralph` to check completion and run trials
6. User invokes `/merge-agent` to merge validated branches into dev

### Key Architectural Decisions

✅ **Configuration-driven** - Single `config.yaml` makes system portable
✅ **OpenCode must commit** - Makes merge deterministic (branches, not diffs)
✅ **Preflight checks** - Fail fast if environment isn't ready
✅ **Per-attempt directories** - Clear debugging lineage for retries
✅ **Heartbeat monitoring** - Detect stuck processes
✅ **Budget tracking** - Control costs and execution time
✅ **Gated transitions** - Human approval at key checkpoints

---

## Directory Structure

```
repo/
├── .claude/
│   └── skills/
│       ├── start-ralph/
│       │   ├── SKILL.md
│       │   └── scripts/
│       │       ├── preflight.sh              # Environment checks
│       │       ├── worktree_create.sh        # Create worktree + branch
│       │       └── opencode_spawn.sh         # Spawn background run
│       ├── validate-ralph/
│       │   ├── SKILL.md
│       │   └── scripts/
│       │       ├── check_completion.sh       # Check process status
│       │       ├── run_trials.sh             # Run validation tests
│       │       └── collect_logs.sh           # Aggregate logs
│       └── merge-agent/
│           ├── SKILL.md
│           └── scripts/
│               ├── merge_plan.sh             # Generate merge plan
│               ├── merge_execute.sh          # Execute merge + test
│               └── worktree_cleanup.sh       # Clean up worktrees
│
├── .autoralph/                               # Unified Ralph workspace
│   ├── config.yaml                           # Configuration contract ✨
│   ├── status.json                           # Execution state
│   ├── work_ledger.json                      # Task definitions (user-provided)
│   ├── work_docs/                            # Detailed specs (user-provided)
│   │   ├── task_001.md
│   │   ├── task_002.md
│   │   └── ...
│   ├── prompts/                              # Generated prompts per task
│   │   ├── task_001_attempt_1.md
│   │   └── ...
│   ├── runs/                                 # Per-task, per-attempt logs ✨
│   │   └── task-001/
│   │       ├── attempt-1/
│   │       │   ├── events.jsonl              # OpenCode JSON events
│   │       │   ├── stdout.log                # Shell output
│   │       │   ├── stderr.log                # Shell errors
│   │       │   ├── summary.md                # Claude-written digest
│   │       │   ├── exit.json                 # Normalized result
│   │       │   └── heartbeat                 # Liveness indicator ✨
│   │       └── attempt-2/
│   │           └── ...
│   ├── trials/                               # Validation results
│   │   ├── task_001.md
│   │   └── ...
│   ├── merge/                                # Merge planning artifacts ✨
│   │   ├── plan.md                           # Merge order + risk notes
│   │   └── failure.md                        # Failure diagnostics (if any)
│   └── worktrees/                            # Isolated git worktrees ✨
│       ├── task-001/
│       ├── task-002/
│       └── ...
│
└── .gitignore                                # Add: .autoralph/ (except config.yaml)
```

### Why `.autoralph/` Unified Directory

- **Discoverability**: "Where's the Ralph stuff?" → `.autoralph/`
- **Clean separation**: Ralph artifacts separate from source code
- **Easy gitignore**: Ignore `.autoralph/*` except `config.yaml`
- **Semantic clarity**: Everything Ralph-related in one place

---

## Configuration Contract (`.autoralph/config.yaml`)

This file makes the system **portable across repos**.

```yaml
# Ralph Configuration Contract
# This file defines the integration points for Ralph multi-agent system

# Project identification
project: my-awesome-app
schema_version: "2.0"

# Work tracking (user-provided files)
works_ledger_path: .autoralph/work_ledger.json
works_doc_path: .autoralph/work_docs

# Git configuration
base_branch: dev                               # Branch to merge into
worktree_root: .autoralph/worktrees           # Where to create worktrees

# Validation commands
validate_cmd: npm test                         # Run in worktree after completion
merge_test_cmd: npm run test:integration       # Run after merge (can equal validate_cmd)
lint_cmd: npm run lint                         # Optional: linting
type_check_cmd: npm run type-check             # Optional: type checking

# OpenCode configuration
opencode:
  attach_url: http://localhost:4096            # OpenCode server URL (optional)
  model: anthropic/claude-sonnet-4-5           # Model to use
  agent: default                               # Agent profile (optional)
  max_tries_per_item: 3                        # Retry limit per task
  max_steps: 10                                # Max tool calls per run
  json_events: true                            # Emit JSON events
  timeout_minutes: 30                          # Per-agent timeout

# Budget controls
budgets:
  max_parallel_agents: 3                       # How many agents to run simultaneously
  max_total_time_hours: 8                      # Total time budget for all work
  max_cost_usd: 50.0                          # Cost cap (if trackable)

# Selection criteria (for start-ralph)
selection:
  count: 3                                     # How many tasks to select
  criteria: priority_and_unblocked             # Selection algorithm
  min_priority: 5                              # Minimum priority to consider

# Merge configuration
merge:
  strategy: sequential                         # sequential | parallel (Stage B)
  no_ff: true                                  # Use --no-ff for traceability
  squash: false                                # Don't squash commits
  delete_branches: false                       # Keep branches after merge (for debugging)
```

---

## State File Schemas

### 1. `.autoralph/status.json` (Execution State)

Runtime state tracking. Generated and updated by skills.

```json
{
  "schema_version": "2.0",
  "session_id": "claude_session_abc123",
  "created_at": "2026-01-22T10:30:00Z",
  "updated_at": "2026-01-22T11:45:00Z",
  "status": "running",
  "base_branch": "dev",
  "base_commit": "a1b2c3d4",

  "selected_work_items": [
    {
      "work_id": "001",
      "title": "Add user authentication",
      "priority": 10,
      "source_ref": "work_docs/task_001.md",
      "selected_at": "2026-01-22T10:30:00Z"
    }
  ],

  "runs": {
    "001": {
      "work_id": "001",
      "worktree_path": ".autoralph/worktrees/task-001",
      "branch": "ralph/task-001",
      "prompt_path": ".autoralph/prompts/task_001_attempt_1.md",
      "run_dir": ".autoralph/runs/task-001/attempt-1",
      "pid": 12345,
      "attach_url": "http://localhost:4096",
      "tries_used": 1,
      "tries_remaining": 2,
      "state": "running",
      "started_at": "2026-01-22T10:35:00Z",
      "last_heartbeat": "2026-01-22T11:44:00Z",
      "exit_code": null,
      "has_commits": false
    }
  },

  "opencode_server": {
    "url": "http://localhost:4096",
    "pid": 12300,
    "status": "running",
    "started_at": "2026-01-22T10:30:00Z"
  },

  "next_actions": [
    "wait_for_runs_completion",
    "invoke_validate_ralph"
  ]
}
```

**States for `runs[].state`:**
- `queued` - Selected but not yet started
- `running` - OpenCode agent currently executing
- `needs_validation` - Run completed, awaiting trial
- `validating` - Trials currently running
- `passed` - Validation passed, ready for merge
- `retrying` - Failed but retrying with new prompt
- `failed` - Exceeded retry limit
- `complete` - Validated and ready for merge

### 2. `.autoralph/work_ledger.json` (Task Definitions)

**User-provided file**. Defines tasks to work on. Similar to PRD.

```json
{
  "project": "my-awesome-app",
  "base_branch": "dev",
  "target_branch": "dev",
  "created_at": "2026-01-20T00:00:00Z",
  "updated_at": "2026-01-22T11:45:00Z",

  "tasks": [
    {
      "id": "001",
      "title": "Add user authentication",
      "description": "Implement JWT-based authentication system",
      "priority": 10,
      "status": "in_progress",
      "work_doc": "work_docs/task_001.md",
      "dependencies": [],
      "tags": ["auth", "security"],
      "acceptance_criteria": [
        "Login form accepts email and password",
        "JWT tokens are generated and validated",
        "Protected routes redirect to login"
      ],
      "validation": {
        "tests_passing": false,
        "linting_passing": false,
        "type_check_passing": false,
        "manual_review": false
      },
      "trials": [],
      "created_at": "2026-01-20T00:00:00Z",
      "started_at": "2026-01-22T10:35:00Z",
      "completed_at": null
    },
    {
      "id": "002",
      "title": "Implement user profile API",
      "priority": 8,
      "status": "pending",
      "work_doc": "work_docs/task_002.md",
      "dependencies": ["001"],
      "acceptance_criteria": [
        "GET /api/profile returns user data",
        "PUT /api/profile updates user data",
        "Validation errors return 400"
      ]
    }
  ]
}
```

### 3. `.autoralph/work_docs/task_NNN.md` (Task Specifications)

**User-provided file**. Detailed spec for each task.

```markdown
# Task 001: Add User Authentication

## Overview
Implement a complete JWT-based authentication system with login, token validation, and protected routes.

## Technical Requirements
- Use bcrypt for password hashing (cost factor: 12)
- JWT tokens expire after 24 hours
- Refresh tokens stored in httpOnly cookies
- Rate limiting on login endpoint (5 attempts per 15 minutes)
- Password must be min 8 chars with upper/lower/digit/special

## Files to Create
- `src/auth/login.ts` - Login handler
- `src/auth/jwt.ts` - Token generation and validation
- `src/auth/middleware.ts` - Authentication middleware
- `src/auth/login.test.ts` - Unit tests

## Files to Modify
- `src/routes/index.ts` - Add auth routes
- `src/app.ts` - Add authentication middleware to protected routes
- `package.json` - Add dependencies: jsonwebtoken, bcrypt

## Acceptance Criteria
1. Login form accepts email and password
2. Invalid credentials return 401 with error message
3. Valid credentials return JWT token and set refresh cookie
4. JWT tokens are validated on protected routes
5. Expired tokens return 401
6. Tests cover: happy path, invalid credentials, expired tokens, rate limiting
7. All tests pass
8. Linting passes (no warnings)
9. Type check passes (strict mode)

## Context & Related Work
- See `docs/architecture/auth.md` for overall auth strategy
- Related to task 002 (user profile needs auth)
- Security review required before merge

## Validation
```bash
# Run these in worktree after implementation
npm test -- auth
npm run lint -- src/auth/
npm run type-check
```

## Notes
- Do NOT store passwords in plain text
- Do NOT log JWT tokens
- DO implement rate limiting
- DO write comprehensive tests
```

### 4. `.autoralph/runs/<work_id>/attempt-<n>/exit.json`

Normalized result format for each run attempt.

```json
{
  "work_id": "001",
  "attempt": 1,
  "success": true,
  "exit_code": 0,
  "completed_at": "2026-01-22T11:20:00Z",
  "duration_seconds": 450,
  "has_commits": true,
  "commit_count": 3,
  "commit_hashes": ["abc123", "def456", "ghi789"],
  "sentinel_found": true,
  "errors": [],
  "warnings": ["Unused variable on line 42"],
  "files_changed": [
    "src/auth/login.ts",
    "src/auth/jwt.ts",
    "src/auth/middleware.ts",
    "src/auth/login.test.ts"
  ],
  "next_action": "run_validation"
}
```

### 5. `.autoralph/trials/<work_id>.md`

Validation results after running trials.

```markdown
# Validation Trial: Task 001 (Attempt 1)

**Timestamp:** 2026-01-22T11:25:00Z
**Work ID:** 001
**Worktree:** .autoralph/worktrees/task-001
**Branch:** ralph/task-001

## Tests

**Command:** `npm test -- auth`
**Exit Code:** 0
**Duration:** 12.3s
**Result:** ✅ PASSED

```
 PASS  src/auth/login.test.ts
  Login Handler
    ✓ accepts valid credentials (23ms)
    ✓ rejects invalid password (18ms)
    ✓ rejects invalid email (12ms)
    ✓ rate limits after 5 attempts (45ms)

Test Suites: 1 passed, 1 total
Tests:       4 passed, 4 total
```

## Linting

**Command:** `npm run lint -- src/auth/`
**Exit Code:** 0
**Result:** ✅ PASSED

No warnings or errors.

## Type Check

**Command:** `npm run type-check`
**Exit Code:** 0
**Result:** ✅ PASSED

## Manual Checks

- [x] No sensitive data in logs
- [x] No hardcoded credentials
- [x] Rate limiting implemented correctly
- [x] Password hashing uses bcrypt cost 12

## Overall Result

**✅ PASSED** - Ready for merge

## Next Action

Ready for merge via `/merge-agent`
```

### 6. `.autoralph/merge/plan.md`

Generated before merge execution.

```markdown
# Merge Plan - Session: claude_session_abc123

**Generated:** 2026-01-22T12:00:00Z
**Base Branch:** dev
**Base Commit:** a1b2c3d4

## Tasks to Merge

| Order | Work ID | Title | Branch | Commits |
|-------|---------|-------|--------|---------|
| 1 | 002 | User profile API | ralph/task-002 | 3 |
| 2 | 001 | User authentication | ralph/task-001 | 3 |
| 3 | 004 | Email verification | ralph/task-004 | 2 |

## Merge Order Rationale

1. **task-002 first**: No dependencies, touches isolated files
2. **task-001 second**: Dependency of task-004, moderate conflict risk
3. **task-004 third**: Depends on task-001, highest conflict risk (shares auth files)

## Risk Analysis

### Conflict Hotspots

**High Risk:**
- `src/auth/routes.ts` - Modified by task-001 and task-004
- `src/app.ts` - Modified by task-001 and task-002

**Medium Risk:**
- `package.json` - Modified by all tasks (dependencies)

**Low Risk:**
- Test files (isolated)
- New files (no conflicts possible)

### File Change Summary

```
Task 001: 5 files changed, +234 -12
Task 002: 4 files changed, +156 -8
Task 004: 3 files changed, +89 -5
```

## Execution Strategy

1. Merge task-002 → run merge_test_cmd → commit
2. Merge task-001 → run merge_test_cmd → commit
3. Merge task-004 → run merge_test_cmd → commit
4. On conflict: abort, log details, stop for human review
5. On test failure: revert merge, log details, stop for human review

## Rollback Plan

Each merge is a discrete commit. On failure:
```bash
git reset --hard <pre-merge-commit>
```

All worktrees and branches preserved for debugging.

## Validation

After all merges:
- Run full test suite
- Run integration tests
- Verify all acceptance criteria met
```

---

## Skill Specifications

### Skill 1: `/start-ralph`

#### Purpose
Orchestrate the initialization of parallel OpenCode coding agents.

#### File: `.claude/skills/start-ralph/SKILL.md`

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
arguments:
  - name: count
    type: number
    description: "Number of tasks to select (overrides config)"
    required: false
---

# Start Ralph Multi-Agent Orchestration

This skill initializes the Ralph workflow by selecting tasks, creating worktrees, generating prompts, and spawning headless OpenCode agents in background.

## Prerequisites (Checked by preflight.sh)

Before invoking this skill:

1. **Environment:**
   - [ ] Git is installed and working
   - [ ] OpenCode is installed and on PATH
   - [ ] OpenCode credentials are configured
   - [ ] Repository is clean (no uncommitted changes)

2. **OpenCode Server (recommended):**
   ```bash
   opencode serve --port 4096
   export OPENCODE_SERVER_PASSWORD="your-secret"
   ```

3. **Configuration:**
   - [ ] `.autoralph/config.yaml` exists and is valid
   - [ ] `.autoralph/work_ledger.json` exists with tasks
   - [ ] Work docs exist for all tasks

4. **Base branch:**
   - [ ] `dev` branch exists and is up to date
   - [ ] Current branch is `dev` or can switch to `dev`

## Usage

```
/start-ralph
```

Or with custom count:
```
/start-ralph 5
```

## What This Skill Does

### Step 1: Preflight Checks

Run `.claude/skills/start-ralph/scripts/preflight.sh`:
- Verify git is clean
- Verify OpenCode is available
- Verify config.yaml is valid
- Verify work_ledger.json exists
- Verify OpenCode server is reachable (if attach_url configured)

If any check fails, **stop immediately** and show error.

### Step 2: Load Configuration and State

Read files:
- `.autoralph/config.yaml` → config
- `.autoralph/work_ledger.json` → ledger
- `.autoralph/status.json` → current state (create if doesn't exist)

### Step 3: Select Tasks

Select top N tasks (from config or argument) where:
- `status == "pending"` or `status == "failed"` (retryable)
- `priority >= config.selection.min_priority`
- Dependencies are met (all `dependencies[]` tasks have `status == "complete"`)

Sort by: priority DESC, then created_at ASC

### Step 4: For Each Selected Task

#### 4a. Create Worktree and Branch

Run `.claude/skills/start-ralph/scripts/worktree_create.sh <work_id>`:
```bash
#!/bin/bash
WORK_ID=$1
WORKTREE_PATH=".autoralph/worktrees/task-$WORK_ID"
BRANCH_NAME="ralph/task-$WORK_ID"
BASE_BRANCH="dev"  # from config

# Create worktree from dev branch
git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME" "$BASE_BRANCH"

echo "$WORKTREE_PATH"
```

#### 4b. Generate Prompt File

Read `work_docs/task_<work_id>.md` and generate prompt:

**Template:**
```markdown
# OpenCode Agent Instructions - Task ${work_id}

You are an OpenCode agent working in an isolated git worktree to implement this task.

## Task Specification

${work_doc_content}

## Critical Requirements

1. **You MUST commit your changes** before completing
   - Make atomic commits as you work
   - Use clear commit messages
   - Final commit message should summarize the implementation

2. **Run validation checks in the worktree**
   - After implementation, run: ${validate_cmd}
   - Fix any failures before completing

3. **Output completion marker**
   - When all work is done and tests pass, output:
   - `<promise>COMPLETE</promise>`

4. **Stay in the worktree**
   - Your working directory is: ${worktree_path}
   - Do NOT modify files outside this worktree

5. **Be thorough but concise**
   - Implement according to spec
   - Write tests as specified
   - Run linters and type checks
   - Do NOT over-engineer or add extra features

## Worktree Information

- **Worktree path:** ${worktree_path}
- **Branch:** ${branch_name}
- **Base commit:** ${base_commit}

## Validation Commands

After implementation, run these in the worktree:
- Tests: `${validate_cmd}`
- Linting: `${lint_cmd}` (if configured)
- Type check: `${type_check_cmd}` (if configured)

## Completion Checklist

Before outputting <promise>COMPLETE</promise>:
- [ ] All files created/modified as specified
- [ ] All tests passing
- [ ] Linting passing (no warnings)
- [ ] Type checking passing
- [ ] Changes committed to branch
- [ ] Acceptance criteria met

## Important

This is attempt ${attempt_number} of ${max_tries}.
You have ${max_steps} tool calls available.
Timeout: ${timeout_minutes} minutes.

Focus on implementing the specification correctly and completely.
```

Save to: `.autoralph/prompts/task_${work_id}_attempt_${attempt}.md`

#### 4c. Create Run Directory

```bash
mkdir -p .autoralph/runs/task-${work_id}/attempt-${attempt}
```

#### 4d. Spawn OpenCode Agent

Run `.claude/skills/start-ralph/scripts/opencode_spawn.sh`:

```bash
#!/bin/bash
WORK_ID=$1
WORKTREE_PATH=$2
PROMPT_FILE=$3
ATTEMPT=$4
CONFIG_FILE=".autoralph/config.yaml"

# Read config (use yq or python)
ATTACH_URL=$(yq e '.opencode.attach_url' "$CONFIG_FILE")
MODEL=$(yq e '.opencode.model' "$CONFIG_FILE")
MAX_STEPS=$(yq e '.opencode.max_steps' "$CONFIG_FILE")
TIMEOUT_MIN=$(yq e '.opencode.timeout_minutes' "$CONFIG_FILE")

# Output paths
RUN_DIR=".autoralph/runs/task-$WORK_ID/attempt-$ATTEMPT"
EVENTS_FILE="$RUN_DIR/events.jsonl"
STDOUT_FILE="$RUN_DIR/stdout.log"
STDERR_FILE="$RUN_DIR/stderr.log"
HEARTBEAT_FILE="$RUN_DIR/heartbeat"

# Build OpenCode command
CMD="timeout ${TIMEOUT_MIN}m opencode run \
  -f \"$PROMPT_FILE\" \
  --format json \
  --cwd \"$WORKTREE_PATH\" \
  --maxSteps $MAX_STEPS"

# Add attach if configured
if [ -n "$ATTACH_URL" ]; then
  CMD="$CMD --attach $ATTACH_URL"
fi

# Add model if configured
if [ -n "$MODEL" ]; then
  CMD="$CMD --model $MODEL"
fi

# Redirect output and run in background
$CMD > "$EVENTS_FILE" 2> "$STDERR_FILE" &
PID=$!

# Capture PID
echo $PID > "$RUN_DIR/pid"

# Start heartbeat monitor (touch file every 60s while process alive)
(
  while kill -0 $PID 2>/dev/null; do
    touch "$HEARTBEAT_FILE"
    sleep 60
  done
) &

# Return PID
echo $PID
```

### Step 5: Update Status

Write to `.autoralph/status.json`:
- Add selected tasks to `selected_work_items[]`
- Add run metadata to `runs[]` with state="running"
- Set `status="running"`
- Set `next_actions=["wait_for_runs_completion", "invoke_validate_ralph"]`

### Step 6: Output Summary

Show user:
```
✅ Ralph orchestration started

Selected tasks:
  1. Task 001: Add user authentication (priority: 10)
  2. Task 002: Implement user profile API (priority: 8)
  3. Task 004: Email verification system (priority: 6)

Worktrees created:
  - .autoralph/worktrees/task-001 → ralph/task-001
  - .autoralph/worktrees/task-002 → ralph/task-002
  - .autoralph/worktrees/task-004 → ralph/task-004

OpenCode agents spawned:
  - Agent 001 (PID: 12345) - timeout: 30m
  - Agent 002 (PID: 12346) - timeout: 30m
  - Agent 004 (PID: 12348) - timeout: 30m

Monitor progress:
  tail -f .autoralph/runs/task-001/attempt-1/events.jsonl | jq .

Check status:
  cat .autoralph/status.json | jq .

When agents complete, run:
  /validate-ralph
```

## Error Handling

- If preflight fails → stop, show error
- If worktree creation fails → skip task, continue with others
- If prompt generation fails → skip task, log error
- If OpenCode spawn fails → mark task as failed, continue with others

## Notes

- This skill is **deterministic** - it just runs scripts
- No LLM reasoning needed (disable-model-invocation: true)
- All logic in supporting scripts
- State tracked in status.json
```

---

### Skill 2: `/validate-ralph`

#### Purpose
Check completion status of OpenCode agents, run validation trials, decide on retry/escalation.

#### File: `.claude/skills/validate-ralph/SKILL.md`

```markdown
---
name: validate-ralph
description: "Validate completed Ralph agents and run trials"
user-invocable: true
disable-model-invocation: false
allowed-tools:
  - Read
  - Write
  - Bash
  - Grep
---

# Validate Ralph Agent Results

This skill checks the status of running/completed OpenCode agents, runs validation trials in each worktree, and determines next actions (retry, escalate, or mark complete).

## Usage

After spawning agents with `/start-ralph`, wait for them to complete, then:

```
/validate-ralph
```

You can run this multiple times to check progress of long-running agents.

## What This Skill Does

### Step 1: Read Current State

Load:
- `.autoralph/status.json` → current runs
- `.autoralph/config.yaml` → validation commands
- `.autoralph/work_ledger.json` → task definitions

### Step 2: Check Each Run

For each run in `status.json` with state="running":

#### 2a. Check Process Status

Run `.claude/skills/validate-ralph/scripts/check_completion.sh <work_id> <attempt>`:

```bash
#!/bin/bash
WORK_ID=$1
ATTEMPT=$2
RUN_DIR=".autoralph/runs/task-$WORK_ID/attempt-$ATTEMPT"
PID_FILE="$RUN_DIR/pid"
EVENTS_FILE="$RUN_DIR/events.jsonl"
HEARTBEAT_FILE="$RUN_DIR/heartbeat"

# Check if PID file exists
if [ ! -f "$PID_FILE" ]; then
  echo '{"status":"error","error":"PID file not found"}'
  exit 1
fi

PID=$(cat "$PID_FILE")

# Check if process is alive
if kill -0 $PID 2>/dev/null; then
  # Still running - check heartbeat
  HEARTBEAT_AGE=$(( $(date +%s) - $(stat -c %Y "$HEARTBEAT_FILE" 2>/dev/null || echo 0) ))
  if [ $HEARTBEAT_AGE -gt 180 ]; then
    echo "{\"status\":\"stuck\",\"heartbeat_age_seconds\":$HEARTBEAT_AGE}"
  else
    echo '{"status":"running"}'
  fi
  exit 0
fi

# Process finished - check exit code
wait $PID 2>/dev/null
EXIT_CODE=$?

# Check for completion sentinel
if grep -q '<promise>COMPLETE</promise>' "$EVENTS_FILE"; then
  SENTINEL_FOUND=true
else
  SENTINEL_FOUND=false
fi

# Check for commits in worktree
WORKTREE_PATH=".autoralph/worktrees/task-$WORK_ID"
cd "$WORKTREE_PATH"
COMMIT_COUNT=$(git rev-list --count HEAD ^dev)

echo "{\"status\":\"completed\",\"exit_code\":$EXIT_CODE,\"sentinel_found\":$SENTINEL_FOUND,\"commit_count\":$COMMIT_COUNT}"
```

Update status:
- If "running" → leave as is, show progress
- If "stuck" → mark as failed, log timeout
- If "completed" → proceed to trials

#### 2b. Run Validation Trials (if completed)

Run `.claude/skills/validate-ralph/scripts/run_trials.sh <work_id>`:

```bash
#!/bin/bash
WORK_ID=$1
WORKTREE_PATH=".autoralph/worktrees/task-$WORK_ID"
CONFIG_FILE=".autoralph/config.yaml"
TRIAL_FILE=".autoralph/trials/task_${WORK_ID}.md"

# Read validation commands from config
VALIDATE_CMD=$(yq e '.validate_cmd' "$CONFIG_FILE")
LINT_CMD=$(yq e '.lint_cmd' "$CONFIG_FILE")
TYPE_CHECK_CMD=$(yq e '.type_check_cmd' "$CONFIG_FILE")

# Enter worktree
cd "$WORKTREE_PATH"

# Initialize trial file
cat > "$TRIAL_FILE" <<EOF
# Validation Trial: Task $WORK_ID

**Timestamp:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Worktree:** $WORKTREE_PATH
**Branch:** $(git branch --show-current)

## Tests

**Command:** \`$VALIDATE_CMD\`
EOF

# Run tests
echo "**Exit Code:** " >> "$TRIAL_FILE"
$VALIDATE_CMD > /tmp/test_output_$WORK_ID.txt 2>&1
TEST_EXIT_CODE=$?
echo "$TEST_EXIT_CODE" >> "$TRIAL_FILE"

if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "**Result:** ✅ PASSED" >> "$TRIAL_FILE"
else
  echo "**Result:** ❌ FAILED" >> "$TRIAL_FILE"
  echo "\`\`\`" >> "$TRIAL_FILE"
  tail -50 /tmp/test_output_$WORK_ID.txt >> "$TRIAL_FILE"
  echo "\`\`\`" >> "$TRIAL_FILE"
fi

# Run linting if configured
if [ -n "$LINT_CMD" ]; then
  echo -e "\n## Linting\n" >> "$TRIAL_FILE"
  echo "**Command:** \`$LINT_CMD\`" >> "$TRIAL_FILE"
  $LINT_CMD > /tmp/lint_output_$WORK_ID.txt 2>&1
  LINT_EXIT_CODE=$?
  echo "**Exit Code:** $LINT_EXIT_CODE" >> "$TRIAL_FILE"
  if [ $LINT_EXIT_CODE -eq 0 ]; then
    echo "**Result:** ✅ PASSED" >> "$TRIAL_FILE"
  else
    echo "**Result:** ❌ FAILED" >> "$TRIAL_FILE"
  fi
fi

# Return overall result
if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "PASSED"
else
  echo "FAILED"
fi
```

#### 2c. Analyze Results and Decide Next Action

For each completed run, analyze:

**If ALL validations passed:**
- Mark run state="passed"
- Update work_ledger.json: status="complete", validation.tests_passing=true
- Add to merge-ready list

**If ANY validation failed:**
- Check tries_remaining
- If tries_remaining > 0:
  - Read error logs
  - Generate retry prompt with error context
  - Spawn new OpenCode run (attempt n+1)
  - Mark state="retrying"
- If tries_remaining == 0:
  - Mark state="failed"
  - Update work_ledger.json: status="failed", requires_escalation=true
  - Log for human review

### Step 3: Generate Summary

Show user:

```
Validation Summary - Task 001
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Process Status: Completed (exit code: 0)
Completion Marker: ✅ Found
Commits: 3 commits on ralph/task-001
Duration: 8m 45s

Validation Trials:
  ✅ Tests: PASSED (12/12 tests, 12.3s)
  ✅ Linting: PASSED (no warnings)
  ✅ Type Check: PASSED

Overall: ✅ PASSED - Ready for merge

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Validation Summary - Task 002
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Process Status: Completed (exit code: 0)
Completion Marker: ✅ Found
Commits: 4 commits on ralph/task-002

Validation Trials:
  ❌ Tests: FAILED (2/8 tests failing)

  Failing tests:
    - should handle 404 errors
    - should validate email format

Retry: Attempt 2 of 3 starting...
  Generated retry prompt with error context
  Spawned new agent (PID: 12999)

Overall: 🔄 RETRYING (attempt 2/3)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Validation Summary - Task 004
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Process Status: Still running
Duration: 15m 23s
Last heartbeat: 12 seconds ago

Overall: ⏳ RUNNING - Check again later

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Summary:
  1 passed (ready for merge)
  1 retrying (attempt 2/3)
  1 running (waiting)

Next Actions:
  - Wait for running/retrying agents
  - Run /validate-ralph again to recheck
  - When all pass, run /merge-agent
```

## Retry Prompt Generation

When retrying, enhance the prompt with:

```markdown
## Previous Attempt Failed

This is retry attempt ${n} of ${max_tries}.

**Previous failure reason:**
${error_summary}

**Test output excerpt:**
```
${relevant_test_failures}
```

**What to fix:**
${specific_issues_identified}

Focus on fixing these specific issues while maintaining the rest of the implementation.
```

## Error Handling

- If status.json doesn't exist → error "Run /start-ralph first"
- If no runs to validate → info "No runs to validate"
- If trial commands fail → log error, mark trial as failed
- If stuck process detected → offer to kill it

## Notes

- This skill uses LLM reasoning to analyze failure logs
- Retry prompts are generated with context from errors
- Human-readable summaries are created
```

---

### Skill 3: `/merge-agent`

#### Purpose
Generate merge plan, check for conflicts, merge validated branches into dev, run full tests.

#### File: `.claude/skills/merge-agent/SKILL.md`

```markdown
---
name: merge-agent
description: "Merge validated Ralph branches into dev"
user-invocable: true
disable-model-invocation: false
allowed-tools:
  - Read
  - Write
  - Bash
  - Grep
---

# Merge Ralph Agent Results

This skill merges completed and validated worktrees into the dev branch with conflict detection, testing, and rollback capabilities.

## Prerequisites

Before merging:
- [ ] All selected tasks have state="passed" in status.json
- [ ] All validation trials passed
- [ ] Dev branch is clean and up-to-date
- [ ] No uncommitted changes in main repo

## Usage

After all agents pass validation:

```
/merge-agent
```

## What This Skill Does

### Step 1: Verify Preconditions

Check:
- All runs in status.json have state="passed"
- No runs with state="running" or "retrying"
- Git working directory is clean
- Dev branch exists

If any check fails, **stop** and show error.

### Step 2: Generate Merge Plan

Run `.claude/skills/merge-agent/scripts/merge_plan.sh`:

```bash
#!/bin/bash
CONFIG_FILE=".autoralph/config.yaml"
STATUS_FILE=".autoralph/status.json"
PLAN_FILE=".autoralph/merge/plan.md"

mkdir -p .autoralph/merge

BASE_BRANCH=$(yq e '.base_branch' "$CONFIG_FILE")

# Get list of branches to merge
BRANCHES=($(jq -r '.runs | to_entries[] | select(.value.state=="passed") | .value.branch' "$STATUS_FILE"))

# Analyze conflicts
echo "# Merge Plan" > "$PLAN_FILE"
echo "" >> "$PLAN_FILE"
echo "**Base Branch:** $BASE_BRANCH" >> "$PLAN_FILE"
echo "**Branches to merge:** ${#BRANCHES[@]}" >> "$PLAN_FILE"
echo "" >> "$PLAN_FILE"

# For each branch, get changed files
declare -A file_counts
for branch in "${BRANCHES[@]}"; do
  files=$(git diff --name-only "$BASE_BRANCH...$branch")
  for file in $files; do
    ((file_counts[$file]++))
  done
done

# Identify hotspots (files changed by multiple branches)
echo "## Conflict Hotspots" >> "$PLAN_FILE"
echo "" >> "$PLAN_FILE"
for file in "${!file_counts[@]}"; do
  count=${file_counts[$file]}
  if [ $count -gt 1 ]; then
    echo "- **$file** (modified by $count branches)" >> "$PLAN_FILE"
  fi
done

# Recommend merge order (lowest conflict risk first)
# Simple heuristic: fewer file changes = lower risk
echo "" >> "$PLAN_FILE"
echo "## Recommended Merge Order" >> "$PLAN_FILE"
echo "" >> "$PLAN_FILE"

for branch in "${BRANCHES[@]}"; do
  file_count=$(git diff --name-only "$BASE_BRANCH...$branch" | wc -l)
  echo "$file_count $branch"
done | sort -n | awk '{print NR". "$2" ("$1" files)"}'  >> "$PLAN_FILE"
```

The merge plan is a Claude-reasoning task. Analyze:
- Which files are touched by multiple branches
- Dependencies between tasks
- Optimal merge order (dependencies first, low-risk first)

Write detailed plan to `.autoralph/merge/plan.md`.

### Step 3: Show Plan and Request Confirmation

Display the plan to user and ask:

```
Merge Plan Generated
━━━━━━━━━━━━━━━━━━━━

Base Branch: dev
Tasks to merge: 3

Merge Order:
  1. ralph/task-002 (4 files, no dependencies)
  2. ralph/task-001 (5 files, dependency of task-004)
  3. ralph/task-004 (3 files, depends on task-001)

Conflict Hotspots (HIGH RISK):
  - src/auth/routes.ts (modified by task-001 and task-004)
  - package.json (modified by all tasks)

Strategy:
  - Sequential merge (one at a time)
  - Run tests after each merge
  - Abort on conflict or test failure
  - Rollback plan available

This plan has been saved to .autoralph/merge/plan.md

Proceed with merge? (yes/no)
```

Wait for user confirmation.

### Step 4: Execute Merge

For each branch in merge order:

#### 4a. Merge Branch

Run `.claude/skills/merge-agent/scripts/merge_execute.sh <branch>`:

```bash
#!/bin/bash
BRANCH=$1
CONFIG_FILE=".autoralph/config.yaml"
WORK_ID=$(echo $BRANCH | sed 's/ralph\/task-//')

BASE_BRANCH=$(yq e '.base_branch' "$CONFIG_FILE")
MERGE_TEST_CMD=$(yq e '.merge_test_cmd' "$CONFIG_FILE")
NO_FF=$(yq e '.merge.no_ff' "$CONFIG_FILE")

# Record pre-merge state
PRE_MERGE_SHA=$(git rev-parse HEAD)
echo $PRE_MERGE_SHA > .autoralph/merge/pre_merge_sha_$WORK_ID

# Switch to base branch
git checkout "$BASE_BRANCH"

# Merge
if [ "$NO_FF" = "true" ]; then
  git merge --no-ff "$BRANCH" -m "Merge task $WORK_ID: $(git log -1 --pretty=%s $BRANCH)"
else
  git merge "$BRANCH"
fi

MERGE_EXIT_CODE=$?

if [ $MERGE_EXIT_CODE -ne 0 ]; then
  echo "CONFLICT"
  # Abort merge
  git merge --abort
  exit 1
fi

# Run tests
$MERGE_TEST_CMD
TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -ne 0 ]; then
  echo "TEST_FAILED"
  # Rollback
  git reset --hard "$PRE_MERGE_SHA"
  exit 2
fi

echo "SUCCESS"
exit 0
```

#### 4b. Handle Results

**On success:**
- Mark task as merged in work_ledger.json
- Continue to next branch

**On conflict:**
- Abort merge
- Write conflict details to `.autoralph/merge/failure.md`
- Show user which files have conflicts
- Stop and request manual resolution

**On test failure:**
- Rollback (reset to pre-merge SHA)
- Write failure details to `.autoralph/merge/failure.md`
- Show user which tests failed
- Stop and request human review

### Step 5: Cleanup (if all merges succeed)

Run `.claude/skills/merge-agent/scripts/worktree_cleanup.sh`:

```bash
#!/bin/bash
STATUS_FILE=".autoralph/status.json"
CONFIG_FILE=".autoralph/config.yaml"

DELETE_BRANCHES=$(yq e '.merge.delete_branches' "$CONFIG_FILE")

# Get all merged worktrees
WORKTREES=($(jq -r '.runs | to_entries[] | select(.value.state=="passed") | .value.worktree_path' "$STATUS_FILE"))
BRANCHES=($(jq -r '.runs | to_entries[] | select(.value.state=="passed") | .value.branch' "$STATUS_FILE"))

# Remove worktrees
for worktree in "${WORKTREES[@]}"; do
  git worktree remove "$worktree"
  echo "Removed worktree: $worktree"
done

# Optionally delete branches
if [ "$DELETE_BRANCHES" = "true" ]; then
  for branch in "${BRANCHES[@]}"; do
    git branch -d "$branch"
    echo "Deleted branch: $branch"
  done
fi
```

### Step 6: Update State and Show Summary

Update status.json:
- Set merged runs to state="merged"
- Update work_ledger.json: status="merged"
- Archive status.json to `.autoralph/archive/session_${session_id}.json`

Show summary:

```
✅ Merge Complete

Merged Tasks:
  ✅ Task 001: Add user authentication (3 commits)
  ✅ Task 002: Implement user profile API (4 commits)
  ✅ Task 004: Email verification system (2 commits)

Total changes merged:
  - 9 commits
  - 12 files changed
  - +479 lines, -25 lines deleted

All tests passed after merge.

Cleanup:
  - Removed 3 worktrees
  - Kept branches for reference (config: delete_branches=false)

Work Ledger Status:
  - 3 tasks completed
  - 5 tasks remaining

Next Actions:
  - Review merged changes: git log --oneline -10
  - Push to remote: git push origin dev
  - Start next iteration: /start-ralph
```

## Failure Scenarios

### Merge Conflict

```
❌ Merge Failed: Conflict Detected

Task 004 (ralph/task-004) has conflicts with dev branch.

Conflicting files:
  - src/auth/routes.ts

The merge has been aborted. No changes were made to dev branch.

Resolution:
  1. Review the conflict in .autoralph/merge/failure.md
  2. Manually merge the branch:
     cd .autoralph/worktrees/task-004
     git checkout dev
     git merge ralph/task-004
  3. Resolve conflicts manually
  4. Update work_ledger.json: status="merged"
  5. Run /merge-agent again for remaining tasks
```

### Test Failure After Merge

```
❌ Merge Failed: Tests Failed

Task 001 (ralph/task-001) was merged but tests failed.

The merge has been rolled back. Dev branch restored to pre-merge state.

Failed tests:
  - src/auth/login.test.ts: should handle rate limiting

Root cause: Possible integration issue with existing code.

Resolution:
  1. Review failure details in .autoralph/merge/failure.md
  2. Investigate test failure in worktree
  3. Fix issue and revalidate
  4. Retry merge
```

## Error Handling

- If preconditions fail → stop, show which precondition failed
- If merge plan generation fails → log error, stop
- If user declines merge → stop, no changes made
- If any merge fails → abort remaining merges, preserve state
- All rollbacks logged to `.autoralph/merge/failure.md`

## Notes

- This skill uses LLM reasoning for merge planning
- Conflict detection is deterministic (git)
- Rollback is always safe (git reset)
- Branches and worktrees preserved for debugging
```

---

## Environment Setup (Preflight Checklist)

### System Requirements

1. **Git >= 2.5** (for `git worktree`)
   ```bash
   git --version
   ```

2. **OpenCode** (latest)
   ```bash
   opencode --version
   opencode auth status
   ```

3. **Claude Code** (latest)
   ```bash
   claude --version
   ```

4. **Helper tools** (for scripts)
   - `jq` - JSON parsing
   - `yq` - YAML parsing
   ```bash
   brew install jq yq  # macOS
   sudo apt install jq  # Linux (yq via snap or go install)
   ```

### OpenCode Server Setup

For best performance, run persistent server:

```bash
# Start server
opencode serve --port 4096 --hostname 127.0.0.1

# In another terminal
export OPENCODE_SERVER_PASSWORD="$(openssl rand -hex 16)"

# Test connection
curl http://localhost:4096/health
```

Or use systemd/PM2 for production:

```ini
# /etc/systemd/system/opencode-ralph.service
[Unit]
Description=OpenCode Server for Ralph
After=network.target

[Service]
Type=simple
User=youruser
WorkingDirectory=/home/youruser
ExecStart=/usr/local/bin/opencode serve --port 4096
Restart=always

[Install]
WantedBy=multi-user.target
```

### Repository Setup

1. **Create dev branch** (if doesn't exist)
   ```bash
   git checkout -b dev main
   git push -u origin dev
   ```

2. **Create Ralph structure**
   ```bash
   mkdir -p .claude/skills/{start-ralph,validate-ralph,merge-agent}/scripts
   mkdir -p .autoralph/{work_docs,prompts,runs,trials,merge,worktrees}
   ```

3. **Add to .gitignore**
   ```gitignore
   # Ralph working files
   .autoralph/*
   !.autoralph/config.yaml
   !.autoralph/work_ledger.json
   !.autoralph/work_docs/
   ```

4. **Create initial config**
   ```bash
   cp .autoralph/config.yaml.template .autoralph/config.yaml
   # Edit config.yaml for your repo
   ```

---

## Phase 1 Implementation (Minimal Viable Test)

### Goal
Test the entire workflow with **ONE task** to validate all components.

### Phase 1 Scope

**What to build:**
- All 3 skill SKILL.md files (simplified)
- Minimal supporting scripts (bash only, no yq dependency)
- One test task in work ledger
- Basic status.json tracking

**What to defer:**
- Full error handling
- Retry logic
- Complex merge planning
- Cost tracking
- Heartbeat monitoring (optional)

### Phase 1 Test Task

Create a trivial task to validate the workflow:

**`.autoralph/work_ledger.json`:**
```json
{
  "project": "test-ralph",
  "base_branch": "dev",
  "tasks": [
    {
      "id": "001",
      "title": "Add simple utility function",
      "priority": 10,
      "status": "pending",
      "work_doc": "work_docs/task_001.md",
      "dependencies": [],
      "acceptance_criteria": [
        "Function add(a, b) returns a + b",
        "Tests pass"
      ]
    }
  ]
}
```

**`.autoralph/work_docs/task_001.md`:**
```markdown
# Task 001: Add Simple Utility Function

## Overview
Create a basic math utility function for testing Ralph workflow.

## Files to Create
- `src/utils/math.js` - Add function
- `src/utils/math.test.js` - Tests

## Implementation

Create `src/utils/math.js`:
```javascript
export function add(a, b) {
  return a + b;
}
```

Create `src/utils/math.test.js`:
```javascript
import { add } from './math.js';

test('adds two numbers', () => {
  expect(add(2, 3)).toBe(5);
});
```

## Acceptance Criteria
1. Function exists and works
2. Tests pass: `npm test -- math`
3. File is committed to branch

## Validation
```bash
npm test -- math
```

## Notes
This is a simple test to validate Ralph workflow.
```

### Phase 1 Scripts (Simplified)

**`.claude/skills/start-ralph/scripts/preflight.sh`:**
```bash
#!/bin/bash
set -e

echo "Running preflight checks..."

# Check git
if ! command -v git &> /dev/null; then
  echo "ERROR: git not found"
  exit 1
fi

# Check clean repo
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: Repository has uncommitted changes"
  exit 1
fi

# Check OpenCode
if ! command -v opencode &> /dev/null; then
  echo "ERROR: opencode not found"
  exit 1
fi

# Check config exists
if [ ! -f ".autoralph/config.yaml" ]; then
  echo "ERROR: .autoralph/config.yaml not found"
  exit 1
fi

echo "✅ All preflight checks passed"
```

**`.claude/skills/start-ralph/scripts/worktree_create.sh`:**
```bash
#!/bin/bash
WORK_ID=$1
WORKTREE_PATH=".autoralph/worktrees/task-$WORK_ID"
BRANCH_NAME="ralph/task-$WORK_ID"
BASE_BRANCH="dev"

# Create worktree
git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME" "$BASE_BRANCH"

echo "$WORKTREE_PATH"
```

**`.claude/skills/start-ralph/scripts/opencode_spawn.sh`:**
```bash
#!/bin/bash
WORK_ID=$1
WORKTREE_PATH=$2
PROMPT_FILE=$3
ATTEMPT=${4:-1}

RUN_DIR=".autoralph/runs/task-$WORK_ID/attempt-$ATTEMPT"
EVENTS_FILE="$RUN_DIR/events.jsonl"
mkdir -p "$RUN_DIR"

# Spawn OpenCode (simplified, no attach)
timeout 30m opencode run \
  -f "$PROMPT_FILE" \
  --format json \
  --cwd "$WORKTREE_PATH" \
  --maxSteps 10 \
  > "$EVENTS_FILE" 2>&1 &

PID=$!
echo $PID > "$RUN_DIR/pid"
echo $PID
```

**`.claude/skills/validate-ralph/scripts/check_completion.sh`:**
```bash
#!/bin/bash
WORK_ID=$1
ATTEMPT=${2:-1}
RUN_DIR=".autoralph/runs/task-$WORK_ID/attempt-$ATTEMPT"
PID_FILE="$RUN_DIR/pid"
EVENTS_FILE="$RUN_DIR/events.jsonl"

if [ ! -f "$PID_FILE" ]; then
  echo '{"status":"error"}'
  exit 1
fi

PID=$(cat "$PID_FILE")

if kill -0 $PID 2>/dev/null; then
  echo '{"status":"running"}'
  exit 0
fi

# Check for completion sentinel
if grep -q '<promise>COMPLETE</promise>' "$EVENTS_FILE" 2>/dev/null; then
  echo '{"status":"completed","sentinel_found":true}'
else
  echo '{"status":"completed","sentinel_found":false}'
fi
```

**`.claude/skills/validate-ralph/scripts/run_trials.sh`:**
```bash
#!/bin/bash
WORK_ID=$1
WORKTREE_PATH=".autoralph/worktrees/task-$WORK_ID"
TRIAL_FILE=".autoralph/trials/task_${WORK_ID}.md"

cd "$WORKTREE_PATH"

# Run tests (simplified)
echo "# Validation Trial: Task $WORK_ID" > "$TRIAL_FILE"
echo "" >> "$TRIAL_FILE"
echo "**Command:** npm test" >> "$TRIAL_FILE"

npm test > /tmp/test_output_$WORK_ID.txt 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "**Result:** ✅ PASSED" >> "$TRIAL_FILE"
  echo "PASSED"
else
  echo "**Result:** ❌ FAILED" >> "$TRIAL_FILE"
  echo "FAILED"
fi
```

**`.claude/skills/merge-agent/scripts/merge_execute.sh`:**
```bash
#!/bin/bash
BRANCH=$1
BASE_BRANCH="dev"

# Record pre-merge state
PRE_MERGE_SHA=$(git rev-parse HEAD)

# Switch to base branch
git checkout "$BASE_BRANCH"

# Merge
git merge --no-ff "$BRANCH" -m "Merge $BRANCH"

if [ $? -ne 0 ]; then
  echo "CONFLICT"
  git merge --abort
  exit 1
fi

# Run tests
npm test
if [ $? -ne 0 ]; then
  echo "TEST_FAILED"
  git reset --hard "$PRE_MERGE_SHA"
  exit 2
fi

echo "SUCCESS"
```

---

## Testing Phase 1

### Step-by-Step Test

1. **Setup**
   ```bash
   cd your-repo
   git checkout dev

   # Copy Phase 1 files
   # Create config, work ledger, work doc

   # Make scripts executable
   chmod +x .claude/skills/*/scripts/*.sh
   ```

2. **Start OpenCode server** (optional but recommended)
   ```bash
   opencode serve --port 4096
   ```

3. **Start Claude interactive session**
   ```bash
   claude
   ```

4. **Invoke start-ralph**
   ```
   /start-ralph
   ```

   Expected output:
   - Preflight checks pass
   - Worktree created
   - Prompt generated
   - OpenCode spawned (PID shown)

5. **Monitor progress** (optional)
   ```bash
   tail -f .autoralph/runs/task-001/attempt-1/events.jsonl
   ```

6. **Wait for completion** (2-5 minutes)

7. **Invoke validate-ralph**
   ```
   /validate-ralph
   ```

   Expected output:
   - Process status: completed
   - Sentinel found: yes
   - Tests: PASSED
   - Overall: PASSED

8. **Invoke merge-agent**
   ```
   /merge-agent
   ```

   Expected output:
   - Merge plan generated
   - Merge executed successfully
   - Tests passed after merge
   - Worktree cleaned up

9. **Verify result**
   ```bash
   git log --oneline -5
   git show HEAD
   ```

### Success Criteria

✅ All skills executed without errors
✅ Worktree created and branch merged
✅ OpenCode agent completed and committed changes
✅ Tests passed in worktree and after merge
✅ Status.json tracked state correctly

---

## Migration Path (Stage A → Stage B)

After Stage A is working, future enhancements:

### Stage B: Parallel Execution (2-3 agents)
- Test with 2 independent tasks
- Handle resource contention
- Parallel validation

### Stage C: Full Scale (4+ agents)
- Test with 4+ tasks
- Advanced merge conflict resolution
- Cost optimization

### Stage D: Production Hardening
- Error recovery mechanisms
- Automatic retry with learning
- Dashboard/monitoring
- Integration with CI/CD

---

## Key Differences from Original Plans

### From Original Plan (Mine)
✅ Kept: Heartbeat monitoring, budget tracking, risk documentation, phased testing
✅ Improved: Moved to `.autoralph/`, better file organization

### From Alternative Plan
✅ Kept: Configuration contract, preflight checks, commit requirement, per-attempt dirs
✅ Enhanced: Added heartbeat, budget tracking, detailed validation structure

### Merged Benefits
✨ **Configuration-driven** - Portable across repos
✨ **Deterministic operations** - OpenCode MUST commit
✨ **Clear debugging** - Per-attempt directories
✨ **Fail fast** - Preflight checks
✨ **Production-ready** - Budget controls, monitoring, rollback

---

## Summary

This merged specification provides a **production-ready, portable, debuggable** multi-agent orchestration system that:

1. **Works in any repo** with just `config.yaml` customization
2. **Has clear failure modes** and debugging paths via per-attempt logs
3. **Tracks costs** and enforces budgets to prevent runaway execution
4. **Scales safely** from 1 to 4+ agents with phased testing
5. **Handles retries** and conflicts gracefully with rollback
6. **Requires explicit commits** making merge deterministic and safe
7. **Uses file-based coordination** for crash-safety and auditability
8. **Separates concerns** (task definitions vs execution state vs validation)

**Start with Phase 1** (single agent, simple task) to validate the workflow, then scale incrementally.

🚀 **Ready to implement!**
