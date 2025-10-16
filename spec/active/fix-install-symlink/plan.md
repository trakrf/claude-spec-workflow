# Implementation Plan: Fix csw install symlink creation
Generated: 2025-10-16
Specification: spec.md

## Understanding

The `csw install` command fails to create the CLI symlink in `~/.local/bin/csw` due to a bash arithmetic bug. The root cause is that scripts use `set -e` (exit on error), and post-increment operators `((var++))` return the old value before incrementing. When the counter is 0, the expression evaluates to 0, which bash treats as a failure, causing premature script exit.

**Audit Results**: Found 6 additional instances of the same pattern across the codebase:
- csw:405 (uninstall function)
- scripts/lib/validation.sh:93,98,103,108 (4 instances)
- scripts/cleanup.sh:47,86,89 (3 instances)

**User Decisions**:
- Fix already applied to csw:86,89 → Verify existing fix ✅
- Manual testing only (no automated test) ✅
- Audit all scripts for similar patterns ✅
- Add CHANGELOG entry ✅

## Relevant Files

**Files Already Fixed**:
- `csw` (lines 86,89) - ✅ Already corrected

**Files to Modify**:
- `csw` (line 405) - Fix uninstall function
- `scripts/lib/validation.sh` (lines 93,98,103,108) - Fix validation suite
- `scripts/cleanup.sh` (lines 47,86,89) - Fix cleanup counters
- `CHANGELOG.md` - Add bug fix entry (CREATE if doesn't exist)

## Architecture Impact
- **Subsystems affected**: Installation script, validation library, cleanup workflow
- **New dependencies**: None
- **Breaking changes**: None (bug fix only)

## Task Breakdown

### Task 1: Verify Existing Fix in csw install
**File**: `csw:86,89`
**Action**: VERIFY
**Pattern**: Already fixed

**Implementation**:
Confirm lines 86 and 89 use:
```bash
updated=$((updated + 1))
installed=$((installed + 1))
```

**Validation**:
```bash
grep -n "updated=\$((updated + 1))" csw
grep -n "installed=\$((installed + 1))" csw
```
Both should return matches.

---

### Task 2: Fix csw uninstall Counter
**File**: `csw:405`
**Action**: MODIFY
**Pattern**: Same fix as lines 86,89

**Implementation**:
Change line 405 from:
```bash
((removed++))
```
To:
```bash
removed=$((removed + 1))
```

**Validation**:
```bash
bash -n csw  # Syntax check
grep -n "removed=\$((removed + 1))" csw  # Verify fix
```

---

### Task 3: Fix validation.sh Counters
**File**: `scripts/lib/validation.sh:93,98,103,108`
**Action**: MODIFY (4 instances)
**Pattern**: Same fix pattern

**Implementation**:
Change all 4 instances of:
```bash
((failed++))
```
To:
```bash
failed=$((failed + 1))
```

**Locations**:
- Line 93: After test failure
- Line 98: After linter failure
- Line 103: After type checker failure
- Line 108: After build failure

**Validation**:
```bash
bash -n scripts/lib/validation.sh  # Syntax check
grep -n "failed=\$((failed + 1))" scripts/lib/validation.sh  # Verify all 4 fixed
```

---

### Task 4: Fix cleanup.sh Counters
**File**: `scripts/cleanup.sh:47,86,89`
**Action**: MODIFY (3 instances)
**Pattern**: Same fix pattern

**Implementation**:
Change line 47 from:
```bash
((merged_count++))
```
To:
```bash
merged_count=$((merged_count + 1))
```

Change line 86 from:
```bash
((cleaned_count++))
```
To:
```bash
cleaned_count=$((cleaned_count + 1))
```

Change line 89 from:
```bash
((kept_count++))
```
To:
```bash
kept_count=$((kept_count + 1))
```

**Validation**:
```bash
bash -n scripts/cleanup.sh  # Syntax check
grep -n "count=\$((.*count + 1))" scripts/cleanup.sh  # Verify all 3 fixed
```

---

### Task 5: Manual Integration Testing
**File**: N/A
**Action**: MANUAL TEST
**Pattern**: Validation criteria from spec

**Test Scenarios**:

**Scenario 1: Fresh Install**
```bash
# Setup
rm -f ~/.local/bin/csw

# Execute
./csw install

# Verify
ls -la ~/.local/bin/csw  # Should exist
readlink ~/.local/bin/csw  # Should point to ~/claude-spec-workflow/csw
```
Expected: Symlink created, all 6 commands processed

**Scenario 2: Reinstall**
```bash
# Execute (symlink already exists)
./csw install

# Verify
ls -la ~/.local/bin/csw  # Should still exist
```
Expected: No errors, reports "Already installed"

**Scenario 3: Uninstall**
```bash
# Execute
./csw uninstall

# Verify
ls -la ~/.local/bin/csw  # Should NOT exist
```
Expected: Symlink removed, commands cleaned up

**Validation**:
- [ ] Fresh install creates symlink
- [ ] All 6 command files processed and reported
- [ ] Reinstall doesn't fail
- [ ] Uninstall removes symlink
- [ ] No premature script exits
- [ ] Counter summaries show correct counts

---

### Task 6: Create/Update CHANGELOG
**File**: `CHANGELOG.md`
**Action**: CREATE (if missing) or MODIFY
**Pattern**: Keep-a-changelog format

**Implementation**:
If CHANGELOG.md doesn't exist, create it:
```markdown
# Changelog

All notable changes to Claude Spec Workflow will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Fix `csw install` failing to create CLI symlink due to arithmetic operator bug with `set -e`
- Fix similar counter increment bugs in `csw uninstall`, validation suite, and cleanup workflow
- All bash scripts now use `var=$((var + 1))` instead of `((var++))` for `set -e` compatibility

```

If CHANGELOG.md exists, add to `[Unreleased]` section:
```markdown
### Fixed
- Fix `csw install` failing to create CLI symlink due to arithmetic operator bug with `set -e`
- Fix similar counter increment bugs in `csw uninstall`, validation suite, and cleanup workflow
- All bash scripts now use `var=$((var + 1))` instead of `((var++))` for `set -e` compatibility
```

**Validation**:
```bash
cat CHANGELOG.md  # Review entry
```

---

## Risk Assessment

**Risk**: Breaking other scripts with similar patterns we missed
**Mitigation**: Comprehensive grep audit completed (found all instances)

**Risk**: Arithmetic syntax errors in fixes
**Mitigation**: `bash -n` syntax check after each change

**Risk**: Changed behavior in counters
**Mitigation**: Both syntaxes produce identical results, just different error handling

## Integration Points
- Installation workflow: csw install
- Uninstall workflow: csw uninstall
- Validation suite: scripts/lib/validation.sh
- Cleanup workflow: scripts/cleanup.sh

## VALIDATION GATES (MANDATORY)

**Use commands from `spec/stack.md`:**

After EVERY code change:
```bash
# Gate 1: Syntax Check
bash -n <modified-file.sh>

# Gate 2: Lint (shellcheck)
find . -name "*.sh" -not -path "*/\.*" -exec shellcheck {} +

# Gate 3: Validate (syntax check all scripts)
for script in $(find . -name "*.sh" -not -path "*/\.*"); do
  bash -n "$script" || exit 1
done
echo "✅ All bash scripts: syntax valid"
```

**Enforcement Rules**:
- If ANY gate fails → Fix immediately
- Re-run validation after fix
- Loop until ALL gates pass
- After 3 failed attempts → Stop and ask for help

**Do not proceed to next task until current task passes all gates.**

## Validation Sequence

After each task (Tasks 2-4): Run syntax check
```bash
bash -n <modified-file>
```

After Task 4 (all code changes complete): Run full lint
```bash
find . -name "*.sh" -not -path "*/\.*" -exec shellcheck {} +
```

After Task 5 (manual testing): Verify all validation criteria pass

Final validation: Full syntax check
```bash
for script in $(find . -name "*.sh" -not -path "*/\.*"); do
  bash -n "$script" || exit 1
done
```

## Plan Quality Assessment

**Complexity Score**: 1/10 (VERY LOW)
**Confidence Score**: 9/10 (HIGH)

**Confidence Factors**:
✅ Clear requirements from spec (root cause identified)
✅ Fix already applied and tested in csw:86,89
✅ Comprehensive audit completed (found all 6 instances)
✅ All clarifying questions answered by user
✅ Simple pattern fix (no logic changes)
✅ Validation commands available in spec/stack.md
✅ Manual test scenarios well-defined

**Assessment**: Straightforward bug fix with clear pattern. Existing fix already validated successfully. Extending same pattern to 6 additional locations.

**Estimated one-pass success probability**: 95%

**Reasoning**: The fix is proven (already works in csw:86,89), the pattern is simple and repetitive, and we've identified all instances through comprehensive audit. Only risk is typos during editing, mitigated by syntax validation gates.
