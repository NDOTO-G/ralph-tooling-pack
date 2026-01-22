---
name: merge-agent
description: "Merge completed Ralph work after risk assessment and validation"
user-invocable: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
disable-model-invocation: true
---

# Merge Agent — Safe Merge with Risk Check

You are preparing to merge completed Ralph work. Perform thorough risk assessment before approving.

## Pre-Conditions

Verify before proceeding:
1. `ralph/READY_TO_MERGE.md` exists (from validate-ralph COMPLETE)
2. All stories in `ralph/prd.json` have `passes: true`
3. No `ralph/ESCALATED.md` present

If pre-conditions fail, output blockers and stop.

## Step 1: Load Context

Read these files:
- `ralph/prd.json` — verify all stories complete
- `ralph/progress.md` — full audit trail
- `ralph/config.json` — loop configuration

## Step 2: Gather Diff Statistics

```bash
# Get full diff from base branch
git diff main...HEAD --stat
git diff main...HEAD --numstat
```

Record:
- Files changed
- Lines added/removed
- File types affected

## Step 3: Security Scan

### 3.1 Secret Detection
```bash
# Check for potential secrets
git diff main...HEAD | grep -iE "(password|secret|api_key|token|credential)" || echo "No obvious secrets"
```

### 3.2 Sensitive File Check
Check for changes to:
- `.env*` files
- `*credentials*`
- `*secret*`
- Config files with potential secrets

### 3.3 Dependency Check
```bash
# Check for new dependencies
git diff main...HEAD -- package.json package-lock.json Cargo.toml requirements.txt go.mod
```

If new dependencies added:
- Flag for review
- Check for known vulnerabilities if tooling available

## Step 4: Breaking Change Detection

### 4.1 API Surface Changes
Search diff for:
- Removed exports
- Changed function signatures
- Renamed public interfaces
- Modified types/interfaces

### 4.2 Database/Schema Changes
Flag any:
- Migration files
- Schema modifications
- Data model changes

### 4.3 Configuration Changes
Flag changes to:
- Build configuration
- Deployment configs
- Environment requirements

## Step 5: Test Coverage Check

```bash
# Run tests and check coverage if available
npm test 2>&1 | tail -50
```

Verify:
- All tests pass
- No skipped tests that were previously running
- Coverage hasn't decreased significantly (if baseline available)

## Step 6: Diff Size Sanity

Apply size limits:
- WARN if > 500 lines changed
- BLOCK if > 2000 lines changed (likely scope creep)
- WARN if > 20 files changed
- BLOCK if > 50 files changed

## Step 7: Generate Risk Report

```markdown
# Merge Risk Assessment

## Summary
- **Decision:** <APPROVED / NEEDS_REVIEW / BLOCKED>
- **Risk Level:** <LOW / MEDIUM / HIGH / CRITICAL>
- **Confidence:** <percentage>

## Statistics
- Files changed: X
- Lines added: +Y
- Lines removed: -Z
- New dependencies: N

## Security Checks
| Check | Status | Notes |
|-------|--------|-------|
| Secret scan | PASS/WARN/FAIL | <details> |
| Sensitive files | PASS/WARN/FAIL | <details> |
| Dependencies | PASS/WARN/FAIL | <details> |

## Breaking Change Checks
| Check | Status | Notes |
|-------|--------|-------|
| API surface | PASS/WARN/FAIL | <details> |
| Database | PASS/WARN/FAIL | <details> |
| Config | PASS/WARN/FAIL | <details> |

## Quality Checks
| Check | Status | Notes |
|-------|--------|-------|
| Tests | PASS/FAIL | X/Y passing |
| Coverage | PASS/WARN | <delta> |
| Diff size | PASS/WARN/FAIL | <stats> |

## Blockers
<list any FAIL items that block merge>

## Warnings
<list WARN items for reviewer attention>

## Stories Completed
<list from PRD>

## Recommendation
<detailed recommendation based on findings>
```

## Step 8: Take Action

### If APPROVED (no FAIL, low/medium risk):
```bash
# Create PR
gh pr create \
  --title "Ralph: <branch summary>" \
  --body "$(cat <<'EOF'
## Summary
<generated from progress.md>

## Stories Completed
<from PRD>

## Risk Assessment
- Risk Level: <level>
- All security checks passed
- All tests passing

## Evidence
- Progress log: ralph/progress.md
- Artifacts: ralph/artifacts/
EOF
)"
```

Output PR URL and summary.

### If NEEDS_REVIEW (WARN items present):
- Create draft PR
- List items needing human review
- Do not auto-merge

### If BLOCKED (any FAIL):
- Do not create PR
- Output blockers clearly
- Suggest remediation steps

## Step 9: Cleanup (on APPROVED only)

```bash
# Archive ralph directory
mv ralph ralph-archive-$(date +%Y%m%d-%H%M%S)
```

## Output Format

```
Merge Agent Complete
====================

Decision: <APPROVED/NEEDS_REVIEW/BLOCKED>
Risk Level: <level>

<If APPROVED>
PR Created: <URL>
Branch ready for merge after review.

<If NEEDS_REVIEW>
Draft PR Created: <URL>
Items needing review:
- <item 1>
- <item 2>

<If BLOCKED>
Merge blocked due to:
- <blocker 1>
- <blocker 2>

Remediation:
- <step 1>
- <step 2>
```
