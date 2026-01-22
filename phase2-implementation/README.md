# Ralph Multi-Agent System - Phase 2 Implementation

**Dual-agent parallel execution with all Phase 1 critical fixes**

## What This Is

This directory contains a **fully functional Phase 2 implementation** of the Ralph multi-agent skills system. It supports running 2 OpenCode agents in parallel, with critical bug fixes from Test 1 and enhanced merge safety.

## What's Included

### 1. Skills (`.claude/skills/`)

Three Claude Code skills ready to use:
- **start-ralph** - Selects tasks, creates worktrees, spawns OpenCode agents
- **validate-ralph** - Checks completion, runs validation trials
- **merge-agent** - Merges validated branches into dev

### 2. Supporting Scripts

10 bash scripts that handle all the heavy lifting:
- `preflight.sh` - Environment checks
- `task_selector.sh` - **NEW** Parallel task selection
- `worktree_create.sh` - Git worktree creation
- `opencode_spawn.sh` - **FIXED** Background agent spawning with correct OpenCode syntax
- `check_completion.sh` - **UPDATED** Process status checking with --all mode
- `run_trials.sh` - Validation execution
- `merge_execute.sh` - **ENHANCED** Merge with mutex, npm install, and better test handling

### 3. Configuration & State

- `config.yaml` - Configuration contract (customize for your repo)
- `work_ledger.json` - Sample task list
- `work_docs/task_001.md` - Sample task specification

### 4. Documentation

- `PHASE2_TEST_GUIDE.md` - Complete step-by-step testing instructions for dual agents
- Inline documentation in all skills and scripts

## Key Features (Phase 2)

✅ **Dual agent execution** - Run 2 independent tasks in parallel
✅ **Task selection logic** - Automatically select independent tasks
✅ **5-second stagger** - Prevents API rate limiting
✅ **Merge mutex** - Sequential merges prevent conflicts
✅ **Fixed OpenCode syntax** - All 6 critical issues from Test 1 resolved
✅ **npm install support** - Automatic dependency installation after merge
✅ **Better test handling** - Gracefully handles missing test scripts
✅ **File-based coordination** - All state in `.autoralph/`
✅ **OpenCode must commit** - Deterministic merging
✅ **Preflight checks** - Fail fast on environment issues
✅ **Validation trials** - Automated test execution
✅ **Conflict detection** - Git-based conflict handling
✅ **Rollback on failure** - Safe merge operations
✅ **Configuration-driven** - Portable across repos

## Critical Fixes from Test 1

All 6 issues from the Phase 1 test have been fixed:

1. ✅ **Invalid `--cwd` flag** → Now uses `cd "$WORKTREE_PATH" &&` instead
2. ✅ **Invalid `--maxSteps` flag** → Removed entirely
3. ✅ **Wrong model format** → Uses `provider/model_id` format (e.g., `anthropic/claude-sonnet-4-5`)
4. ✅ **Message/flag ordering** → Message comes BEFORE `-f` flag
5. ✅ **Missing npm install** → Automatically runs after merge when package.json changes
6. ✅ **Test script handling** → Gracefully handles projects without test scripts

## Quick Start

### 1. Copy to Your Repo

```bash
# In your test repository
cp -r phase2-implementation/.claude .
cp -r phase2-implementation/.autoralph .
cp phase2-implementation/.gitignore .
```

### 2. Setup

```bash
# Create dev branch
git checkout -b dev

# Make scripts executable
chmod +x .claude/skills/*/scripts/*.sh

# Customize config
vi .autoralph/config.yaml
```

### 3. Test

```bash
# Start Claude
claude

# Run skills for 2 parallel agents
/start-ralph
# Wait 5-10 minutes for both agents
/validate-ralph
# Merge both tasks (run twice, once per task)
/merge-agent
/merge-agent
```

See **PHASE2_TEST_GUIDE.md** for detailed instructions.

## Directory Structure

```
.claude/skills/              # Claude Code skills
├── start-ralph/
│   ├── SKILL.md            # Skill definition
│   └── scripts/            # Supporting bash scripts
│       ├── preflight.sh
│       ├── task_selector.sh    # NEW: Parallel task selection
│       ├── worktree_create.sh
│       └── opencode_spawn.sh   # FIXED: Correct OpenCode syntax
├── validate-ralph/
│   ├── SKILL.md
│   └── scripts/
│       ├── check_completion.sh
│       └── run_trials.sh
└── merge-agent/
    ├── SKILL.md
    └── scripts/
        └── merge_execute.sh

.autoralph/                  # Ralph workspace
├── config.yaml             # Configuration (customize this!)
├── work_ledger.json        # Task list (user-provided)
├── work_docs/              # Task specs (user-provided)
│   └── task_001.md
├── prompts/                # Generated (by start-ralph)
├── runs/                   # Generated (OpenCode output)
├── trials/                 # Generated (validation results)
├── merge/                  # Generated (merge plans)
└── worktrees/              # Generated (git worktrees)
```

## How It Works

### Phase 2 Workflow

```
1. User: /start-ralph
   ↓
   Claude reads config & work ledger
   ↓
   Selects 2 independent tasks (task_selector.sh)
   ↓
   For EACH task:
     - Creates git worktree (.autoralph/worktrees/task-00X)
     - Generates prompt from work doc
     - Spawns OpenCode agent in background
     - Waits 5 seconds before next agent (stagger)
   ↓
   Returns PIDs and status for BOTH agents

2. [OpenCode agent works independently]
   ↓
   Reads task spec
   ↓
   Implements feature
   ↓
   Runs tests
   ↓
   COMMITS changes ← KEY!
   ↓
   Outputs <promise>COMPLETE</promise>

3. User: /validate-ralph
   ↓
   Claude checks process status
   ↓
   Verifies completion marker
   ↓
   Checks for commits
   ↓
   Runs validation trials (tests)
   ↓
   Updates status.json and work_ledger.json

4. User: /merge-agent (run once per validated task)
   ↓
   Claude generates merge plan
   ↓
   User confirms
   ↓
   Acquires merge lock (prevents concurrent merges)
   ↓
   Merges branch into dev
   ↓
   Detects package.json changes → runs npm install
   ↓
   Runs tests after merge
   ↓
   On success: keeps merge, releases lock
   ↓
   On failure: rollback (git reset), releases lock
   ↓
   Repeat for second task
```

## Architecture Highlights

### Why Phase 2 Is Better

Phase 2 builds on Phase 1 with critical improvements:

**New in Phase 2:**
- ✨ Parallel execution - 2 agents work simultaneously
- ✨ Task selection logic - Automatically picks independent tasks
- ✨ Merge mutex - Safe sequential merges
- ✨ OpenCode command fixes - All 6 Test 1 issues resolved
- ✨ npm install support - Automatic dependency management
- ✨ Better test handling - Graceful fallback for missing scripts
- ✨ 5-second stagger - Prevents rate limiting

**Retained from Phase 1:**
- ✨ Configuration-driven (`.autoralph/config.yaml`)
- ✨ Preflight checks
- ✨ "OpenCode must commit" requirement
- ✨ Per-attempt directory structure
- ✨ Unified `.autoralph/` workspace
- ✨ Detailed validation levels
- ✨ Phased testing approach

### Key Design Decisions

1. **Deterministic Operations** - Skills use `disable-model-invocation: true` where appropriate
2. **File-Based State** - All coordination through `.autoralph/` files
3. **Explicit Commits** - OpenCode MUST commit, making merge deterministic
4. **Fail Fast** - Preflight checks catch environment issues early
5. **Conservative Phase 1** - Single agent, preserved branches, minimal retry

## What's NOT in Phase 2

Phase 2 focuses on parallel execution and critical fixes. These features come later:

- ❌ Automatic retry with error context → Phase 3
- ❌ Heartbeat monitoring → Phase 3
- ❌ Cost tracking → Phase 3
- ❌ More than 2 parallel agents → Phase 3
- ❌ Dependency analysis → Phase 3
- ❌ Complex merge ordering → Phase 3
- ❌ Dashboard/monitoring UI → Phase 4

## Testing Phases

### Phase 1 (Completed)
- 1 task, 1 agent
- Simple test case
- Validated core workflow
- **Status:** ✅ Complete with 6 identified issues

### Phase 2 (This Implementation)
- 2 tasks, 2 parallel agents
- Independent tasks only
- Validate parallel execution
- Fixed all Phase 1 issues
- **Timeline:** 20-30 minutes

### Phase 3 (Production)
- 4+ tasks with dependencies
- Complex merge scenarios
- Retry logic
- **Timeline:** 1 day

### Phase 4 (Enterprise)
- Monitoring dashboard
- Cost optimization
- CI/CD integration
- **Timeline:** 1 week

## Requirements

- Git >= 2.5
- Node.js >= 18 (for test project)
- OpenCode (latest)
- Claude Code (latest)
- Bash (for scripts)

Optional:
- `jq` for JSON parsing
- `yq` for YAML parsing (Phase 2+)

## Configuration

Edit `.autoralph/config.yaml` to customize for your repo:

```yaml
# Change this to match your test command
validate_cmd: npm test

# Change this if using a different base branch
base_branch: main

# Optionally use OpenCode server for faster startup
opencode:
  attach_url: http://localhost:4096
```

## Customization

### For Your Project

1. **Copy files** to your repo
2. **Edit config.yaml** with your test commands
3. **Create work_ledger.json** with your tasks
4. **Write work docs** with specifications
5. **Test with simple task** first

### For Different Languages

If not using Node.js/npm:

```yaml
# Python example
validate_cmd: pytest
merge_test_cmd: pytest

# Ruby example
validate_cmd: bundle exec rspec
merge_test_cmd: bundle exec rspec

# Go example
validate_cmd: go test ./...
merge_test_cmd: go test ./...
```

## Troubleshooting

See **PHASE2_TEST_GUIDE.md** for:
- Common issues and solutions for parallel execution
- Debug commands for multiple agents
- Reset procedures
- Log locations
- Merge mutex troubleshooting

## Next Steps

After Phase 2 works:

1. **Scale to 3-4 agents** in parallel
2. **Add retry logic** with error context
3. **Implement heartbeat monitoring**
4. **Add dependency-aware task scheduling**
5. **Build dashboard** for visualization
6. **Integrate cost tracking**
7. **Add CI/CD integration**

## Files You'll Customize

These files are **meant to be edited** for your project:

- ✏️ `.autoralph/config.yaml` - Configuration
- ✏️ `.autoralph/work_ledger.json` - Your tasks
- ✏️ `.autoralph/work_docs/*.md` - Your specifications

These files are **generated** and should not be edited:

- 🚫 `.autoralph/status.json` - Runtime state
- 🚫 `.autoralph/prompts/` - Generated prompts
- 🚫 `.autoralph/runs/` - Agent output
- 🚫 `.autoralph/trials/` - Validation results
- 🚫 `.autoralph/merge/` - Merge artifacts

## Support

Questions or issues? Check:

1. **PHASE2_TEST_GUIDE.md** - Detailed testing instructions for dual agents
2. **RALPH_TEST1_REPORT.md** - Analysis of Phase 1 issues and fixes
3. **RALPH_MERGED_SPECIFICATION.md** - Complete architecture
4. Skill SKILL.md files - Detailed skill documentation
5. Script comments - Inline documentation

## License

Same as parent project.

## Credits

This implementation synthesizes ideas from:
- Original Ralph loop concept
- OpenCode and Claude Code best practices
- Alternative planning approach
- Community feedback

---

**Ready to test?** Start with **PHASE2_TEST_GUIDE.md**

**Phase 1 issues?** See **RALPH_TEST1_REPORT.md** for all fixes

**Need architecture details?** Read **RALPH_MERGED_SPECIFICATION.md**

**Want to customize?** Edit `.autoralph/config.yaml`

🚀 **Phase 2: Parallel agents working together!**
