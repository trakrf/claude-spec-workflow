# Implementation Plan: `/cleanup` Command
Generated: 2025-10-15T00:30:00Z
Specification: spec.md

## Understanding

The `/cleanup` command provides a one-shot workflow for solo developers to clean up after shipping and merging a feature:
1. Sync with latest main
2. Delete all merged feature branches
3. Create `cleanup/merged` staging branch
4. Delete shipped spec directories
5. Commit cleanup
6. Ready for `/plan` to rename branch and start next feature

**Key Design Decisions** (from clarifying questions):
1. Delete ALL merged branches (feature/*, fix/*, chore/*), not just feature/*
2. Warn gracefully on edge cases (missing SHIPPED.md, already on cleanup/merged)
3. Keep `/cleanup` command separate from `scripts/cleanup.sh` (different concerns)
4. Update `/plan` in this PR to honor `cleanup/merged` branch convention
5. Verbose output showing each action (match manual execution style)

## Relevant Files

**Reference Patterns** (existing code to follow):
- `commands/spec.md` (lines 1-167) - Command structure with persona, ultrathink, process steps
- `commands/ship.md` (lines 320-334) - csw execution pattern at end
- `scripts/cleanup.sh` (lines 1-72) - Pre-flight cleanup logic for /plan (different scope, but similar operations)
- `scripts/lib/cleanup.sh` - Library functions for spec deletion
- `bin/csw` (lines 34-38) - Command routing (already has "cleanup" registered)

**Files to Create**:
- `commands/cleanup.md` - Slash command definition (~150 lines)

**Files to Modify**:
- `commands/plan.md` (lines 46-71) - Add cleanup/merged branch detection (~15 lines added)
- `README.md` - Add `/cleanup` to commands table and lifecycle diagram (~5 lines modified)

## Architecture Impact
- **Subsystems affected**: Commands layer only
- **New dependencies**: None
- **Breaking changes**: None (opt-in command, doesn't modify existing workflows)

## Task Breakdown

### Task 1: Create `/cleanup` Command Definition
**File**: `commands/cleanup.md`
**Action**: CREATE
**Pattern**: Follow `commands/spec.md` structure - persona, process, execution

**Implementation**:
```markdown
# Clean Up Shipped Features

## Persona: Efficient Solo Developer

You are a solo developer who values speed and automation. Your strength is **aggressive cleanup** without asking permission. You trust that everything is backed up (git history + SHIPPED.md).

---

## Process

1. **Pre-flight Checks**
   - Warn if SHIPPED.md doesn't exist
   - Warn if already on cleanup/merged branch
   - Don't block - just inform user

2. **Sync with Main**
   ```bash
   git checkout main
   git pull
   ```

3. **Delete Merged Branches**
   ```bash
   # Find all merged branches (any prefix: feature/*, fix/*, chore/*, etc.)
   git branch --merged | grep -v -E '^\*|main|master' | while read branch; do
     echo "Deleting merged branch: $branch"
     git branch -d "$branch"
   done
   ```

   If no branches to delete: "✅ No merged branches to clean up"

4. **Create Cleanup Branch**
   ```bash
   git checkout -b cleanup/merged
   ```

5. **Delete Shipped Specs**
   ```bash
   find spec -name "spec.md" -type f | while read spec_file; do
     spec_dir=$(dirname "$spec_file")
     feature_name=$(basename "$spec_dir")

     if grep -q "$feature_name" spec/SHIPPED.md; then
       echo "Cleaning up: $spec_dir (found '$feature_name' in SHIPPED.md)"
       rm -rf "$spec_dir"
     else
       echo "Keeping: $spec_dir (not in SHIPPED.md)"
     fi
   done
   ```

6. **Commit Cleanup**
   ```bash
   git add spec/
   git commit -m "chore: cleanup shipped features"
   ```

7. **Success Message**
   ```
   ✅ Cleanup complete. On cleanup/merged branch.
   Run /plan when ready for next feature.
   ```

## Execution
{csw cleanup pattern}
```

**Validation**:
- shellcheck on embedded bash snippets
- Test with manual execution (already done!)

### Task 2: Update `/plan` to Honor `cleanup/merged` Branch
**File**: `commands/plan.md`
**Action**: MODIFY (lines ~429-430)
**Pattern**: Add branch detection before git checkout

**Implementation**:
Insert after "10. **Git Setup**" section (around line 429):

```markdown
10. **Git Setup**
   ```bash
   # Check current branch
   current=$(git branch --show-current)
   feature_name="{extracted-from-spec}"

   # Magic branch detection
   if [[ $current == "cleanup/merged" ]]; then
     # Solo dev fast path - specs already cleaned
     info "🔄 Renaming cleanup/merged → feature/$feature_name"
     git branch -m "feature/$feature_name"
   elif [[ $current == "main" ]] || [[ $current == "master" ]]; then
     # Standard path - create new branch
     git checkout -b "feature/$feature_name"
   else
     # Already on a feature branch
     warning "Already on branch: $current"
     error "Finish current feature or checkout main first"
     exit 1
   fi

   # Stage the planning artifacts
   git add spec/{feature}/spec.md spec/{feature}/plan.md
   git commit -m "plan: {feature-name} implementation"
   ```
```

**Rationale**: This enables the `/ship` → `<merge>` → `/cleanup` → `/plan` fast cycle.

**Validation**:
- Verify logic handles all three cases (cleanup/merged, main, feature/*)
- Test manual branch renaming works (already verified!)

### Task 3: Update README.md Documentation
**File**: `README.md`
**Action**: MODIFY (commands table + lifecycle diagram)

**Changes**:

**Commands table** (around line 244):
```markdown
| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/spec` | Convert conversation to specification | After exploring an idea interactively |
| `/plan` | Generate implementation plan | When you have a clear spec |
| `/build` | Execute the plan | After plan is approved |
| `/check` | Validate everything | Before creating PR |
| `/ship` | Complete and PR | When ready to merge |
| `/cleanup` | Clean up shipped features | After merging PR (optional solo dev tool) |
```

**Lifecycle section** (around line 253):
Update from:
```
([spec] | `<spec>`) → plan → build → [check] → ship → `<merge>` → repeat
```

To:
```
([spec] | `<spec>`) → plan → build → [check] → ship → `<merge>` → [cleanup] → repeat
```

Add explanation after diagram:
```markdown
**Optional `/cleanup` step**:
- Solo devs: Use `/cleanup` for zero-friction transition to next feature
- Team devs: Handle cleanup manually per team conventions
- Skippable: `/plan` still works without prior cleanup
```

**Validation**:
- Verify markdown renders correctly
- Check links and formatting

## Risk Assessment
- **Risk**: `/cleanup` is aggressive (deletes without confirmation)
  **Mitigation**: Clear warning in docs, opt-in only, everything backed up in git

- **Risk**: Spec matching by basename could have false positives
  **Mitigation**: Documented in spec as acceptable v1 tradeoff, iterate on real issues

- **Risk**: `cleanup/merged` branch convention could clash with user's branch naming
  **Mitigation**: Convention is opt-in, if you don't use `/cleanup` you never see it

## Integration Points
- **bin/csw**: Already routes "cleanup" to scripts/cleanup.sh (line 35)
- **scripts/cleanup.sh**: Currently used by /plan; will be REPLACED for /cleanup command
- **commands/plan.md**: Will detect and honor cleanup/merged branch
- **Manual execution**: Already proven the workflow works (we just did it!)

## VALIDATION GATES (MANDATORY)

This is a shell-scripts project. Use validation commands from `spec/stack.md`:

```bash
# Gate 1: Shellcheck (syntax & best practices)
shellcheck commands/*.md -f gcc || true  # Embedded bash
shellcheck scripts/*.sh

# No typechecking (bash)
# No tests (command definitions, not testable code)

# Gate 2: Manual verification
# Run /cleanup in test environment
# Verify cleanup/merged branch created
# Verify /plan honors cleanup/merged
```

**Enforcement Rules**:
- Shellcheck must pass (SC1091 warnings acceptable)
- Manual test must verify full cycle works
- Documentation must render correctly

## Validation Sequence
After each task:
```bash
shellcheck commands/cleanup.md -f gcc || true
```

Final validation:
```bash
# Full shellcheck scan
shellcheck scripts/*.sh commands/*.md -f gcc || true

# Manual end-to-end test
# 1. Ship a feature (use fix-plan-autoarchive as example)
# 2. Merge PR
# 3. Run /cleanup
# 4. Verify cleanup/merged branch
# 5. Run /plan for new feature
# 6. Verify branch renamed to feature/new
```

## Plan Quality Assessment

**Complexity Score**: 2/10 (LOW)
- File Impact: 1 file created, 2 files modified
- Subsystems: Commands layer only
- Tasks: 3 subtasks
- Dependencies: 0
- Pattern Novelty: Following existing patterns

**Confidence Score**: 9/10 (HIGH)

**Confidence Factors**:
✅ Clear requirements from spec
✅ Similar patterns found in commands/spec.md, commands/ship.md
✅ All clarifying questions answered
✅ Existing cleanup.sh shows similar operations work
✅ Manual execution already proven (we just did it!)
✅ bin/csw already has routing ready
✅ No external dependencies
⚠️ Aggressive deletion (but documented, opt-in, backed up)

**Assessment**: This is a well-understood feature with proven manual execution. The patterns exist, the routing is ready, and we've already validated the workflow works. High confidence in one-pass success.

**Estimated one-pass success probability**: 95%

**Reasoning**: We literally just executed this workflow manually and it worked perfectly. We're just formalizing it into a command. The only risk is edge cases in bash scripting, but we have existing patterns to follow and shellcheck to catch issues. Very high confidence.
