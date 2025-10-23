# Feature: Fix Cleanup Script Shipped Detection

## Origin
This specification emerged from [Issue #35](https://github.com/trakrf/claude-spec-workflow/issues/35), which identified a critical bug in the cleanup script that causes data loss by deleting unshipped specs.

## Outcome
The cleanup script will use filesystem evidence (`log.md` on main branch) as the definitive proof of completion, eliminating false positives from SHIPPED.md text matching.

## User Story
As a developer using claude-spec-workflow
I want the cleanup script to only delete specs that have actually been shipped
So that I don't lose work-in-progress specs that are referenced as future work

## Context

**Discovery**: While working on the `trakrf/action-spec` project, the cleanup script incorrectly deleted `spec/3.3.2/` even though it had never been shipped. The deletion occurred because Phase 3.3.1's SHIPPED.md entry mentioned "3.3.2" in its description: `**Foundation for**: Phase 3.3.2 (PR creation), Phase 3.4 (form pre-population)`.

**Current Behavior** (`scripts/cleanup.sh:70`):
```bash
if grep -q "$feature_name" spec/SHIPPED.md 2>/dev/null; then
```
- Uses simple string matching anywhere in SHIPPED.md
- Deletes any spec whose name appears anywhere in the file
- Cannot distinguish between shipped entries and inline mentions

**Desired Behavior**:
- Use `log.md` existence on main branch as proof of completion
- `log.md` can only exist on main if: /build ran → committed → PR merged
- Filesystem state is ground truth; SHIPPED.md is just documentation
- No false positives possible (log.md doesn't get created accidentally)

## Problem Analysis

**The Real Issue**: The cleanup script tries to parse human documentation (SHIPPED.md) instead of using filesystem evidence of completion.

**Root Cause**: The grep pattern doesn't anchor to section header syntax, so it matches any occurrence of the feature name in the document.

**The Breakthrough Insight**: A spec directory on main branch with `log.md` is **definitive proof** of completion:
- `/build` command creates `log.md`
- Developer commits it
- PR merges to main (where cleanup runs)
- **Merge to main is canonically the end of the cycle**
- Any further changes would create a new spec subdirectory

**Impact of Current Bug**:
- **Data Loss Risk**: Deletes unshipped specs that were created but not yet worked on
- **Workflow Disruption**: Forces manual verification of cleanup results
- **Trust Erosion**: Users cannot rely on cleanup to safely remove only shipped work
- **Recoverable**: Specs can be restored from git history (but this is manual work)

## Technical Requirements

### 1. Use Filesystem as Ground Truth

**Current** (`scripts/cleanup.sh:70`):
```bash
if grep -q "$feature_name" spec/SHIPPED.md 2>/dev/null; then
```

**Proposed Solution**:
```bash
# Check for log.md as proof of completion
if [ -f "spec/$feature_name/log.md" ]; then
    echo "  ✓ Removing completed spec: $feature_name (has log.md on main)"
    rm -rf "spec/$feature_name"
fi
```

### 2. Why log.md Is Definitive Proof

The existence of `log.md` on main branch proves:
1. ✅ `/build` command ran (log.md was created)
2. ✅ Work was committed (file is in git)
3. ✅ PR was merged (file exists on main branch)
4. ✅ Cycle is complete (merge to main = end of cycle)

**Cannot be false positive because**:
- log.md is only created by `/build` command
- Developer must intentionally commit it
- Must pass PR review/merge process
- Cleanup runs on main branch (not feature branches)

### 3. No Edge Cases

Unlike SHIPPED.md text parsing, filesystem checking has **zero edge cases**:
- ❌ No regex complexity
- ❌ No partial name matches (exact directory match)
- ❌ No inline mention confusion
- ❌ No format variations
- ❌ No typo vulnerability
- ✅ Simple file existence check
- ✅ Binary true/false (file exists or doesn't)

### 4. Backward Compatibility

**Perfect compatibility** with existing workflow:
- All shipped specs already have log.md on main
- Even legacy specs (pre-this-fix) have log.md if they were properly shipped
- Specs without log.md are unfinished (should be preserved)
- No migration needed

## Test Cases

### Should Delete (Has log.md)
Create test spec directories:
```
spec/3.3.1/
├── spec.md
├── plan.md
└── log.md     ← EXISTS on main

spec/3.3.2/
├── spec.md
├── plan.md
└── log.md     ← EXISTS on main
```

Expected: Both `spec/3.3.1/` and `spec/3.3.2/` deleted

### Should NOT Delete (No log.md - Work In Progress)
Create test spec directories:
```
spec/3.3.3/
├── spec.md
├── plan.md
└── (no log.md)  ← MISSING

spec/3.3.4/
└── spec.md      ← Only spec, not even planned
```

SHIPPED.md contains inline mentions:
```markdown
## Phase 3.3.1: GitHub Client Foundation
**Foundation for**: Phase 3.3.3 (future work), Phase 3.3.4 (planning)
```

Expected: Both `spec/3.3.3/` and `spec/3.3.4/` preserved (no log.md means not completed)

### The Original Bug Case
This is the exact scenario from Issue #35:
```
spec/3.3.2/
├── spec.md     ← Placeholder created
└── (no other files)

SHIPPED.md:
  ## Phase 3.3.1: GitHub Client Foundation
  **Foundation for**: Phase 3.3.2 (PR creation)
```

**Old behavior**: Deleted `spec/3.3.2/` (matched inline text)
**New behavior**: Preserves `spec/3.3.2/` (no log.md = not completed) ✓

## Implementation Plan

1. **Update cleanup script** (`scripts/cleanup.sh:70`)
   - Replace SHIPPED.md grep with log.md file check
   - Add clear comment explaining the proof chain
   - Simplify logic (no regex needed)

2. **Implementation code**
   ```bash
   # Check for log.md as definitive proof of completion
   # log.md on main proves: /build ran → committed → PR merged → complete
   if [ -f "spec/$feature_name/log.md" ]; then
       echo "  ✓ Removing completed spec: $feature_name"
       rm -rf "spec/$feature_name"
   else
       echo "  → Preserving: $feature_name (no log.md)"
   fi
   ```

3. **Test manually**
   - Create test spec with log.md → should be deleted
   - Create test spec without log.md → should be preserved
   - Verify against the original bug case (3.3.2 with inline mention)

4. **Document in SHIPPED.md**
   - Add entry explaining the fix
   - Reference issue #35
   - Note that cleanup now uses filesystem proof instead of text parsing

## Validation Criteria

- [ ] Specs with log.md on main are deleted
- [ ] Specs without log.md are preserved (regardless of SHIPPED.md content)
- [ ] Original bug case: spec/3.3.2/ with inline mention is preserved
- [ ] No false positives: only completed specs are removed
- [ ] No false negatives: all completed specs are removed
- [ ] Backward compatible: works with all existing shipped specs
- [ ] Simpler code: no regex, just file existence check

## Success Metrics

1. **Data Safety**: Zero unintended spec deletions after fix
2. **Simplicity**: Simpler code (file check vs regex parsing)
3. **Reliability**: Filesystem ground truth eliminates all text-matching edge cases
4. **Workflow Trust**: Users can confidently run cleanup without verification

## Conversation References

**Original Issue Insight**: "This uses a simple string search that matches **anywhere** in the file, not just in section headers." ([Issue #35](https://github.com/trakrf/claude-spec-workflow/issues/35))

**Real-World Impact**: "In `action-spec` project, the cleanup script deleted `spec/3.3.2/` because Line 31 of SHIPPED.md contains: `**Foundation for**: Phase 3.3.2 (PR creation)`"

**Initial Proposed Solution**: Use regex to match section headers only

**Breakthrough Insight**: "Having a committed log.md on main branch implies that we ran the build slash command and that we shipped and merged it. That definitely implies completion... even before this change a spec subdirectory on main with log.md implies completion. The merge to main is canonically the end of the cycle in this workflow."

**Final Solution**: Use log.md existence as ground truth instead of parsing SHIPPED.md text

**Severity Assessment**: Medium-High (data loss, though recoverable from git history)

## Future Considerations

- Could add automated tests for cleanup script behavior
- Could add `--dry-run` flag to preview what would be deleted
- Could add confirmation prompt before deleting multiple specs
- SHIPPED.md becomes purely documentation (not used for cleanup logic)
