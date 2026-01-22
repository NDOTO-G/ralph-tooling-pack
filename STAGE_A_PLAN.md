# Stage A — "Live Agent" Skill Testing Plan

## Overview

Stage A establishes the foundational skills for running Ralph loops interactively and autonomously. These skills encapsulate the core operations: starting a new Ralph session, validating iteration results, merging completed work, and autonomous execution.

---

## Skill Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        RALPH LOOP                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│   │ start-ralph  │───▶│validate-ralph│───▶│ merge-agent  │     │
│   └──────────────┘    └──────────────┘    └──────────────┘     │
│         │                    │                   │              │
│         ▼                    ▼                   ▼              │
│   • Select top 3       • Read artifacts    • Merge plan        │
│   • Write prompts      • Check tests       • Risk check        │
│   • Init PRD           • Decide next       • Gate release      │
│                                                                 │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │                   ralph-auto                             │  │
│   │  (Autonomous runner - orchestrates above skills)         │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Skill Definitions

### 1. `/start-ralph` — Initialize New Ralph Session

**Purpose:** Bootstrap a new Ralph loop by selecting the top priority items from a backlog and generating initial prompt files.

**Inputs:**
- Backlog file (issues.json, TODO.md, or GitHub issues)
- Optional: max_stories (default: 3)
- Optional: target_branch name

**Outputs:**
- `ralph/prd.json` — PRD with top 3 prioritized stories
- `ralph/prompts/iteration_1.md` — First iteration prompt
- `ralph/progress.md` — Initialized progress log
- `ralph/config.json` — Loop configuration

**Flow:**
1. Read backlog source (file or API)
2. Score and rank items by priority/impact/feasibility
3. Select top N stories (default 3)
4. Generate PRD with acceptance criteria
5. Write first iteration prompt
6. Initialize progress log
7. Output confirmation with next steps

---

### 2. `/validate-ralph` — Validate Iteration Results

**Purpose:** Analyze artifacts from a completed iteration and determine next actions.

**Inputs:**
- Iteration artifacts (events.jsonl, diff.patch, test output)
- Current PRD state
- Progress log

**Outputs:**
- Validation report
- Decision: CONTINUE | RETRY | ESCALATE | COMPLETE
- Updated PRD (if story completed)
- Next iteration prompt (if continuing)

**Flow:**
1. Parse event stream for completion sentinel
2. Read test output, check pass/fail
3. Analyze diff for scope creep or unintended changes
4. Cross-reference with acceptance criteria
5. Decide action:
   - CONTINUE: Story passed, more stories remain
   - RETRY: Story failed, generate retry prompt with errors
   - ESCALATE: Multiple failures, flag for human review
   - COMPLETE: All stories done
6. Update progress log with decision
7. Generate next prompt if continuing

---

### 3. `/merge-agent` — Merge Plan with Risk Check

**Purpose:** Safely merge completed Ralph work after validation and risk assessment.

**Inputs:**
- Completed branch
- PRD with all stories marked passes: true
- Progress log (audit trail)

**Outputs:**
- Risk assessment report
- Merge status (APPROVED | BLOCKED | NEEDS_REVIEW)
- PR creation (if approved)

**Flow:**
1. Verify all stories in PRD are complete
2. Run risk checks:
   - Security scan (no secrets, no vulnerable deps)
   - Breaking change detection
   - Test coverage delta
   - Diff size sanity check
3. Generate risk assessment report
4. If APPROVED:
   - Create PR with summary from progress log
   - Include evidence links
5. If BLOCKED:
   - Document blockers
   - Suggest remediation
6. Output merge status and next steps

---

### 4. `/ralph-auto` — Autonomous Loop Runner

**Purpose:** Run Ralph loops autonomously when invoked by external orchestration (cron, CI, webhook).

**Inputs:**
- Mode: INIT | ITERATE | VALIDATE | FINALIZE
- State directory path
- Optional: max_iterations, timeout

**Outputs:**
- Structured status report (JSON)
- Updated state files
- Sentinel for orchestrator

**Flow:**
```
MODE=INIT:
  1. Call /start-ralph internally
  2. Output: {"status": "initialized", "next_mode": "ITERATE"}

MODE=ITERATE:
  1. Read current PRD and progress
  2. Select next uncomplete story
  3. Generate iteration prompt
  4. Execute iteration (invoke agent)
  5. Output: {"status": "iteration_complete", "iteration": N}

MODE=VALIDATE:
  1. Call /validate-ralph internally
  2. Output decision and next mode:
     - CONTINUE → {"next_mode": "ITERATE"}
     - COMPLETE → {"next_mode": "FINALIZE"}
     - ESCALATE → {"next_mode": "PAUSE", "reason": "..."}

MODE=FINALIZE:
  1. Call /merge-agent internally
  2. Output final status
  3. Cleanup temp files
```

**Orchestration Protocol:**
```bash
# External harness calls:
opencode run -p "Run /ralph-auto with MODE=INIT"
# ... polls for completion ...
opencode run -p "Run /ralph-auto with MODE=ITERATE"
# ... repeats until FINALIZE ...
```

---

## File Structure

```
.opencode/skills/
├── start-ralph/
│   └── SKILL.md
├── validate-ralph/
│   └── SKILL.md
├── merge-agent/
│   └── SKILL.md
└── ralph-auto/
    └── SKILL.md

ralph/                    # Created at runtime
├── prd.json
├── progress.md
├── config.json
├── prompts/
│   ├── iteration_1.md
│   ├── iteration_2.md
│   └── ...
└── artifacts/
    ├── iteration_1_events.jsonl
    ├── iteration_1_diff.patch
    └── ...
```

---

## Configuration (opencode.json additions)

```json
{
  "permission": {
    "skill": [
      { "pattern": "start-ralph", "decision": "allow" },
      { "pattern": "validate-ralph", "decision": "allow" },
      { "pattern": "merge-agent", "decision": "ask" },
      { "pattern": "ralph-auto", "decision": "allow" }
    ]
  }
}
```

---

## Testing Plan

### Unit Tests (per skill)
1. **start-ralph**: Mock backlog → verify PRD structure, prompt generation
2. **validate-ralph**: Mock artifacts → verify decision logic
3. **merge-agent**: Mock diff → verify risk detection
4. **ralph-auto**: Mock state transitions → verify mode handling

### Integration Tests
1. Full loop: INIT → ITERATE (×3) → VALIDATE → FINALIZE
2. Failure recovery: Inject test failures → verify RETRY path
3. Escalation: Inject repeated failures → verify ESCALATE path

### Live Testing (Stage A Goal)
1. Run against a real small project (e.g., add 3 utility functions)
2. Monitor token usage, timing, success rate
3. Collect feedback for Stage B refinements

---

## Success Criteria for Stage A

- [ ] All 4 skills created and loadable
- [ ] `/start-ralph` successfully generates PRD from sample backlog
- [ ] `/validate-ralph` correctly classifies PASS/FAIL iterations
- [ ] `/merge-agent` blocks on obvious security issues
- [ ] `/ralph-auto` completes full loop on toy project
- [ ] Documentation updated with usage examples

---

## Next Steps

1. Create skill files in `.opencode/skills/`
2. Test each skill in isolation
3. Run full integration test
4. Document learnings for Stage B
