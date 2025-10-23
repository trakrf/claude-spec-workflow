# Implementation Plan: Auto-Delete Retired SHIPPED.md
Generated: 2025-10-23
Specification: spec.md

## Understanding

The spec requests removing the interactive confirmation prompt for SHIPPED.md deletion during cleanup. Currently, `scripts/cleanup.sh` asks the user "Delete spec/SHIPPED.md? (y/n)" when it detects the retired file. This should be replaced with automatic deletion and a simple info message.

**Key Requirements**:
1. Remove interactive `read -p` prompt from cleanup script
2. Auto-delete SHIPPED.md if it exists (no user interaction)
3. Show info message: "Removed retired SHIPPED.md (preserved in git history)"
4. Remove "Pre-flight Checks" section from commands/cleanup.md (one-off migration concern)
5. Add version 0.4.0 entry to CHANGELOG.md as a workflow improvement

**Rationale**: SHIPPED.md is retired. Anyone who cares will see the change documented in the changelog. No need to ask permission to delete a retired file every time cleanup runs.

## Relevant Files

**Files to Modify**:
- `scripts/cleanup.sh` (lines 18-33) - Replace interactive prompt with automatic deletion
- `commands/cleanup.md` (lines 26-29) - Remove "Pre-flight Checks" section and renumber steps
- `CHANGELOG.md` (after line 49) - Add version 0.4.0 entry under [Unreleased] section

**Reference Patterns**:
- `scripts/cleanup.sh:89` - Example of info message pattern: `echo "  ✓ Removing completed spec: $spec_dir (has log.md)"`
- `scripts/cleanup.sh:19-20` - Existing info helper usage pattern
- `CHANGELOG.md:51-64` - Version 0.3.2 entry format to mirror for consistency

## Architecture Impact
- **Subsystems affected**: Cleanup workflow, Documentation
- **New dependencies**: None
- **Breaking changes**: None (behavioral change only - removes interactive prompt)

## Task Breakdown

### Task 1: Update cleanup script to auto-delete SHIPPED.md
**File**: scripts/cleanup.sh
**Action**: MODIFY
**Lines**: 18-33

**Current behavior**:
- Interactive prompt asks user to delete SHIPPED.md
- User must type y/n
- Different messages based on response

**New behavior**:
- Check if spec/SHIPPED.md exists
- If yes: delete it silently and show info message
- If no: do nothing (no message needed)

**Implementation**:
```bash
# Before current_branch check, add simple auto-delete:
if [[ -f "spec/SHIPPED.md" ]]; then
    rm spec/SHIPPED.md
    info "Removed retired SHIPPED.md (preserved in git history)"
    echo ""
fi
```

**Validation**:
- Shellcheck must pass (no new warnings)
- Script should run without errors
- Test: Create dummy spec/SHIPPED.md, run cleanup, verify it's deleted with info message

### Task 2: Remove Pre-flight Checks section from documentation
**File**: commands/cleanup.md
**Action**: MODIFY
**Lines**: 26-29

**Current state**:
- Section "1. Pre-flight Checks" mentions SHIPPED.md prompt
- Subsequent sections numbered 2-7

**New state**:
- Remove lines 26-29 entirely (the Pre-flight Checks bullet points)
- Renumber: "2. Sync with Main" becomes "1. Sync with Main"
- Renumber all subsequent sections (3→2, 4→3, 5→4, 6→5, 7→6)

**Implementation**:
Delete the Pre-flight Checks section and renumber the process steps list.

**Validation**:
- Documentation should read clearly without the removed section
- Step numbering should be sequential (1-6 instead of 1-7)

### Task 3: Add CHANGELOG entry for version 0.4.0
**File**: CHANGELOG.md
**Action**: MODIFY
**Lines**: After line 49 (the [Unreleased] section)

**Pattern to follow**: Version 0.3.2 format (lines 51-64)

**Implementation**:
```markdown
## [0.4.0] - 2025-10-23

> **Workflow Improvement**: Streamlined cleanup automation

### Changed

- **`/cleanup` SHIPPED.md handling**
  - Removed interactive confirmation prompt for deleting retired SHIPPED.md file
  - SHIPPED.md is now deleted automatically if present during cleanup
  - Shows info message: "Removed retired SHIPPED.md (preserved in git history)"
  - Rationale: SHIPPED.md is retired; no need to ask permission each time
  - One-time migration concern removed from workflow context
  - Changed in: `scripts/cleanup.sh:18-23`
```

**Validation**:
- Entry follows Keep a Changelog format
- Date is accurate (2025-10-23)
- Positioned correctly after [Unreleased] section
- Line reference matches actual implementation

## Risk Assessment

**Risk**: Script syntax error breaks cleanup workflow
**Mitigation**:
- Keep changes minimal (replace 16 lines with 5 lines)
- Run shellcheck validation
- Test manually before committing

**Risk**: Documentation renumbering introduces inconsistencies
**Mitigation**:
- Carefully verify all step numbers are sequential
- Read through the entire Process section after editing

## Integration Points

- No store updates
- No route changes
- No config updates
- Pure workflow automation change

## VALIDATION GATES (MANDATORY)

**CRITICAL**: These are not suggestions - they are GATES that block progress.

After EVERY code change, use commands from `spec/stack.md`:
- Gate 1: Syntax (shellcheck scripts/cleanup.sh)
- Gate 2: Manual test (create dummy SHIPPED.md, run cleanup, verify deletion)
- Gate 3: Documentation review (read commands/cleanup.md for clarity)

**Enforcement Rules**:
- If ANY gate fails → Fix immediately
- Re-run validation after fix
- Loop until ALL gates pass

**Do not proceed to next task until current task passes all gates.**

## Validation Sequence

After Task 1: Run shellcheck on scripts/cleanup.sh
After Task 2: Read commands/cleanup.md to verify step numbering
After Task 3: Verify CHANGELOG.md follows Keep a Changelog format

Final validation:
- Run cleanup script with test SHIPPED.md file
- Verify info message appears
- Verify file is deleted

## Plan Quality Assessment

**Complexity Score**: 2/10 (LOW)
- File Impact: 3 files modified (1pt)
- Subsystems: 1 (cleanup workflow + docs) (0pts)
- Task Estimate: 3 subtasks (1pt)
- Dependencies: 0 new packages (0pts)
- Pattern Novelty: Existing patterns (0pts)

**Confidence Score**: 9/10 (HIGH)

**Confidence Factors**:
✅ Clear requirements from spec
✅ Simple code deletion and replacement
✅ Existing patterns found at scripts/cleanup.sh:89 (info message)
✅ All clarifying questions answered
✅ No external dependencies
✅ Straightforward documentation updates
✅ Well-defined CHANGELOG format to follow

**Assessment**: High confidence implementation. This is a straightforward refactoring task with clear requirements, no dependencies, and well-established patterns to follow.

**Estimated one-pass success probability**: 95%

**Reasoning**: The task involves minimal code changes (replacing 16 lines with 5 lines), simple documentation edits, and a standard CHANGELOG entry. The only minor risk is ensuring step renumbering is correct in the documentation, which is easily verifiable. The existing codebase provides clear patterns for the info message format.
