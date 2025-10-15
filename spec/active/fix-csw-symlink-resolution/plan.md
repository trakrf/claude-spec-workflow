# Implementation Plan: Fix CSW Symlink Resolution
Generated: 2025-10-15
Specification: spec.md

## Understanding

The `csw` wrapper at `bin/csw` currently fails when invoked via the symlink at `~/.local/bin/csw` because it doesn't resolve symlinks before calculating `CSW_HOME`. The fix implements a standard symlink resolution loop (used by Node.js, Homebrew, etc.) to find the actual project directory.

**Current state**: The fix has been implemented in the working tree but not committed. The symlink resolution code (lines 7-15 of `bin/csw`) correctly handles:
- Single-level symlinks
- Multi-level symlink chains
- Relative symlink targets
- Absolute symlink targets

**Goal**: Commit the fix, validate it works correctly, and ensure it passes shellcheck.

## Relevant Files

**Reference Patterns** (existing code to follow):
- `scripts/spec.sh` (lines 1-5) - Standard bash script structure: shebang, set -e, source libs
- `scripts/cleanup.sh` (lines 1-7) - Similar pattern with error handling
- `spec/stack.md` (lines 10-13) - Shellcheck validation command

**Files to Modify**:
- `bin/csw` (lines 7-15) - Symlink resolution already implemented, needs validation
- No other files need changes

**Files Already Modified**:
- `bin/csw` - Contains the symlink resolution fix (uncommitted)

## Architecture Impact
- **Subsystems affected**: CLI wrapper only
- **New dependencies**: None
- **Breaking changes**: None (fixes broken behavior)

## Task Breakdown

### Task 1: Validate Symlink Resolution Logic
**File**: `bin/csw` (lines 7-15)
**Action**: VERIFY (already implemented)

**What to check**:
The existing implementation should match this pattern:
```bash
# Resolve symlinks to find the actual project directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
CSW_HOME="$(cd -P "$(dirname "$(dirname "$SOURCE")")" && pwd)"
SCRIPT_DIR="$CSW_HOME/scripts"
```

**Verification steps**:
1. Read `bin/csw` lines 7-15
2. Confirm the symlink resolution loop is present
3. Confirm `CSW_HOME` calculation uses the resolved `SOURCE`
4. Confirm `SCRIPT_DIR` is set to `$CSW_HOME/scripts`

**Validation**:
- Code review: Logic matches industry-standard pattern
- Next task will test functionality

### Task 2: Run Shellcheck Validation
**File**: `bin/csw`
**Action**: VALIDATE

**Implementation**:
Run the shellcheck command from `spec/stack.md`:
```bash
shellcheck bin/csw
```

**Expected result**: No errors or warnings

**If shellcheck reports issues**:
- Review each warning/error
- Fix legitimate issues
- Document any suppressions needed (with SC#### codes and comments)

**Validation**:
- Shellcheck exits with code 0
- No errors reported
- Any warnings are documented/justified

### Task 3: Test Symlink Resolution Manually
**File**: `bin/csw`
**Action**: TEST

**Test procedure**:
1. Verify the symlink exists: `ls -la ~/.local/bin/csw`
   - Should show: `~/.local/bin/csw -> /home/mike/claude-spec-workflow/bin/csw`

2. Test from different directories:
   ```bash
   cd /tmp
   csw --version    # Should show version, not error
   csw help         # Should show help, not "script not found"
   ```

3. Test a real command:
   ```bash
   cd ~/claude-spec-workflow
   csw cleanup      # Should run successfully (or warn about state)
   ```

**Expected behavior**:
- All commands work from any directory
- No "No such file or directory" errors
- Scripts are found in project directory

**Validation**:
- Manual test passes
- Commands execute successfully
- Error messages (if any) are about command logic, not missing files

### Task 4: Test Edge Cases
**File**: `bin/csw`
**Action**: TEST

**Edge cases to verify**:

1. **Direct execution** (not via symlink):
   ```bash
   cd ~/claude-spec-workflow
   ./bin/csw --version
   ```
   - Should work (loop exits immediately if not a symlink)

2. **Relative symlink** (if applicable):
   - Current setup uses absolute symlink
   - Logic handles relative with: `[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"`
   - No action needed unless symlink is relative

3. **Multi-level symlinks**:
   - Not present in current setup
   - Loop handles automatically
   - No action needed

**Validation**:
- Direct execution works
- Edge case handling is correct (even if not currently triggered)

### Task 5: Run Full Validation Suite
**File**: All shell scripts
**Action**: VALIDATE

**Implementation**:
Run all validation commands from `spec/stack.md`:

1. **Shellcheck** (all scripts):
   ```bash
   find . -name "*.sh" -not -path "*/\.*" -exec shellcheck {} +
   ```

2. **Syntax validation**:
   ```bash
   for script in $(find . -name "*.sh" -not -path "*/\.*"); do
     bash -n "$script" || exit 1
   done
   echo "✅ All bash scripts: syntax valid"
   ```

**Expected result**: All scripts pass validation

**Validation**:
- Shellcheck passes for all scripts
- Syntax validation passes
- No errors reported

### Task 6: Document the Fix
**File**: Update spec to reflect completed state
**Action**: UPDATE

**Implementation**:
Update `spec/active/fix-csw-symlink-resolution/spec.md`:

Change validation criteria:
```markdown
- [x] `csw cleanup` runs successfully from any directory
- [x] Wrapper resolves symlink correctly (tested)
- [x] Scripts are found in project directory, not `~/.local/scripts/`
- [x] Works on Linux (verified in testing)
- [ ] Works on macOS (deferred - will test when available)
- [ ] Works on WSL (deferred - will test when available)
- [ ] Works on Git Bash for Windows (deferred - will test when available)
```

Add implementation completion note:
```markdown
## Implementation Completed

**Date**: 2025-10-15
**Testing**: Verified on Linux (Ubuntu/GNU)
**Status**: Working as expected

**Deferred Testing**:
- macOS testing - requires access to macOS system
- WSL testing - requires Windows environment
- Git Bash testing - requires Windows environment

The implementation uses standard POSIX shell features (`readlink`, `-h` test, `cd -P`) that are available on all target platforms. Cross-platform compatibility is expected based on pattern usage in Node.js and Homebrew.
```

**Validation**:
- Spec reflects current state
- Deferred items are clearly marked
- Implementation notes are added

## Risk Assessment

**Risk**: Symlink resolution might behave differently on macOS (BSD `readlink`)
**Mitigation**:
- Pattern is proven across Node.js, Homebrew (both support macOS)
- BSD and GNU `readlink` both support reading symlink target
- Will test on macOS when available

**Risk**: Git Bash for Windows might not support `readlink`
**Mitigation**:
- MSYS2 (Git Bash's environment) provides `readlink` command
- `-h` test is POSIX standard
- Pattern is used by cross-platform tools

**Risk**: Relative symlinks might not resolve correctly
**Mitigation**:
- Code explicitly handles: `[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"`
- Converts relative to absolute by prepending directory
- Standard pattern from industry tools

## Integration Points

**No integration changes needed**:
- Fix is isolated to `bin/csw` entry point
- All downstream scripts receive absolute paths via `exec "$SCRIPT_DIR/$COMMAND.sh"`
- Library scripts continue using relative sourcing (already works)

## VALIDATION GATES (MANDATORY)

**CRITICAL**: These are not suggestions - they are GATES that block progress.

After EVERY code change, run these validation commands from `spec/stack.md`:

**Gate 1: Shellcheck** (lint)
```bash
shellcheck bin/csw
```
- Must exit with code 0
- No errors or warnings (or warnings are documented)

**Gate 2: Syntax Validation**
```bash
bash -n bin/csw
```
- Must exit with code 0
- No syntax errors

**Gate 3: Functional Test**
```bash
cd /tmp && csw --version && csw help
```
- Must show version and help output
- No "file not found" errors

**Enforcement Rules**:
- If ANY gate fails → Fix immediately
- Re-run validation after fix
- Loop until ALL gates pass
- After 3 failed attempts → Stop and ask for help

**Do not proceed to next task until current task passes all gates.**

## Validation Sequence

**After each task**:
1. Shellcheck validation (Gate 1)
2. Syntax validation (Gate 2)
3. Functional test (Gate 3)

**After all tasks complete**:
1. Full shellcheck on all scripts
2. Full syntax validation on all scripts
3. Manual testing from multiple directories

## Plan Quality Assessment

**Complexity Score**: 1/10 (LOW)
- Single file modification (0 points)
- 1 subsystem (0 points)
- 6 tasks (1 point)
- 0 new dependencies (0 points)
- Standard pattern (0 points)

**Confidence Score**: 9/10 (HIGH)

**Confidence Factors**:
✅ Fix already implemented and working
✅ Standard pattern used by Node.js, Homebrew, etc.
✅ Shellcheck available for validation
✅ Simple, focused change (single file)
✅ No dependencies, no breaking changes
✅ Manual testing is straightforward
⚠️ Cross-platform testing deferred (acceptable - pattern is proven)

**Assessment**: Extremely high confidence. The fix is already implemented and working. This plan focuses on validation and documentation rather than implementation. The symlink resolution pattern is industry-standard and proven across platforms.

**Estimated one-pass success probability**: 95%

**Reasoning**: The fix is already working (tested during `/cleanup` debugging). Tasks focus on validation, documentation, and edge case testing. Only risk is unexpected shellcheck warnings, which are easy to address. The pattern itself is proven and used by major cross-platform tools.
