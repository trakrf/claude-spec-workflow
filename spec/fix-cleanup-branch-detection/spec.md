<!--
# spec.md - WHAT to Build

This file describes WHAT you want to achieve:
- User-facing goals and outcomes
- Business requirements and constraints
- Success criteria

Keep this concise and focused on outcomes, not implementation details.
The /plan command will generate plan.md with HOW to implement this spec.
-->

# Spec: Fix /cleanup Branch Detection

## Metadata
**Type**: bug fix
**Complexity**: medium
**Estimated Tasks**: 3-4
**Closes**:
- https://github.com/trakrf/claude-spec-workflow/issues/20
- https://github.com/trakrf/claude-spec-workflow/issues/30

## Origin
This specification emerged from dogfooding CSW on real projects and discovering that `/cleanup` fails to reliably detect merged branches. Two distinct but related problems were identified through production use.

## Outcome
The `/cleanup` command will reliably detect and delete all merged branches regardless of:
- GitHub's merge strategy (merge commit, squash, rebase)
- Timing (immediate vs delayed execution after merge)
- Remote branch state (deleted by GitHub or still exists)

## User Story
As a **solo developer using CSW**
I want `/cleanup` to automatically detect all merged branches
So that I don't have orphaned local branches cluttering my workspace after merging PRs

## Context

### Discovery: Two Related Problems

**Problem 1: Stale Git Refs (Issue #20)**
- **Timeline**: Merge PR on GitHub → Run `/cleanup` immediately → Branch not detected
- **Root Cause**: `git pull` only updates current branch (main), not knowledge about remote branches
- **Impact**: Timing-dependent failure - works if you wait, fails if run immediately

**Problem 2: Squash-Merge Detection (Issue #30)**
- **Real Evidence**: After merging PR #16 via squash, `git branch --merged main` didn't detect it
- **Root Cause**: Squash creates new commit, original commits don't exist in main's history
- **Impact**: Persistent failure - never works regardless of timing

### Current State
**File**: `scripts/cleanup.sh` (current broken logic)

```bash
1. Checkout main
2. git pull                     # Only updates main content
3. git branch --merged main     # Only detects merge commits
4. Delete detected branches
```

**Fails when**:
- Run immediately after GitHub merge (stale refs)
- GitHub uses "Squash and Merge" (most common default)
- GitHub uses "Rebase and Merge"

### Desired State
**File**: `scripts/cleanup.sh` (proposed comprehensive logic)

```bash
1. git fetch --prune origin     # ← NEW: Sync ALL remote state
2. Checkout main
3. git pull                     # Update main content
4. Delete via --merged          # Handles merge commits
5. Delete via remote tracking   # ← NEW: Handles squash/rebase
```

**Works when**:
- Any timing (fresh remote state via fetch --prune)
- Any GitHub merge strategy (two detection methods)
- Any remote state (prune handles deleted branches)

## Technical Requirements

### Requirement 0: Follow CSW Convention
**All bash logic belongs in `scripts/cleanup.sh`, NOT inline in command prompts**

This fix modifies existing script files following CSW's established pattern:
- Complex logic lives in `scripts/` directory
- Command prompts (`commands/cleanup.md`) stay clean and focused on workflow
- Scripts are testable, lintable, and reusable

### Requirement 1: Fix Stale Refs (Issue #20)
**Add `git fetch --prune origin` in `scripts/cleanup.sh` before branch detection**

```bash
# In scripts/cleanup.sh - before checking merged branches
git fetch --prune origin

# What this does:
# - Syncs ALL remote refs (not just current branch)
# - Updates knowledge of which remote branches exist
# - Removes local refs for deleted remote branches (--prune)
# - Ensures detection logic has fresh data
```

**Benefits**:
- Works immediately after GitHub merge
- Knows which remote branches GitHub deleted
- No race condition between merge and cleanup

### Requirement 2: Enhance Detection Algorithm (Issue #30)
**Use two complementary detection methods in `scripts/cleanup.sh`**

```bash
# Method 1: Traditional --merged (handles merge commits)
git branch --merged main | grep -v "^\*" | grep -v "main" | grep -v "master" | xargs -r git branch -d

# Method 2: Remote tracking check (handles squash/rebase)
for branch in $(git branch --format='%(refname:short)'); do
    # Skip special branches
    if [[ "$branch" == "main" || "$branch" == "master" || "$branch" == "cleanup/merged" ]]; then
        continue
    fi

    # Get remote tracking info
    remote_branch=$(git config --get branch.$branch.merge 2>/dev/null | sed 's|refs/heads/||')
    remote_name=$(git config --get branch.$branch.remote 2>/dev/null)

    # Check if remote branch exists
    if [[ -n "$remote_name" && -n "$remote_branch" ]]; then
        if ! git ls-remote --exit-code --heads $remote_name $remote_branch &>/dev/null; then
            echo "  Deleting: $branch (remote deleted)"
            git branch -D "$branch"  # Force delete since --merged won't detect it
        fi
    fi
done
```

**Why both methods**:

| Merge Strategy | `--merged` works? | Remote deleted works? | Need both? |
|----------------|-------------------|----------------------|------------|
| Merge commit   | ✅ Yes            | ✅ Yes               | Either     |
| Squash merge   | ❌ No             | ✅ Yes               | Yes        |
| Rebase merge   | ❌ No             | ✅ Yes               | Yes        |

### Requirement 3: Safe Deletion Logic
**Ensure no false positives**

- Skip current branch (`^\*`)
- Skip main/master branches
- Skip cleanup/merged branch (CSW workflow branch)
- Only delete if remote tracking branch is confirmed deleted
- Use `-d` for --merged (safe), `-D` for remote-deleted (forced but safe)

### Requirement 4: Clear User Feedback
**Report what was deleted and why**

```bash
# Example output
🧹 Cleaning up merged branches...
  Deleting: feature/auth (merged to main)
  Deleting: feature/ui-fix (remote deleted)
  Deleting: fix/typo (merged to main)
✅ Deleted 3 branches
```

## Code Examples

### Current Implementation (Broken)
**File**: `scripts/cleanup.sh` (lines ~45-50)

```bash
merged_branches=$(git branch --merged main | grep -v "^\*" | grep -v "main" | grep -v "master")
if [[ -z "$merged_branches" ]]; then
    log_success "✅ No merged branches to clean up"
else
    # ... delete logic
fi
```

### Proposed Implementation (scripts/cleanup.sh)
**File**: `scripts/cleanup.sh`
**Function**: `cleanup_merged_branches()` (refactor existing function)

```bash
cleanup_merged_branches() {
    log_info "🧹 Cleaning up merged branches..."

    local deleted_count=0

    # Method 1: Delete branches merged via traditional merge commit
    local merged_branches=$(git branch --merged main | grep -v "^\*" | grep -v "main" | grep -v "master")
    if [[ -n "$merged_branches" ]]; then
        while IFS= read -r branch; do
            branch=$(echo "$branch" | xargs)  # trim whitespace
            echo "  Deleting: $branch (merged to main)"
            git branch -d "$branch"
            deleted_count=$((deleted_count + 1))
        done <<< "$merged_branches"
    fi

    # Method 2: Delete branches whose remote was deleted (handles squash/rebase)
    for branch in $(git branch --format='%(refname:short)'); do
        # Skip special branches
        if [[ "$branch" == "main" || "$branch" == "master" || "$branch" == "cleanup/merged" ]]; then
            continue
        fi

        # Get remote tracking information
        local remote_branch=$(git config --get branch.$branch.merge 2>/dev/null | sed 's|refs/heads/||')
        local remote_name=$(git config --get branch.$branch.remote 2>/dev/null)

        if [[ -n "$remote_name" && -n "$remote_branch" ]]; then
            # Check if remote branch still exists
            if ! git ls-remote --exit-code --heads $remote_name $remote_branch &>/dev/null; then
                echo "  Deleting: $branch (remote deleted)"
                git branch -D "$branch"  # Force delete since --merged won't detect squash/rebase
                deleted_count=$((deleted_count + 1))
            fi
        fi
    done

    if [[ $deleted_count -eq 0 ]]; then
        log_success "✅ No merged branches to clean up"
    else
        log_success "✅ Deleted $deleted_count branch(es)"
    fi
}
```

## Validation Criteria

### Functional Tests
- [ ] **Merge commit**: Detects branch merged via traditional merge commit
- [ ] **Squash merge**: Detects branch merged via "Squash and Merge" (most important!)
- [ ] **Rebase merge**: Detects branch merged via "Rebase and Merge"
- [ ] **Immediate execution**: Works when run immediately after GitHub merge
- [ ] **Delayed execution**: Still works when run hours/days later
- [ ] **No false positives**: Doesn't delete unmerged branches
- [ ] **Safe branches protected**: Never deletes main, master, or cleanup/merged

### Integration Tests
- [ ] **Real workflow**: Merge PR #20 via squash → Run /cleanup → Verify branch deleted
- [ ] **Real workflow**: Merge PR #30 via squash → Run /cleanup → Verify branch deleted
- [ ] **Edge case**: Multiple merged branches with different strategies → All detected
- [ ] **Edge case**: Branch with no remote tracking → Not deleted (safe)
- [ ] **Edge case**: Unmerged branch → Not deleted (safe)

### Code Quality
- [ ] **Shellcheck passes**: No errors or warnings
- [ ] **Syntax valid**: All bash scripts pass `bash -n`
- [ ] **Idempotent**: Safe to run multiple times
- [ ] **Clear logging**: User understands what was deleted and why

## Success Metrics

### Before Fix (Current Broken State)
- ❌ Squash-merged branches: 0% detection rate
- ❌ Immediate execution: ~50% success rate (timing-dependent)
- ❌ User manual cleanup: Required for most PRs

### After Fix (Target State)
- ✅ Squash-merged branches: 100% detection rate
- ✅ Immediate execution: 100% success rate
- ✅ User manual cleanup: Never required
- ✅ All GitHub merge strategies: Fully supported

### Real-World Impact
**From Issue #30 evidence**: 5 orphaned branches after 5 merged PRs
- `feat/testable-startup-optional-db` (PR #16 merged, not detected)
- `feature/active-phase-5-authentication` (PR #15 merged, not detected)
- `feature/active-phase-5b-auth-endpoints` (PR #13 merged, not detected)
- `feature/active-phase-5c-auth-middleware` (PR #12 merged, not detected)
- `feature/phase-6a-justfile-monorepo` (PR #11 merged, not detected)

**After fix**: 0 orphaned branches, 100% automatic cleanup

## Constraints

### Technical Constraints
- Must work with GitHub's default "Squash and Merge" strategy
- Must not require GitHub API access (rely on git only)
- Must maintain backward compatibility with merge commit strategy
- Must be safe (no accidental deletion of unmerged work)
- **Must follow CSW convention**: All bash logic in `scripts/`, NOT inline in `commands/cleanup.md`

### Performance Constraints
- `git ls-remote` called per branch - acceptable for typical branch counts (<20)
- If performance becomes issue, could batch ls-remote calls

### User Experience Constraints
- No new user prompts (maintain aggressive cleanup philosophy)
- Clear logging so user understands what happened
- Idempotent (safe to run multiple times)

## Design Decisions

### Decision 1: Use Both Detection Methods
**Rationale**: No single method handles all GitHub merge strategies. Combination approach provides complete coverage.

### Decision 2: Force Delete for Remote-Deleted Branches
**Rationale**: `git branch -d` will fail for squash-merged branches (commits not in main history). Use `-D` but only after confirming remote is deleted (safe).

### Decision 3: Add `git fetch --prune` Before Detection
**Rationale**: Ensures detection logic always has fresh remote state. Minimal overhead, eliminates timing issues.

### Decision 4: Keep Aggressive No-Prompt Philosophy
**Rationale**: Everything is recoverable from git reflog. Speed over safety is CSW's design principle for cleanup.

## Related Work

### Complementary to Issue #20
Issue #20 fixes timing (stale refs). This spec includes that fix PLUS the algorithm enhancement for squash detection.

### Maintains CSW Philosophy
- Aggressive cleanup (no prompts)
- Trust git history as backup
- Opt-in only (never runs automatically)
- Idempotent and safe
- Local-only (never pushes)

## Risks & Mitigations

**Risk**: `git ls-remote` network call per branch could be slow
**Mitigation**: Only called for branches not detected by --merged. Typical case: 0-5 calls.

**Risk**: Force delete (-D) might delete unmerged work
**Mitigation**: Only force delete after confirming remote is deleted by GitHub (proof of merge).

**Risk**: Breaking existing cleanup behavior
**Mitigation**: Purely additive - existing --merged detection still works, just adds second method.

## References

### GitHub Issues
- Issue #20: /cleanup fails to detect merged branches due to stale git refs
- Issue #30: /cleanup fails to detect squash-merged branches

### Evidence
- PR #11, #12, #13, #15, #16: All squash-merged, all left orphaned branches
- Manual testing: Proposed implementation successfully deleted all 5 orphaned branches

### Git Documentation
- `git branch --merged`: https://git-scm.com/docs/git-branch#Documentation/git-branch.txt---merged
- `git ls-remote`: https://git-scm.com/docs/git-ls-remote
- `git fetch --prune`: https://git-scm.com/docs/git-fetch#Documentation/git-fetch.txt---prune
