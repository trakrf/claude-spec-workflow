# Implementation Plan: Fix /cleanup Branch Detection
Generated: 2025-10-19
Specification: spec.md

## Understanding

This is a bug fix addressing two related issues in the `/cleanup` command:

1. **Stale git refs (Issue #20)**: When running `/cleanup` immediately after merging a PR on GitHub, the local git refs are stale because `git pull` only updates the current branch (main), not knowledge about remote branches. This causes timing-dependent failures.

2. **Squash-merge detection (Issue #30)**: GitHub's "Squash and Merge" strategy (the most common default) creates a new commit, so the original branch commits don't exist in main's history. The traditional `git branch --merged main` command cannot detect these branches.

**Solution approach**:
- Add `git fetch --prune origin` to sync ALL remote refs (fixes timing issue)
- Implement dual detection: `--merged` for merge commits + remote tracking check for squash/rebase
- Extract logic to `cleanup_merged_branches()` function in `scripts/lib/cleanup.sh` (follows codebase pattern)

## Relevant Files

**Reference Patterns** (existing code to follow):
- `scripts/lib/cleanup.sh` (lines 7-19) - Function structure pattern: cleanup_spec_directory()
- `scripts/lib/common.sh` (lines 5-8) - Logging functions: info(), success(), warning(), error()
- `scripts/cleanup.sh` (lines 40-56) - Current branch deletion logic to be replaced
- `scripts/lib/git.sh` (lines 7-9) - Branch detection pattern: get_current_branch()

**Files to Modify**:
- `scripts/cleanup.sh` (lines 30-56) - Add fetch --prune, replace inline logic with function call
- `scripts/lib/cleanup.sh` (end of file) - Add new cleanup_merged_branches() function

## Architecture Impact
- **Subsystems affected**: Shell scripts (cleanup workflow)
- **New dependencies**: None (uses standard git commands)
- **Breaking changes**: None (purely additive, improves existing behavior)

## Task Breakdown

### Task 1: Add git fetch --prune before sync
**File**: `scripts/cleanup.sh`
**Action**: MODIFY
**Pattern**: Reference `scripts/lib/git.sh` lines 91-93 for git fetch pattern

**Implementation**:
```bash
# Around line 30, before "# 2. Sync with Main"
info "📡 Syncing remote refs..."
git fetch --prune origin
echo ""

# Then continue with existing sync logic
main_branch=$(get_main_branch)
info "📥 Syncing with $main_branch..."
```

**Validation**:
- Shellcheck: `find . -name "cleanup.sh" -path "*/scripts/*" -exec shellcheck {} +`
- Syntax: `bash -n scripts/cleanup.sh`

**Why**: Ensures fresh remote state before branch detection, eliminating timing issues.

---

### Task 2: Create cleanup_merged_branches() function skeleton
**File**: `scripts/lib/cleanup.sh`
**Action**: MODIFY
**Pattern**: Reference `scripts/lib/cleanup.sh` lines 7-19 for function structure

**Implementation**:
```bash
# Add at end of scripts/lib/cleanup.sh (after auto_tag_release function)

cleanup_merged_branches() {
    local main_branch="$1"
    local deleted_count=0

    info "🗑️  Deleting merged branches..."
    echo ""

    # Method 1 and Method 2 will be added in next tasks

    if [[ $deleted_count -eq 0 ]]; then
        success "✅ No merged branches to clean up"
    else
        success "✅ Deleted $deleted_count branch(es)"
    fi
    echo ""
}
```

**Validation**:
- Shellcheck: `shellcheck scripts/lib/cleanup.sh`
- Syntax: `bash -n scripts/lib/cleanup.sh`

**Why**: Establishes function structure following codebase pattern (lib functions, not inline).

---

### Task 3: Implement Method 1 - Traditional --merged detection
**File**: `scripts/lib/cleanup.sh`
**Action**: MODIFY
**Pattern**: Reference existing loop pattern from `scripts/cleanup.sh` lines 41-49

**Implementation**:
```bash
# Inside cleanup_merged_branches(), after "# Method 1 and Method 2" comment

# Method 1: Delete branches merged via traditional merge commit
local merged_branches
merged_branches=$(git branch --merged "$main_branch" | grep -v -E '^\*|main|master|cleanup/merged' || true)

if [[ -n "$merged_branches" ]]; then
    while IFS= read -r branch; do
        branch=$(echo "$branch" | xargs)  # trim whitespace
        if [[ -n "$branch" ]]; then
            echo "  Deleting: $branch (merged to $main_branch)"
            git branch -d "$branch" 2>/dev/null || true
            deleted_count=$((deleted_count + 1))
        fi
    done <<< "$merged_branches"
fi
```

**Validation**:
- Shellcheck: `shellcheck scripts/lib/cleanup.sh`
- Syntax: `bash -n scripts/lib/cleanup.sh`

**Why**: Handles traditional merge commits, maintains existing behavior while adding detailed logging.

---

### Task 4: Implement Method 2 - Remote tracking detection
**File**: `scripts/lib/cleanup.sh`
**Action**: MODIFY
**Pattern**: New logic based on spec requirements (lines 203-222)

**Implementation**:
```bash
# Inside cleanup_merged_branches(), after Method 1

# Method 2: Delete branches whose remote was deleted (handles squash/rebase)
for branch in $(git branch --format='%(refname:short)'); do
    # Skip special branches
    if [[ "$branch" == "main" || "$branch" == "master" || "$branch" == "cleanup/merged" ]]; then
        continue
    fi

    # Skip if already deleted by Method 1
    if ! git show-ref --verify --quiet "refs/heads/$branch"; then
        continue
    fi

    # Get remote tracking information
    local remote_branch
    local remote_name
    remote_branch=$(git config --get "branch.$branch.merge" 2>/dev/null | sed 's|refs/heads/||')
    remote_name=$(git config --get "branch.$branch.remote" 2>/dev/null)

    if [[ -n "$remote_name" && -n "$remote_branch" ]]; then
        # Check if remote branch still exists
        if git ls-remote --exit-code --heads "$remote_name" "$remote_branch" &>/dev/null; then
            # Remote still exists, don't delete
            continue
        else
            # Check if ls-remote command succeeded (exit code 0 or 2, not network error)
            local ls_exit=$?
            if [[ $ls_exit -eq 2 ]]; then
                # Exit code 2 means remote doesn't exist (what we want)
                echo "  Deleting: $branch (remote deleted)"
                git branch -D "$branch"  # Force delete since --merged won't detect squash/rebase
                deleted_count=$((deleted_count + 1))
            else
                # Network error or other failure
                warning "  Skipping: $branch (could not verify remote status)"
            fi
        fi
    fi
done
```

**Validation**:
- Shellcheck: `shellcheck scripts/lib/cleanup.sh`
- Syntax: `bash -n scripts/lib/cleanup.sh`

**Why**: Detects squash-merged and rebase-merged branches by checking if GitHub deleted the remote. Conservative error handling logs warnings instead of deleting on uncertainty.

---

### Task 5: Replace inline logic in cleanup.sh with function call
**File**: `scripts/cleanup.sh`
**Action**: MODIFY
**Pattern**: Reference function call pattern from line 69 (cleanup_spec_directory)

**Implementation**:
```bash
# Replace lines 36-56 with:

# 3. Delete Merged Branches
cleanup_merged_branches "$main_branch"
```

**Validation**:
- Shellcheck: `shellcheck scripts/cleanup.sh`
- Syntax: `bash -n scripts/cleanup.sh`

**Why**: Simplifies main script, moves complexity to library function following codebase pattern.

---

### Task 6: Update comments and section numbering
**File**: `scripts/cleanup.sh`
**Action**: MODIFY
**Pattern**: Maintain existing comment style

**Implementation**:
```bash
# After adding fetch --prune and function call, update section numbering:
# 1. Pre-flight Checks (unchanged)
# 2. Sync Remote State (new: fetch --prune + sync main)
# 3. Delete Merged Branches (now: function call)
# 4. Create Cleanup Staging Branch (renumber from 4)
# 5. Delete Shipped Spec Directories (renumber from 5)
# 6. Commit Cleanup (renumber from 6)
# 7. Success Message (renumber from 7)
```

**Validation**:
- Shellcheck: `shellcheck scripts/cleanup.sh`
- Visual review: Ensure comments match actual flow

**Why**: Maintains code documentation clarity after structural changes.

---

### Task 7: Final validation - Run full shellcheck
**File**: All modified scripts
**Action**: VALIDATE
**Pattern**: Use validation command from `spec/stack.md`

**Implementation**:
```bash
# Run shellcheck on all modified files
find . -name "*.sh" -not -path "*/\.*" -exec shellcheck {} +

# Verify syntax on modified files specifically
bash -n scripts/cleanup.sh
bash -n scripts/lib/cleanup.sh
```

**Validation**:
- All shellcheck warnings resolved
- No syntax errors
- Code follows existing patterns

**Why**: Ensures code quality and catches any issues before committing.

---

## Risk Assessment

**Risk**: `git ls-remote` network calls could slow down cleanup on many branches
**Mitigation**: Only called for branches not already deleted by Method 1. Typical case: 0-5 calls. If this becomes an issue in practice, can batch ls-remote calls in future iteration.

**Risk**: Force delete (-D) might delete unmerged work
**Mitigation**: Only force delete after confirming remote is deleted by GitHub (proof of merge). Conservative error handling skips deletion on uncertainty.

**Risk**: Breaking existing cleanup behavior
**Mitigation**: Purely additive - Method 1 preserves existing --merged detection, Method 2 adds squash/rebase coverage. Existing functionality unchanged.

**Risk**: Shellcheck warnings on new code
**Mitigation**: Run shellcheck after each task, fix issues immediately. Follow existing patterns from scripts/lib/*.sh.

## Integration Points

- **scripts/cleanup.sh**: Calls new cleanup_merged_branches() function
- **scripts/lib/cleanup.sh**: Exports new function for use by cleanup.sh
- **git commands**: Uses fetch --prune, ls-remote (standard git, no new dependencies)

## VALIDATION GATES (MANDATORY)

**CRITICAL**: These are not suggestions - they are GATES that block progress.

After EVERY code change, use commands from `spec/stack.md`:

**Gate 1: Shellcheck (Lint)**
```bash
find . -name "*.sh" -not -path "*/\.*" -exec shellcheck {} +
```

**Gate 2: Syntax Validation**
```bash
for script in $(find . -name "*.sh" -not -path "*/\.*"); do
  bash -n "$script" || exit 1
done
```

**Enforcement Rules**:
- If ANY gate fails → Fix immediately
- Re-run validation after fix
- Loop until ALL gates pass
- After 3 failed attempts → Stop and ask for help

**Do not proceed to next task until current task passes all gates.**

## Validation Sequence

**After each task**:
1. Run shellcheck on modified file
2. Run bash -n syntax check
3. Fix any issues
4. Re-run until clean

**Final validation** (after Task 7):
1. Run shellcheck on ALL .sh files
2. Run syntax validation on ALL .sh files
3. Manual smoke test (optional): Run `./scripts/cleanup.sh` in test environment

## Plan Quality Assessment

**Complexity Score**: 1/10 (LOW)
**Confidence Score**: 9/10 (HIGH)

**Confidence Factors**:
✅ Clear requirements from spec with real-world evidence (5 orphaned branches)
✅ Similar patterns found in codebase at scripts/lib/cleanup.sh, scripts/lib/git.sh
✅ All clarifying questions answered
✅ Standard git commands only (no new dependencies)
✅ Conservative approach (YAGNI, error handling)
⚠️ Cannot fully automate testing (would need real merged branches to test)

**Assessment**: High confidence in implementation success. The fix is well-scoped, follows existing patterns, and addresses a clearly defined problem with real evidence. The only uncertainty is manual testing, but the logic is straightforward and defensive.

**Estimated one-pass success probability**: 85%

**Reasoning**: Strong patterns to follow, clear requirements, and conservative implementation reduce risk. The 15% uncertainty is mainly from edge cases in git ls-remote error handling and ensuring both detection methods work together correctly. Shellcheck validation will catch syntax/logic errors early.
