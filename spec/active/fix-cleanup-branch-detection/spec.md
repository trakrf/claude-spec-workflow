# Feature: Fix Cleanup Script Branch Detection Exit Code Bug

## Origin
This specification emerged from testing the 0.3.1 cleanup fix (Issue #35). While validating the log.md-based spec deletion logic, we discovered a separate bug in the branch cleanup code that causes timeouts and prevents proper cleanup of squash/rebase merged branches.

## Outcome
The cleanup script's branch detection logic will correctly capture and handle git ls-remote exit codes, enabling proper cleanup of branches merged via squash or rebase strategies.

## User Story
As a developer using claude-spec-workflow
I want the cleanup script to successfully delete branches whose remotes were deleted (squash/rebase merges)
So that my local repository stays clean without manual intervention

## Context

**Discovery**: While running `/cleanup` after merging PR #36, the script timed out during branch cleanup. Investigation revealed a critical bug in exit code handling.

**Current Behavior** (`scripts/lib/cleanup.sh:129-144`):
```bash
if git ls-remote --exit-code --heads "$remote_name" "$remote_branch" &>/dev/null; then
    # Remote still exists, don't delete
    continue
else
    # Check ls-remote exit code for proper error handling
    local ls_exit=$?  # BUG: Captures exit code of 'if' check, not ls-remote!
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
```

**The Bug**:
- `local ls_exit=$?` is executed INSIDE the `else` block
- At that point, `$?` contains the exit code of the `if` statement evaluation (0), not the `git ls-remote` command
- The condition `[[ $ls_exit -eq 2 ]]` never triggers correctly
- Branches with deleted remotes are never cleaned up
- This can cause the script to hang or behave unexpectedly

**Why This Matters**:
- GitHub's squash and rebase merge strategies delete the remote branch after merge
- The cleanup script has dual detection: Method 1 (--merged flag) + Method 2 (remote deleted check)
- Method 2 is essential for squash/rebase workflows, which are common in modern GitHub workflows
- This bug completely breaks Method 2

**Desired Behavior**:
- Capture ls-remote exit code BEFORE any conditional logic
- Check exit code values correctly:
  - Exit 0 = remote exists → keep branch
  - Exit 2 = remote doesn't exist → delete branch (squash/rebase merged)
  - Other exit codes = network/auth error → skip with warning

## Problem Analysis

**Root Cause**: Bash variable scoping and exit code capture timing issue.

**Exit Code Behavior**:
```bash
# $? contains exit code of the LAST command executed
git ls-remote ...  # Returns exit code 2
if <condition>; then
    # $? is now 0 (the if condition evaluation succeeded)
```

**Current Code Path**:
1. `git ls-remote` exits with code 2 (remote doesn't exist)
2. `if` statement evaluates the non-zero exit code → false
3. Enters `else` block
4. `local ls_exit=$?` → captures 0 (the `if` evaluation), NOT 2 (ls-remote)
5. `[[ $ls_exit -eq 2 ]]` → false (0 ≠ 2)
6. Branch is NOT deleted (incorrect behavior)

**Impact**:
- **Functional**: Branches with deleted remotes accumulate in local repository
- **User Experience**: Manual `git branch -D` cleanup required after merges
- **Reliability**: Cleanup workflow doesn't complete as expected
- **Adoption**: Reduces trust in cleanup automation

## Technical Requirements

### 1. Fix Exit Code Capture Timing

**Current** (`scripts/lib/cleanup.sh:129-144`):
```bash
if git ls-remote --exit-code --heads "$remote_name" "$remote_branch" &>/dev/null; then
    continue
else
    local ls_exit=$?  # BUG HERE
    if [[ $ls_exit -eq 2 ]]; then
        # Delete logic
    fi
fi
```

**Solution**:
```bash
# Capture exit code BEFORE any conditional logic
git ls-remote --exit-code --heads "$remote_name" "$remote_branch" &>/dev/null
ls_exit=$?

# Now check the exit code
if [[ $ls_exit -eq 0 ]]; then
    # Remote exists, don't delete
    continue
elif [[ $ls_exit -eq 2 ]]; then
    # Remote doesn't exist (squash/rebase merged), delete branch
    echo "  Deleting: $branch (remote deleted)"
    git branch -D "$branch" 2>/dev/null || true
    deleted_count=$((deleted_count + 1))
else
    # Network error or other failure (exit code 1, 128, etc.)
    warning "  Skipping: $branch (could not verify remote status)"
fi
```

### 2. Maintain Existing Safety Features

Preserve all existing safety checks:
- ✅ Skip special branches (main, master, cleanup/merged)
- ✅ Skip branches without remote tracking
- ✅ Use -D flag only (force delete) since we've confirmed remote is gone
- ✅ Use `|| true` to prevent set -e from exiting on delete failure
- ✅ Warn on network/auth errors instead of failing

### 3. No Functional Changes to Method 1

Method 1 (traditional --merged detection) works correctly. Don't change it.

## Test Cases

### Should Delete (Remote Deleted - Squash/Rebase Merged)

**Setup**:
```bash
# Create and push a feature branch
git checkout -b feature/test-squash
echo "test" > test.txt
git add test.txt
git commit -m "test"
git push -u origin feature/test-squash

# Merge via GitHub squash merge (deletes remote branch)
# ... PR merged via squash ...

# Run cleanup
git checkout main
git pull
csw cleanup
```

**Expected**:
- `git ls-remote` returns exit code 2 (remote gone)
- Script detects exit code 2
- Deletes `feature/test-squash` locally
- Output: "Deleting: feature/test-squash (remote deleted)"

### Should Keep (Remote Still Exists)

**Setup**:
```bash
# Feature branch exists remotely
git branch feature/active-work
git push -u origin feature/active-work

# Run cleanup
csw cleanup
```

**Expected**:
- `git ls-remote` returns exit code 0 (remote exists)
- Script detects exit code 0
- Keeps `feature/active-work` locally
- No output for this branch

### Should Warn (Network Error)

**Setup**:
```bash
# Simulate network error by using invalid remote
git branch feature/test-error
git config branch.feature/test-error.remote "invalid-remote"
git config branch.feature/test-error.merge "refs/heads/feature/test-error"

# Run cleanup
csw cleanup
```

**Expected**:
- `git ls-remote` returns exit code 128 (invalid remote)
- Script detects exit code != 0 and != 2
- Skips branch with warning
- Output: "⚠️ Skipping: feature/test-error (could not verify remote status)"

## Validation Criteria

- [ ] Branches with deleted remotes (exit code 2) are deleted
- [ ] Branches with existing remotes (exit code 0) are preserved
- [ ] Network errors (exit code 1, 128, etc.) trigger warnings and skip deletion
- [ ] Method 1 (--merged) continues to work unchanged
- [ ] Cleanup script completes without hanging or timeout
- [ ] All shellcheck validations pass
- [ ] Manual testing confirms squash-merged branches are cleaned up

## Success Metrics

1. **Correctness**: 100% accurate branch deletion based on remote state
2. **Reliability**: Cleanup script completes successfully without timeouts
3. **Safety**: Network errors don't cause incorrect deletions (warning + skip)
4. **User Trust**: Developers can rely on automated cleanup after GitHub merges

## Implementation Notes

**Exit Code Reference** (from `git ls-remote --exit-code` docs):
- `0` = Remote ref exists
- `2` = Remote ref does not exist
- `1` = General error (network, auth, etc.)
- `128+` = Fatal errors (invalid remote, etc.)

**Testing Strategy**:
1. Unit test: Create test script that simulates different exit codes
2. Integration test: Actually merge a branch via squash and run cleanup
3. Regression test: Verify Method 1 (--merged) still works

## Version and Changelog

**Version**: 0.3.2 (patch release)

**Rationale**:
- 0.3.1 just shipped (10 minutes ago) with the spec deletion fix
- This is a separate bug in the same script
- Unlikely anyone pulled 0.3.1 and encountered this issue yet
- Safe to release as 0.3.2 immediately after 0.3.1

**CHANGELOG Entry**:
```markdown
## [0.3.2] - 2025-10-23

> **Bug Fix**: Cleanup script branch detection

### Fixed

- **`/cleanup` branch detection exit code handling**
  - Fixed critical bug where ls-remote exit codes were captured incorrectly
  - Root cause: `local ls_exit=$?` inside else block captured wrong exit code
  - Impact: Branches with deleted remotes (squash/rebase merges) weren't being cleaned up
  - Solution: Capture exit code before conditional logic, use elif chain for clarity
  - Now correctly deletes branches merged via GitHub squash/rebase strategies
  - Changed in: `scripts/lib/cleanup.sh:121-145`
```

## Conversation References

**Bug Discovery**: "FOUND THE BUG! Line 134: `local ls_exit=$?` - This is declaring a local variable inside the `else` block AFTER checking the exit code."

**Root Cause Analysis**: "The `$?` is being captured AFTER the `if` statement completes, so it's always capturing the wrong exit code!"

**Impact**: "Branches with deleted remotes are not being cleaned up properly"

**User Decision**: "we can play save and change log it as 0.3.2"

## Future Considerations

- Add automated tests for cleanup script behavior
- Consider caching ls-remote results to improve performance
- Add `--dry-run` flag to preview what would be deleted
- Add progress indicator for long branch cleanup operations
