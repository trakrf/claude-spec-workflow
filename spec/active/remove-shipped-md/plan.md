# Implementation Plan: Remove SHIPPED.md from Workflow
Generated: 2025-10-23
Specification: spec.md

## Understanding

We're removing SHIPPED.md from the claude-spec-workflow system because:
1. It stores commit SHAs that become invalid after squash/rebase merges
2. The cleanup script never reads its content - only checks if it exists
3. GitHub PRs already provide all the information SHIPPED.md tries to capture
4. `log.md` presence is the real proof that a spec is complete

This simplifies the workflow by removing a redundant tracking file and making GitHub the canonical source of truth for what shipped.

## Relevant Files

**Current Implementation to Remove From**:
- `commands/ship.md` (lines 226-260) - Step 9 creates SHIPPED.md entries
- `commands/cleanup.md` (multiple references) - Documents SHIPPED.md-based cleanup
- `commands/plan.md` (line 67) - Brief mention of SHIPPED.md
- `scripts/cleanup.sh` (lines 17-21, 52, 89-91) - SHIPPED.md existence checks
- `scripts/lib/cleanup.sh` (lines 72-81) - Unused `cleanup_shipped_feature` function
- `csw` (lines 256-259) - Initializes empty SHIPPED.md in new projects

**Documentation to Update**:
- `spec/README.md` - Multiple sections explain SHIPPED.md workflow
- `README.md` - References to SHIPPED.md and workflow
- `spec/template.md` - Success metrics mention SHIPPED.md
- `templates/spec-template.md` - Same as spec/template.md
- `templates/README.md` - References SHIPPED.md in workflow
- `templates/bootstrap-spec.md` - Validation criteria mentions SHIPPED.md

**What Stays Unchanged**:
- `scripts/cleanup.sh` (lines 62-85) - The log.md-based deletion logic is correct
- `scripts/lib/cleanup.sh` (lines 87-155) - Branch cleanup logic (remote tracking)

## Architecture Impact

- **Subsystems affected**: Workflow commands, cleanup scripts, initialization, documentation
- **New dependencies**: None
- **Breaking changes**:
  - `/ship` no longer creates/updates SHIPPED.md
  - `/cleanup` offers to delete existing SHIPPED.md files
  - New projects won't have SHIPPED.md
  - Existing SHIPPED.md files become historical artifacts (can be kept or deleted)

## Task Breakdown

### Task 1: Remove SHIPPED.md from /ship command
**File**: `commands/ship.md`
**Action**: MODIFY
**Lines**: Remove 226-260 (Step 9 "Update Shipped Log")

**Implementation**:
- Delete entire Step 9 section that creates SHIPPED.md entries
- Update step numbering if needed (Step 8 becomes the final step)
- The ship command will end after PR creation

**Validation**:
```bash
# Verify Step 9 is removed and PR creation is the final step
grep -n "Update Shipped Log" commands/ship.md  # Should return nothing
grep -n "SHIPPED.md" commands/ship.md  # Should return nothing
```

### Task 2: Update /cleanup command documentation
**File**: `commands/cleanup.md`
**Action**: MODIFY
**Lines**: Multiple sections throughout

**Implementation**:
Rewrite the command to explain the simpler log.md-based approach:
- Change persona description (line 5) - Remove "SHIPPED.md" from trust statement
- Update step 5 logic (lines 47-51) - Change from "matches entry in SHIPPED.md" to "has log.md file"
- Update philosophy section (line 66) - Remove SHIPPED.md from backup mention
- Update "What Gets Deleted" (lines 80-81) - Change from SHIPPED.md matching to log.md presence
- Update error handling (line 104) - Remove SHIPPED.md warning

**Key message**: Specs with log.md get deleted. GitHub PRs are the source of truth.

**Validation**:
```bash
# Verify SHIPPED.md references removed
grep "SHIPPED" commands/cleanup.md  # Should return nothing
# Verify log.md approach documented
grep "log.md" commands/cleanup.md  # Should find references
```

### Task 3: Remove SHIPPED.md reference from /plan command
**File**: `commands/plan.md`
**Action**: MODIFY
**Line**: 67

**Implementation**:
Replace the note about SHIPPED.md with simpler explanation:
```markdown
**Note**: Specs are NOT moved to `spec/archive/`. When deleted by /cleanup, they're preserved in git history. Use `gh pr list --state merged` to see shipped features.
```

**Validation**:
```bash
grep "SHIPPED" commands/plan.md  # Should return nothing
```

### Task 4: Add SHIPPED.md retirement offer to cleanup script
**File**: `scripts/cleanup.sh`
**Action**: MODIFY
**Lines**: Replace 17-21, 52, 89-91

**Implementation**:

Replace lines 17-21 (warning about missing SHIPPED.md):
```bash
# Check if retired SHIPPED.md exists and offer to delete
if [[ -f "spec/SHIPPED.md" ]]; then
    echo ""
    info "📋 SHIPPED.md Retirement Notice"
    echo "   SHIPPED.md has been retired from the workflow."
    echo "   Use GitHub PRs as the source of truth: gh pr list --state merged"
    echo ""
    read -p "   Delete spec/SHIPPED.md? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm spec/SHIPPED.md
        info "   ✓ Deleted spec/SHIPPED.md"
    else
        info "   ✓ Kept spec/SHIPPED.md (can delete manually anytime)"
    fi
    echo ""
fi
```

Remove lines 52 (SHIPPED.md check before spec cleanup)
Remove lines 89-91 (info message about no SHIPPED.md)

**Validation**:
```bash
# Verify no hard dependency on SHIPPED.md
grep "SHIPPED" scripts/cleanup.sh  # Should only find retirement offer
# Verify log.md logic untouched
grep "log.md" scripts/cleanup.sh  # Should still find the core logic
```

### Task 5: Remove unused function from cleanup library
**File**: `scripts/lib/cleanup.sh`
**Action**: MODIFY
**Lines**: Remove 62-85 (cleanup_shipped_feature function)

**Implementation**:
Delete the entire `cleanup_shipped_feature` function (lines 62-85):
- This function checks for SHIPPED.md and commits deletions
- It's not called anywhere in the current codebase
- Dead code from older version

Keep `cleanup_merged_branches` function (lines 87-155) - it's actively used.

**Validation**:
```bash
# Verify function removed
grep -n "cleanup_shipped_feature" scripts/lib/cleanup.sh  # Should return nothing
# Verify branch cleanup function intact
grep -n "cleanup_merged_branches" scripts/lib/cleanup.sh  # Should still exist
```

### Task 6: Remove SHIPPED.md initialization from csw init
**File**: `csw`
**Action**: MODIFY
**Lines**: Remove 256-259

**Implementation**:
Delete the SHIPPED.md initialization block:
```bash
# Initialize SHIPPED.md if it doesn't exist
if [ ! -f "$PROJECT_DIR/spec/SHIPPED.md" ]; then
    touch "$PROJECT_DIR/spec/SHIPPED.md"
fi
```

**Validation**:
```bash
# Verify SHIPPED.md not created in init
grep -A 3 "SHIPPED" csw  # Should return nothing in init section
```

### Task 7: Update spec/README.md
**File**: `spec/README.md`
**Action**: MODIFY
**Lines**: Multiple sections

**Implementation**:
Update the following sections to explain the simpler approach:

1. **Directory Structure** (line 60): Remove `└── SHIPPED.md` entry

2. **Feature Lifecycle & Cleanup Workflow** (lines 112-158):
   - Rewrite to explain: specs with log.md get deleted by /cleanup
   - Clarify: deleted from working tree, preserved in git history
   - Brief mention: GitHub PRs are source of truth

3. **Workflow Diagram** (lines 140-158):
   - Remove references to "Update SHIPPED.md"
   - Simplify to: /ship creates PR → merge → /cleanup deletes specs with log.md

**Key points to emphasize**:
- `log.md` presence = spec is complete = can be deleted
- Deleted specs preserved in git history
- GitHub PRs = canonical record

**Validation**:
```bash
# Verify SHIPPED.md removed
grep "SHIPPED" spec/README.md  # Should return nothing
# Verify log.md approach documented
grep "log.md" spec/README.md  # Should find references
```

### Task 8: Update project README.md
**File**: `README.md`
**Action**: MODIFY
**Lines**: Multiple references

**Implementation**:
Find and update references to SHIPPED.md:
- Line 283: Remove "logs to SHIPPED.md" from ship step
- Line 293: Remove "SHIPPED.md - Record of completed work"
- Line 296: Remove "Complete a feature? /ship logs it to SHIPPED.md"
- Line 302: Remove "features in SHIPPED.md" from backup list
- Line 501: Remove "└── SHIPPED.md" from directory structure
- Lines 643-648: Remove manual SHIPPED.md update instructions

Replace with brief mentions that GitHub PRs are the source of truth where appropriate.

**Validation**:
```bash
grep "SHIPPED" README.md  # Should return nothing
```

### Task 9: Update spec template
**File**: `spec/template.md`
**Action**: MODIFY
**Line**: Remove or rewrite line about SHIPPED.md in Success Metrics section

**Implementation**:
Find the line "Define measurable success criteria that will be tracked in SHIPPED.md" and change to:
```markdown
Define measurable success criteria:
```

**Validation**:
```bash
grep "SHIPPED" spec/template.md  # Should return nothing
```

### Task 10: Update templates/spec-template.md
**File**: `templates/spec-template.md`
**Action**: MODIFY
**Line**: 32

**Implementation**:
Same as Task 9 - change line 32 from:
```markdown
Define measurable success criteria that will be tracked in SHIPPED.md:
```
to:
```markdown
Define measurable success criteria:
```

**Validation**:
```bash
grep "SHIPPED" templates/spec-template.md  # Should return nothing
```

### Task 11: Update templates/README.md
**File**: `templates/README.md`
**Action**: MODIFY
**Lines**: 18, 64

**Implementation**:
- Line 18: Remove "and create your first SHIPPED.md entry"
- Line 64: Remove `└── SHIPPED.md` from directory structure

**Validation**:
```bash
grep "SHIPPED" templates/README.md  # Should return nothing
```

### Task 12: Update templates/bootstrap-spec.md
**File**: `templates/bootstrap-spec.md`
**Action**: MODIFY
**Line**: 36

**Implementation**:
Change validation criteria from:
```markdown
- [ ] This bootstrap spec itself gets shipped to SHIPPED.md
```
to:
```markdown
- [ ] This bootstrap spec creates a merged PR (visible in `gh pr list --state merged`)
```

**Validation**:
```bash
grep "SHIPPED" templates/bootstrap-spec.md  # Should return nothing
```

## Risk Assessment

**Risk**: Users with existing SHIPPED.md files may be confused
- **Mitigation**: Cleanup script offers to delete with clear explanation

**Risk**: Breaking existing workflows that depend on SHIPPED.md
- **Mitigation**: The workflow never actually read SHIPPED.md content, so this is safe

**Risk**: Loss of historical tracking
- **Mitigation**: GitHub PRs provide better tracking, and existing SHIPPED.md files can be kept as historical reference

## Integration Points

- **Cleanup workflow**: Now based purely on log.md presence
- **Ship workflow**: Ends at PR creation, no SHIPPED.md update
- **Init workflow**: No longer creates empty SHIPPED.md
- **Documentation**: Consistent message about GitHub as source of truth

## VALIDATION GATES (MANDATORY)

**CRITICAL**: These are not suggestions - they are GATES that block progress.

After EVERY code change, use commands from `spec/stack.md`:
- Gate 1: Syntax & Style (lint command)
- Gate 2: Type Safety (typecheck command - if applicable)
- Gate 3: Unit Tests (test command - if applicable)

For this project (shell scripts):
```bash
# After each file modification:
bash -n <file>  # Syntax check

# Final validation:
./test.sh  # If test suite exists
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
# Syntax check the modified file
bash -n <script-file>  # For .sh files
# Markdown files don't need syntax check

# Verify removal
grep "SHIPPED" <modified-file>  # Should return nothing (or only in retirement message)
```

Final validation:
```bash
# Check all files for lingering SHIPPED.md references (except deprecation message)
grep -r "SHIPPED" commands/ scripts/ templates/ spec/README.md README.md csw | grep -v "retirement\|retired"

# Verify core cleanup logic intact
grep -A 10 "log.md" scripts/cleanup.sh  # Should find deletion logic

# Test init doesn't create SHIPPED.md
cd /tmp && mkdir test-csw-init && cd test-csw-init
git init
/home/mike/claude-spec-workflow/csw init . shell-scripts
[ ! -f "spec/SHIPPED.md" ]  # Should succeed (file shouldn't exist)
cd - && rm -rf /tmp/test-csw-init
```

## Plan Quality Assessment

**Complexity Score**: 8/10 (MEDIUM-HIGH)
- 12 files to modify (more than initially estimated)
- Mostly mechanical deletions/rewrites
- Documentation updates are straightforward

**Confidence Score**: 9/10 (HIGH)

**Confidence Factors**:
✅ Clear requirements from spec
✅ All changes are deletions or simplifications (low risk)
✅ Core cleanup logic (log.md-based) already works correctly
✅ No new code patterns needed
✅ All clarifying questions answered
✅ User preference for retirement message approach confirmed
⚠️ Many files to update (risk of missing a reference)

**Assessment**: High confidence implementation. The changes are mechanical - removing redundant code and updating documentation. The core cleanup logic is already correct and requires no changes. Main risk is missing a SHIPPED.md reference somewhere.

**Estimated one-pass success probability**: 85%

**Reasoning**: Straightforward deletions and rewrites with clear validation criteria. The grep-based validation will catch any missed references. Complexity comes from the number of files, not from technical difficulty.
