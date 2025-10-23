# Implementation Plan: Fix Cleanup Script Branch Detection Exit Code Bug
Generated: 2025-10-23
Specification: spec.md

## Understanding

The cleanup script has a critical bug in `scripts/lib/cleanup.sh:134` where `local ls_exit=$?` is declared inside an `else` block, capturing the exit code of the `if` statement evaluation (0) instead of the `git ls-remote` command (2). This prevents proper cleanup of branches merged via GitHub's squash/rebase strategies.

The fix is straightforward: capture the exit code BEFORE any conditional logic, then use an explicit `if/elif/else` chain to handle the three cases:
- Exit 0: Remote exists → keep branch
- Exit 2: Remote deleted → delete branch (squash/rebase merged)
- Other: Network/auth error → warn and skip

**User Decisions**:
- Manual testing only (test cases in spec)
- Add inline comments explaining exit code handling
- Use non-local variable for exit code (simpler, no scoping issues)

## Relevant Files

**Files to Modify**:
- `scripts/lib/cleanup.sh` (lines 127-145) - Fix exit code capture timing and logic
- `VERSION` - Update from 0.3.1 to 0.3.2
- `CHANGELOG.md` - Add 0.3.2 release notes

**Reference Pattern**:
- `scripts/lib/cleanup.sh:87-107` - Method 1 branch cleanup (works correctly, keep unchanged)
- Exit code pattern already exists in codebase but was incorrectly implemented in Method 2

## Architecture Impact

- **Subsystems affected**: Cleanup script only (scripts/lib/cleanup.sh)
- **New dependencies**: None
- **Breaking changes**: None (bug fix only, maintains all existing behavior)
- **Behavior change**: Branches with deleted remotes will now be cleaned up correctly

## Task Breakdown

### Task 1: Fix exit code capture in cleanup.sh
**File**: scripts/lib/cleanup.sh
**Action**: MODIFY
**Lines**: 127-145

**Current Code** (lines 127-145):
```bash
if [[ -n "$remote_name" && -n "$remote_branch" ]]; then
    # Check if remote branch still exists
    if git ls-remote --exit-code --heads "$remote_name" "$remote_branch" &>/dev/null; then
        # Remote still exists, don't delete
        continue
    else
        # Check ls-remote exit code for proper error handling
        local ls_exit=$?  # BUG: Captures 0 (if eval), not 2 (ls-remote)
        if [[ $ls_exit -eq 2 ]]; then
            # Exit code 2 means remote doesn't exist (what we want)
            echo "  Deleting: $branch (remote deleted)"
            git branch -D "$branch" 2>/dev/null || true
            deleted_count=$((deleted_count + 1))
        else
            # Network error or other failure
            warning "  Skipping: $branch (could not verify remote status)"
        fi
    fi
fi
```

**New Code**:
```bash
if [[ -n "$remote_name" && -n "$remote_branch" ]]; then
    # Check if remote branch still exists
    # Capture exit code BEFORE any conditional to avoid bash $? timing issue
    git ls-remote --exit-code --heads "$remote_name" "$remote_branch" &>/dev/null
    ls_exit=$?

    # Handle exit codes: 0 = exists, 2 = deleted, other = error
    if [[ $ls_exit -eq 0 ]]; then
        # Remote exists, keep branch
        continue
    elif [[ $ls_exit -eq 2 ]]; then
        # Remote doesn't exist (squash/rebase merged), delete branch
        echo "  Deleting: $branch (remote deleted)"
        git branch -D "$branch" 2>/dev/null || true
        deleted_count=$((deleted_count + 1))
    else
        # Network error or auth failure (exit code 1, 128, etc.)
        warning "  Skipping: $branch (could not verify remote status)"
    fi
fi
```

**Key Changes**:
1. Move `git ls-remote` call outside `if` statement
2. Capture `ls_exit=$?` immediately after (before any conditionals)
3. Use `if/elif/else` chain for clarity (three distinct cases)
4. Add inline comments explaining exit code values
5. Remove `local` keyword (simpler, no scoping confusion)

**Validation**:
- Run `bash -n scripts/lib/cleanup.sh` to check syntax
- Run `shellcheck scripts/lib/cleanup.sh` to verify no new warnings

### Task 2: Update VERSION file
**File**: VERSION
**Action**: MODIFY

**Current**:
```
0.3.1
```

**New**:
```
0.3.2
```

**Validation**:
- Verify file contains exactly "0.3.2" with newline

### Task 3: Update CHANGELOG.md
**File**: CHANGELOG.md
**Action**: MODIFY
**Lines**: 47-49 (Unreleased section)

**Current**:
```markdown
## [Unreleased]

_No unreleased changes._
```

**New**:
```markdown
## [Unreleased]

_No unreleased changes._

## [0.3.2] - 2025-10-23

> **Bug Fix**: Cleanup script branch detection

### Fixed

- **`/cleanup` branch detection exit code handling**
  - Fixed critical bug where ls-remote exit codes were captured incorrectly
  - Root cause: `local ls_exit=$?` inside else block captured exit code of if evaluation (0), not ls-remote command (2)
  - Impact: Branches with deleted remotes (squash/rebase merges) weren't being cleaned up
  - Solution: Capture exit code before conditional logic, use elif chain for clarity
  - Now correctly deletes branches merged via GitHub squash/rebase strategies
  - Changed in: `scripts/lib/cleanup.sh:127-145`
```

**Validation**:
- Verify CHANGELOG follows Keep a Changelog format
- Verify date is correct (2025-10-23)
- Verify line reference is accurate (127-145)

### Task 4: Manual testing (from spec test cases)
**Action**: MANUAL TEST

**Test Case 1: Verify fix with deleted remote**

Option A (if you have branches to test):
```bash
# Check if any local branches have deleted remotes
git branch -vv | grep "gone"

# If found, run cleanup and verify they're deleted
csw cleanup
```

Option B (create test scenario):
```bash
# Save current branch
current_branch=$(git branch --show-current)

# Create test branch
git checkout -b test/exit-code-fix
echo "test" > test-exit-code.txt
git add test-exit-code.txt
git commit -m "test: exit code fix"
git push -u origin test/exit-code-fix

# Delete remote via GitHub or command line
git push origin --delete test/exit-code-fix

# Switch back to main
git checkout "$current_branch"

# Run cleanup - should delete test/exit-code-fix
csw cleanup

# Verify branch was deleted
git branch | grep "test/exit-code-fix" && echo "❌ FAIL: Branch still exists" || echo "✅ PASS: Branch deleted"

# If test failed and branch still exists, clean it up manually
git branch -D test/exit-code-fix 2>/dev/null || true
```

**Test Case 2: Verify existing remotes are kept**
```bash
# Check that active branches with remotes are preserved
git branch -vv
# Look for branches with [origin/branch-name] tracking
# After cleanup, verify these still exist
```

**Expected Results**:
- ✅ Branches with deleted remotes (exit code 2) are deleted
- ✅ Branches with existing remotes (exit code 0) are preserved
- ✅ Cleanup completes without hanging or timeout
- ✅ Output shows "Deleting: branch-name (remote deleted)" for deleted branches

## Risk Assessment

**Risk**: Exit code capture might fail in edge cases
**Mitigation**: Use simple assignment `ls_exit=$?` immediately after command. This is the standard bash pattern and very reliable.

**Risk**: Breaking existing cleanup behavior
**Mitigation**: Only changing Method 2 (remote deleted check). Method 1 (--merged) unchanged. All safety checks preserved (skip special branches, use -D flag, || true pattern).

**Risk**: Manual testing might miss edge cases
**Mitigation**: Test cases cover the three main scenarios (exit 0, 2, and errors). The fix is simple enough that code review + basic testing is sufficient.

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
bash -n scripts/lib/cleanup.sh
```
If fails → Fix syntax errors immediately

**Gate 2: Shellcheck**
```bash
shellcheck scripts/lib/cleanup.sh
```
If fails → Fix shellcheck warnings/errors immediately (ignore SC1091 info warnings about sourced files)

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
1. Run syntax check: `bash -n scripts/lib/cleanup.sh`
2. Run shellcheck: `shellcheck scripts/lib/cleanup.sh`
3. Review changes for correctness

Final validation:
1. Run all syntax/shellcheck validation
2. Run manual test cases (Task 4)
3. Verify cleanup completes without timeout
4. Verify branch deletion works correctly

## Plan Quality Assessment

**Complexity Score**: 2/10 (LOW)
**Confidence Score**: 10/10 (HIGH)

**Confidence Factors**:
✅ Clear requirements from spec
✅ Root cause identified and understood
✅ Simple fix (move 2 lines, change if/else to if/elif/else)
✅ All clarifying questions answered
✅ Pattern is standard bash practice (capture exit code immediately)
✅ Existing Method 1 code shows working pattern
✅ No dependencies, no architectural changes
✅ Backward compatible (bug fix only)

**Assessment**: Very high confidence. This is a straightforward bug fix with a well-understood root cause and simple solution. The fix follows standard bash patterns for exit code handling.

**Estimated one-pass success probability**: 98%

**Reasoning**: The bug is clearly identified (wrong timing for $? capture), the fix is simple (move 2 lines, restructure conditional), and the validation is straightforward (shellcheck + manual test). The only risk is a typo or formatting error, which will be caught immediately by syntax validation. This is about as low-risk as an implementation gets.
