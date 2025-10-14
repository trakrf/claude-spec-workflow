# Implementation Plan: Fix /plan Auto-Cleanup Workflow
Generated: 2025-10-14
Specification: spec.md

## Understanding

The `/plan` command currently has two critical issues:

1. **No pre-flight branch cleanup**: When on a merged/shipped branch, `/plan` doesn't detect this situation and clean up automatically
2. **Outdated path assumptions**: The workflow still references `spec/active/*` instead of `spec/*`
3. **Confusing terminology**: Uses "archive" terminology which implies spec/archive/ directory

This plan implements automatic workspace cleanup using linear history workflow (rebase, not merge commits) with proper "cleanup" terminology throughout.

## Relevant Files

**Reference Patterns** (existing code to follow):
- `scripts/lib/git.sh` (lines 44-52) - `delete_merged_branch()` function with merge check
- `scripts/lib/git.sh` (lines 23-29) - `is_branch_merged()` function
- `scripts/lib/git.sh` (lines 97-122) - `handle_branch_transition()` function (needs updating)
- `scripts/lib/archive.sh` (lines 76-88) - `delete_spec_directory()` function (works, just needs renaming)
- `scripts/lib/common.sh` - `info()`, `warning()`, `error()`, `success()` logging functions

**Files to Create**:
- `scripts/cleanup.sh` - Main cleanup script (replaces scripts/archive.sh functionality)
- `scripts/lib/cleanup.sh` - Cleanup library functions (renamed from archive.sh)

**Files to Modify**:
- `commands/plan.md` (lines 46-81) - Replace "Archive Shipped Features" section with cleanup workflow
- `scripts/lib/git.sh` (lines 97-122) - Update `handle_branch_transition()` to use cleanup terminology
- `scripts/archive.sh` - Rename to `scripts/cleanup.sh` (or delete if redundant)
- `bin/csw` - Update command routing if needed

**Files to Delete/Rename**:
- `scripts/archive.sh` → `scripts/cleanup.sh`
- `scripts/lib/archive.sh` → `scripts/lib/cleanup.sh`

## Architecture Impact
- **Subsystems affected**: Commands, Scripts Library, Git Workflow
- **New dependencies**: None
- **Breaking changes**:
  - Terminology shift from "archive" to "cleanup" (documentation/UX only)
  - No breadcrumb files (already not implemented, just removing from docs - done)
  - SHIPPED.md updated before merge (linear history workflow - documented)

## Task Breakdown

### Task 1: Rename archive → cleanup in scripts/lib/
**Files**:
- `scripts/lib/archive.sh` → `scripts/lib/cleanup.sh`
- All function names inside

**Action**: MODIFY + RENAME

**Pattern**: Simple find-replace with git mv

**Implementation**:
```bash
# Rename file
git mv scripts/lib/archive.sh scripts/lib/cleanup.sh

# Update function names and terminology
sed -i 's/archive_feature/cleanup_feature/g' scripts/lib/cleanup.sh
sed -i 's/Archiving/Cleaning up/g' scripts/lib/cleanup.sh
sed -i 's/Archived/Cleaned up/g' scripts/lib/cleanup.sh
sed -i 's/Archive operations/Cleanup operations/g' scripts/lib/cleanup.sh

# Remove breadcrumb functions (create_shipped_entry_template, update_shipped_md)
# Keep delete_spec_directory() but rename to cleanup_spec_directory()

# Update comments
sed -i 's/# Archive/# Cleanup/g' scripts/lib/cleanup.sh
```

**Validation**:
```bash
shellcheck scripts/lib/cleanup.sh
bash -n scripts/lib/cleanup.sh
```

### Task 2: Update scripts/lib/git.sh references
**File**: `scripts/lib/git.sh`

**Action**: MODIFY

**Pattern**: Update sourcing and function calls

**Implementation**:
```bash
# No changes needed - git.sh doesn't source archive.sh
# Just verify no references exist
grep -n "archive" scripts/lib/git.sh
```

**Validation**:
```bash
shellcheck scripts/lib/git.sh
```

### Task 3: Create new scripts/cleanup.sh main script
**File**: `scripts/cleanup.sh`

**Action**: CREATE (or rename from scripts/archive.sh)

**Pattern**: Reference `scripts/lib/cleanup.sh` functions

**Implementation**:
```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/git.sh"
source "$SCRIPT_DIR/lib/cleanup.sh"

# Main logic for cleanup
# Called by /plan command

# 1. Check if current branch is shipped
current_branch=$(get_current_branch)
main_branch=$(get_main_branch)

# Check SHIPPED.md for current branch
if [[ -f "spec/SHIPPED.md" ]] && grep -q "Branch: $current_branch" spec/SHIPPED.md; then
    info "🧹 Current branch $current_branch has been shipped"

    # Validate branch is merged
    if git branch --merged "$main_branch" | grep -q "$current_branch"; then
        info "📥 Pulling latest $main_branch..."
        git checkout "$main_branch"
        git pull origin "$main_branch"

        info "🗑️  Deleting merged branch..."
        git branch -d "$current_branch"

        # Delete spec directory
        feature=$(echo "$current_branch" | sed 's/feature\///')
        cleanup_spec_directory "$feature"
    else
        warning "Branch $current_branch not fully merged"
        error "Please ensure branch is merged before running /plan"
        exit 1
    fi
fi

# 2. Check for OTHER shipped features in spec/
for dir in spec/*/; do
    # Skip backlog
    [[ "$dir" =~ spec/backlog/ ]] && continue
    [[ ! -f "$dir/spec.md" ]] && continue

    feature=$(basename "$dir")

    # Check if in SHIPPED.md
    if [[ -f "spec/SHIPPED.md" ]] && grep -q "## .*$feature" spec/SHIPPED.md; then
        info "📦 Found shipped feature: $feature"
        read -p "Delete spec/$feature/? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cleanup_spec_directory "$feature"
        fi
    fi
done

success "✅ Workspace cleanup complete"
```

**Validation**:
```bash
shellcheck scripts/cleanup.sh
bash -n scripts/cleanup.sh
chmod +x scripts/cleanup.sh
```

### Task 4: Update commands/plan.md cleanup section
**File**: `commands/plan.md`

**Action**: MODIFY (lines 46-81)

**Pattern**: Replace manual instructions with script call

**Implementation**:
Replace entire "Archive Shipped Features" section with:

```markdown
2. **Cleanup Shipped Features** (Workspace Cleanup)

   **Pre-flight branch check and cleanup**:

   The planning workflow automatically cleans up shipped features:

   1. **Detects if current branch is shipped**: Checks spec/SHIPPED.md for current branch
   2. **Switches to main and pulls**: Ensures clean starting point
   3. **Deletes merged branch**: Safely removes shipped branch (validates merge first)
   4. **Deletes shipped spec**: Removes spec directory (preserved in git history)
   5. **Scans for other shipped features**: Prompts to delete any remaining shipped specs

   This happens automatically when you run `/plan`. The script ensures:
   - ✅ Branch is actually merged (safety check with `git branch --merged main`)
   - ✅ Spec directory exists before attempting deletion
   - ✅ Clean workspace for next feature

   **If no shipped features found**:
   ```
   ✅ Workspace clean - no shipped features to clean up

   Proceeding to planning...
   ```

   **Note**: Specs are NOT moved to spec/archive/. They are DELETED and preserved in git history. SHIPPED.md provides the reference to find them.
```

**Validation**:
Verify markdown syntax (no validation command for .md files)

### Task 5: Update bin/csw command routing
**File**: `bin/csw`

**Action**: MODIFY (if needed)

**Pattern**: Check if archive command exists, rename to cleanup

**Implementation**:
```bash
# Check if archive command is routed
grep -n "archive" bin/csw

# If found, update to:
# "cleanup") "$SCRIPT_DIR/../scripts/cleanup.sh" "$@" ;;
```

**Validation**:
```bash
shellcheck bin/csw
bash -n bin/csw
```

### Task 6: Update all script sourcing references
**Files**: All scripts that source `scripts/lib/archive.sh`

**Action**: MODIFY

**Pattern**: Update source statements

**Implementation**:
```bash
# Find all files sourcing archive.sh
grep -r "source.*archive.sh" scripts/

# Update each to source cleanup.sh instead
find scripts/ -type f -name "*.sh" -exec sed -i 's|lib/archive.sh|lib/cleanup.sh|g' {} \;
```

**Validation**:
```bash
# Verify no archive.sh references remain
grep -r "archive.sh" scripts/ bin/
```

### Task 7: Remove old scripts/archive.sh if redundant
**File**: `scripts/archive.sh`

**Action**: DELETE or UPDATE

**Pattern**: Check if still needed, otherwise delete

**Implementation**:
```bash
# Check if archive.sh is still used
grep -r "archive.sh" . --include="*.sh" --include="*.md"

# If only self-references, delete it
git rm scripts/archive.sh

# Otherwise rename it
git mv scripts/archive.sh scripts/cleanup.sh
```

**Validation**:
Manual verification that csw commands still work

### Task 8: Test the workflow end-to-end
**Action**: MANUAL TEST

**Pattern**: Follow spec test scenarios

**Test Scenarios**:
1. **Normal planning from main**:
   ```bash
   git checkout main
   # No cleanup should happen
   ```

2. **Shipped branch cleanup** (simulated):
   ```bash
   # Would need actual shipped branch to test
   # Verify pre-flight cleanup triggers
   ```

3. **Multiple shipped features**:
   ```bash
   # Create dummy shipped specs
   # Verify prompts appear
   ```

**Validation**:
All scenarios complete without errors

## Risk Assessment

- **Risk**: Breaking existing /plan workflow
  **Mitigation**: Keep changes minimal, test thoroughly, scripts are already modular

- **Risk**: Missing references to archive terminology
  **Mitigation**: Comprehensive grep for "archive" across all files after changes

- **Risk**: Git merge detection edge cases
  **Mitigation**: Use existing `is_branch_merged()` function, add `git branch --merged` safety check

- **Risk**: User on un-merged branch tries to /plan
  **Mitigation**: Pre-flight check validates merge status, prompts user to merge first

## Integration Points

- `/plan` command: Calls cleanup.sh before planning
- `spec/SHIPPED.md`: Read to determine what needs cleanup
- Git workflow: Branch detection and deletion
- Scripts library: Shared cleanup functions

## VALIDATION GATES (MANDATORY)

**CRITICAL**: These are not suggestions - they are GATES that block progress.

After EVERY code change:
```bash
# Gate 1: Shellcheck (syntax & style)
shellcheck scripts/*.sh scripts/lib/*.sh

# Gate 2: Bash syntax validation
for f in scripts/*.sh scripts/lib/*.sh; do bash -n "$f"; done

# Gate 3: Manual workflow test
# Run /plan on test branch to verify cleanup works
```

**Enforcement Rules**:
- If ANY gate fails → Fix immediately
- Re-run validation after fix
- Loop until ALL gates pass
- After 3 failed attempts → Stop and ask for help

**Do not proceed to next task until current task passes all gates.**

## Validation Sequence

After each task:
```bash
shellcheck <modified-file>
bash -n <modified-file>
```

Final validation:
```bash
# Full shellcheck
shellcheck scripts/*.sh scripts/lib/*.sh bin/csw

# Syntax check all bash files
find scripts/ bin/ -name "*.sh" -o -name "csw" | xargs -I {} bash -n {}

# Integration test
./scripts/cleanup.sh
```

## Plan Quality Assessment

**Complexity Score**: 3/10 (LOW)

**Confidence Score**: 8/10 (HIGH)

**Confidence Factors**:
✅ Clear requirements from spec
✅ Existing patterns found in scripts/lib/git.sh and scripts/lib/archive.sh
✅ All clarifying questions answered (linear history, cleanup terminology, safety checks)
✅ Modular script architecture makes changes isolated
✅ Shellcheck available for validation
⚠️ Manual testing required (no automated test suite for bash scripts)
⚠️ Workflow documentation conflicts resolved but need user validation

**Assessment**: High confidence implementation. Existing infrastructure supports the changes well, main risk is comprehensiveness of terminology replacement.

**Estimated one-pass success probability**: 85%

**Reasoning**:
- Low complexity (mostly renaming and minor logic updates)
- Existing functions handle most heavy lifting
- Clear patterns to follow
- Main uncertainty is catching all "archive" references
- Deduction for manual testing requirements
