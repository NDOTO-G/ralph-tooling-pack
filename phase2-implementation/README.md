# Ralph Multi-Agent System - Phase 1 Implementation

**Complete, ready-to-test implementation of the Ralph orchestration system**

## What This Is

This directory contains a **fully functional Phase 1 implementation** of the Ralph multi-agent skills system. It merges the best ideas from both planning approaches into a working, testable system.

## What's Included

### 1. Skills (`.claude/skills/`)

Three Claude Code skills ready to use:
- **start-ralph** - Selects tasks, creates worktrees, spawns OpenCode agents
- **validate-ralph** - Checks completion, runs validation trials
- **merge-agent** - Merges validated branches into dev

### 2. Supporting Scripts

9 bash scripts that handle all the heavy lifting:
- `preflight.sh` - Environment checks
- `worktree_create.sh` - Git worktree creation
- `opencode_spawn.sh` - Background agent spawning
- `check_completion.sh` - Process status checking
- `run_trials.sh` - Validation execution
- `merge_execute.sh` - Merge and rollback

### 3. Configuration & State

- `config.yaml` - Configuration contract (customize for your repo)
- `work_ledger.json` - Sample task list
- `work_docs/task_001.md` - Sample task specification

### 4. Documentation

- `PHASE1_TEST_GUIDE.md` - Complete step-by-step testing instructions
- Inline documentation in all skills and scripts

## Key Features (Phase 1)

✅ **Single agent execution** - Test with one task first
✅ **File-based coordination** - All state in `.autoralph/`
✅ **OpenCode must commit** - Deterministic merging
✅ **Preflight checks** - Fail fast on environment issues
✅ **Validation trials** - Automated test execution
✅ **Conflict detection** - Git-based conflict handling
✅ **Rollback on failure** - Safe merge operations
✅ **Configuration-driven** - Portable across repos

## Quick Start

### 1. Copy to Your Repo

```bash
# In your test repository
cp -r phase1-implementation/.claude .
cp -r phase1-implementation/.autoralph .
cp phase1-implementation/.gitignore .
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

# Run skills
/start-ralph
# Wait 2-5 minutes
/validate-ralph
/merge-agent
```

See **PHASE1_TEST_GUIDE.md** for detailed instructions.

## Directory Structure

```
.claude/skills/              # Claude Code skills
├── start-ralph/
│   ├── SKILL.md            # Skill definition
│   └── scripts/            # Supporting bash scripts
│       ├── preflight.sh
│       ├── worktree_create.sh
│       └── opencode_spawn.sh
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

### Phase 1 Workflow

```
1. User: /start-ralph
   ↓
   Claude reads config & work ledger
   ↓
   Creates git worktree (.autoralph/worktrees/task-001)
   ↓
   Generates prompt from work doc
   ↓
   Spawns OpenCode agent in background
   ↓
   Returns PID and status

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

4. User: /merge-agent
   ↓
   Claude generates merge plan
   ↓
   User confirms
   ↓
   Merges branch into dev
   ↓
   Runs tests after merge
   ↓
   On success: keeps merge
   ↓
   On failure: rollback (git reset)
```

## Architecture Highlights

### Why It's Better

This implementation combines the best of both design approaches:

**From Alternative Plan:**
- ✨ Configuration-driven (`.autoralph/config.yaml`)
- ✨ Preflight checks
- ✨ "OpenCode must commit" requirement
- ✨ Per-attempt directory structure
- ✨ Unified `.autoralph/` workspace

**From Original Plan:**
- ✨ Heartbeat monitoring (Phase 2)
- ✨ Budget tracking (Phase 2)
- ✨ Detailed validation levels
- ✨ Risk documentation
- ✨ Phased testing approach

### Key Design Decisions

1. **Deterministic Operations** - Skills use `disable-model-invocation: true` where appropriate
2. **File-Based State** - All coordination through `.autoralph/` files
3. **Explicit Commits** - OpenCode MUST commit, making merge deterministic
4. **Fail Fast** - Preflight checks catch environment issues early
5. **Conservative Phase 1** - Single agent, preserved branches, minimal retry

## What's NOT in Phase 1

Phase 1 is intentionally simple. These features come later:

- ❌ Parallel execution (2+ agents) → Phase 2
- ❌ Automatic retry with error context → Phase 2
- ❌ Heartbeat monitoring → Phase 2
- ❌ Cost tracking → Phase 2
- ❌ Dependency analysis → Phase 3
- ❌ Complex merge ordering → Phase 3
- ❌ Dashboard/monitoring UI → Phase 4

## Testing Phases

### Phase 1 (This Implementation)
- 1 task, 1 agent
- Simple test case
- Validate core workflow
- **Timeline:** 10 minutes

### Phase 2 (Next Step)
- 2-3 tasks, parallel agents
- Independent tasks
- Validate parallel execution
- **Timeline:** 1 hour

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

See **PHASE1_TEST_GUIDE.md** for:
- Common issues and solutions
- Debug commands
- Reset procedures
- Log locations

## Next Steps

After Phase 1 works:

1. **Add more tasks** to work_ledger.json
2. **Test parallel execution** (Phase 2)
3. **Add retry logic** for failures
4. **Implement heartbeat monitoring**
5. **Build dashboard** for visualization
6. **Integrate with CI/CD**

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

1. **PHASE1_TEST_GUIDE.md** - Detailed testing instructions
2. **RALPH_MERGED_SPECIFICATION.md** - Complete architecture
3. Skill SKILL.md files - Detailed skill documentation
4. Script comments - Inline documentation

## License

Same as parent project.

## Credits

This implementation synthesizes ideas from:
- Original Ralph loop concept
- OpenCode and Claude Code best practices
- Alternative planning approach
- Community feedback

---

**Ready to test?** Start with **PHASE1_TEST_GUIDE.md**

**Need details?** Read **RALPH_MERGED_SPECIFICATION.md**

**Want to customize?** Edit `.autoralph/config.yaml`

🚀 **Let's build something amazing with Ralph!**
