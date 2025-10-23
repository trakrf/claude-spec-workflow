# Implementation Plan: Fix Cleanup Script Shipped Detection
Generated: 2025-10-23
Specification: spec.md

## Understanding

The cleanup script currently has a critical bug at `scripts/cleanup.sh:70` where it uses simple string matching (`grep -q "$feature_name"`) to determine if a spec should be deleted. This causes false positives - it deletes specs that are merely **mentioned** in SHIPPED.md (e.g., "Foundation for: Phase 3.3.2") rather than only deleting specs that were actually **shipped**.

The fix leverages a key insight: **`log.md` on main branch is definitive proof of completion**. Since:
- `/build` command creates `log.md`
- Developer commits it
- PR merges to main (where cleanup runs)
- Merge to main is canonically the end of the cycle

We can simply check for `log.md` existence using `find ./spec -name log.md` and delete only those spec directories. This eliminates all text-matching edge cases and is simpler, more reliable, and impossible to falsely trigger.

**User decisions**:
- Pure log.md check (no SHIPPED.md fallback needed - log.md has existed since project start)
- Verbose output showing both deletions and preservations
- Use `find ./spec -name log.md` for simplicity

## Relevant Files

**Files to Modify**:
- `scripts/cleanup.sh` (lines 52-84) - Replace SHIPPED.md text matching with log.md filesystem check

**Reference Patterns**:
- `scripts/cleanup.sh:78` - Existing `find spec -name "spec.md"` pattern (we'll use similar for log.md)
- `scripts/cleanup.sh:70-76` - Current deletion logic (we'll replace the grep check)

## Architecture Impact

- **Subsystems affected**: Cleanup script only
- **New dependencies**: None
- **Breaking changes**: None (backward compatible - all shipped specs have log.md)
- **Behavior change**: More conservative (preserves specs mentioned inline in SHIPPED.md)

## Task Breakdown

### Task 1: Replace SHIPPED.md grep with log.md find
**File**: scripts/cleanup.sh
**Action**: MODIFY
**Lines**: 52-84

**Current logic** (lines 59-78):
```bash
# Find all spec.md files
while IFS= read -r spec_file; do
    spec_dir=$(dirname "$spec_file")
    feature_name=$(basename "$spec_dir")

    # Check if feature is in SHIPPED.md
    if grep -q "$feature_name" spec/SHIPPED.md 2>/dev/null; then
        echo "  Cleaning up: $spec_dir (found '$feature_name' in SHIPPED.md)"
        rm -rf "$spec_dir"
        cleaned_count=$((cleaned_count + 1))
    else
        echo "  Keeping: $spec_dir (not in SHIPPED.md)"
        kept_count=$((kept_count + 1))
    fi
done < <(find spec -name "spec.md" -type f 2>/dev/null || true)
```

**New logic**:
```bash
# Find all spec directories (both with and without log.md)
all_specs=$(find spec -name "spec.md" -type f 2>/dev/null || true)
# Find spec directories with log.md (definitive proof of completion)
completed_specs=$(find spec -name "log.md" -type f 2>/dev/null || true)

# Process all specs
while IFS= read -r spec_file; do
    spec_dir=$(dirname "$spec_file")

    # Skip backlog
    if [[ "$spec_dir" =~ spec/backlog/ ]]; then
        continue
    fi

    # Check if this spec has log.md (definitive proof of completion)
    if echo "$completed_specs" | grep -q "^${spec_dir}/log.md$"; then
        echo "  ✓ Removing completed spec: $spec_dir (has log.md)"
        rm -rf "$spec_dir"
        cleaned_count=$((cleaned_count + 1))
    else
        echo "  → Preserving: $spec_dir (no log.md)"
        kept_count=$((kept_count + 1))
    fi
done <<< "$all_specs"
```

**Validation**:
- Run `bash -n scripts/cleanup.sh` to check syntax
- Run `shellcheck scripts/cleanup.sh` to check for issues

### Task 2: Update comments to explain new logic
**File**: scripts/cleanup.sh
**Action**: MODIFY
**Lines**: 52-54

**Current**:
```bash
if [[ -f "spec/SHIPPED.md" ]]; then
    info "🧹 Cleaning up shipped specs..."
    echo ""
```

**New**:
```bash
if [[ -f "spec/SHIPPED.md" ]]; then
    info "🧹 Cleaning up shipped specs..."
    echo ""
    # Note: Uses log.md as proof of completion (not SHIPPED.md text matching)
    # log.md on main proves: /build ran → committed → PR merged → complete
```

**Validation**:
- Verify comment accurately describes the new approach

### Task 3: Remove SHIPPED.md dependency check (optional)
**File**: scripts/cleanup.sh
**Action**: MODIFY
**Lines**: 17-21, 52

**Current behavior**: Script warns if SHIPPED.md doesn't exist and skips cleanup.

**New behavior**: Since we're not using SHIPPED.md for detection, we can remove this check. However, keep the warning since SHIPPED.md is still documentation and its absence is suspicious.

**Decision**: Keep the SHIPPED.md existence check as-is (it's just a warning, doesn't affect cleanup logic).

**No changes needed for this task**.

### Task 4: Test the fix manually
**File**: N/A
**Action**: MANUAL TEST

**Test Case 1: Spec with log.md (should delete)**
```bash
# Create test spec with log.md
mkdir -p spec/test-completed
echo "# Test" > spec/test-completed/spec.md
echo "# Test Plan" > spec/test-completed/plan.md
echo "# Test Log" > spec/test-completed/log.md

# Run cleanup (dry-run by checking the logic)
# Expected: "✓ Removing completed spec: spec/test-completed (has log.md)"
```

**Test Case 2: Spec without log.md (should preserve)**
```bash
# Create test spec without log.md
mkdir -p spec/test-wip
echo "# Test WIP" > spec/test-wip/spec.md

# Run cleanup
# Expected: "→ Preserving: spec/test-wip (no log.md)"
```

**Test Case 3: Original bug case (should preserve)**
```bash
# Verify spec mentioned in SHIPPED.md but without log.md is preserved
# Add to SHIPPED.md: "**Foundation for**: Phase test-wip"
# Expected: "→ Preserving: spec/test-wip (no log.md)"
```

**Validation**:
- Manually run modified script
- Verify output matches expectations
- Clean up test specs after validation

## Risk Assessment

**Risk**: Breaking existing cleanup behavior
**Mitigation**: log.md has existed since project start; all shipped specs have it. Backward compatible.

**Risk**: find command edge cases (spaces in paths, special characters)
**Mitigation**: Using standard find with proper quoting; tested pattern already exists in codebase

**Risk**: Performance with large number of specs
**Mitigation**: find is fast; cleanup runs infrequently (only after merging PRs)

## Integration Points

- No store updates needed
- No route changes needed
- No config updates needed
- Cleanup script is standalone utility

## VALIDATION GATES (MANDATORY)

**CRITICAL**: These are not suggestions - they are GATES that block progress.

After EVERY code change:

**Gate 1: Syntax Check**
```bash
bash -n scripts/cleanup.sh
```
If fails → Fix syntax errors immediately

**Gate 2: Shellcheck**
```bash
shellcheck scripts/cleanup.sh
```
If fails → Fix shellcheck warnings/errors immediately

**Gate 3: Manual Test**
```bash
# Run the test cases from Task 4
# Verify expected output
```
If fails → Fix logic errors immediately

**Enforcement Rules**:
- If ANY gate fails → Fix immediately
- Re-run validation after fix
- Loop until ALL gates pass
- After 3 failed attempts → Stop and ask for help

**Do not proceed to next task until current task passes all gates.**

## Validation Sequence

After each task:
1. Run syntax check: `bash -n scripts/cleanup.sh`
2. Run shellcheck: `shellcheck scripts/cleanup.sh`
3. Review changes for correctness

Final validation:
1. Run all syntax/shellcheck validation
2. Run manual test cases (Task 4)
3. Verify output matches expected behavior
4. Clean up test specs

## Plan Quality Assessment

**Complexity Score**: 1/10 (LOW)
**Confidence Score**: 9/10 (HIGH)

**Confidence Factors**:
✅ Clear requirements from spec
✅ Existing find pattern in codebase at scripts/cleanup.sh:78
✅ All clarifying questions answered (pure log.md, verbose output, use find)
✅ Simple change (replace grep with find + grep for exact match)
✅ Backward compatible (log.md exists since project start)
✅ User confirmed no legacy edge cases
✅ Validation gates are straightforward (bash syntax + shellcheck)

**Assessment**: Very high confidence. This is a straightforward bugfix replacing complex text matching with simple filesystem check. The pattern already exists in the codebase, and we've confirmed log.md has existed since the beginning of the project.

**Estimated one-pass success probability**: 95%

**Reasoning**: The change is simple (replacing one check with another), uses existing patterns from the same file, and has been validated by user to have no legacy edge cases. The only risk is minor syntax errors which will be caught by validation gates. The logic is simpler than the current implementation, reducing complexity rather than adding it.
