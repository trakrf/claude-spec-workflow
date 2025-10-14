# Implementation Plan: Script Library Phase 3 - Wire It Up
Generated: 2025-10-14
Specification: spec.md

## Understanding

This is the final phase of a 3-phase refactoring to extract bash logic from command files into a reusable script library. Phase 1 built library functions, Phase 2 extracted commands to scripts. This phase wires everything together by:

1. Updating commands to call `csw` instead of embedded bash
2. Fixing bin/csw to use dynamic path detection (not hardcoded)
3. Updating installers to set up csw globally and project-locally
4. Testing all 3 access methods: `/command`, `csw command`, `./spec/csw command`

**Key design decisions** (from clarifying questions):
- All commands use `"$@"` for argument passing (POLS)
- install.sh overwrites existing symlink with `-f` (refresh)
- Commands fall back to `./spec/csw` if `csw` not in PATH (resilience)
- Full test coverage included (reasonable effort, high value)
- shellcheck validation on command bash blocks

## Relevant Files

**Files to Modify** (8 total):

**1. bin/csw** (lines 6-7):
- **Current**: Hardcoded `CSW_HOME="$HOME/.claude-spec-workflow"`
- **Change**: Dynamic detection using script's own location
- **Why**: Supports any checkout directory, not just `~/.claude-spec-workflow`

**2-7. commands/*.md** (6 files, ~1,700 lines total):
- **commands/spec.md** (~50 lines bash → 1 line)
- **commands/plan.md** (~120 lines bash → 1 line)
- **commands/build.md** (~60 lines bash → 1 line)
- **commands/check.md** (~80 lines bash → 1 line)
- **commands/ship.md** (~90 lines bash → 1 line)
- **commands/archive.md** (not in glob, may not exist yet - check)

**8. install.sh** (line ~60):
- **Add**: csw installation section (14 lines from spec)

**9. init-project.sh** (line ~115):
- **Add**: spec/csw symlink creation (20 lines from spec)

**Reference Patterns**:
- bin/csw (lines 1-58): CLI wrapper structure to preserve
- scripts/check.sh (lines 1-18): Example of script that sources libs
- install.sh (lines 28-41): Existing command installation pattern

## Architecture Impact

- **Subsystems affected**:
  1. Commands system (slash commands in Claude Code)
  2. Installation system (install.sh, init-project.sh)
  3. CLI system (bin/csw wrapper)

- **New dependencies**: None (all scripts exist from Phase 2)

- **Breaking changes**: None - maintains backward compatibility
  - Slash commands work identically
  - Output unchanged
  - Only internal implementation changes

## Task Breakdown

### Task 1: Fix bin/csw hardcoded path
**File**: `bin/csw`
**Action**: MODIFY
**Lines**: 6-7

**Current code**:
```bash
CSW_HOME="$HOME/.claude-spec-workflow"
SCRIPT_DIR="$CSW_HOME/scripts"
```

**New code**:
```bash
# Detect installation directory from this script's location
CSW_HOME="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)"
SCRIPT_DIR="$CSW_HOME/scripts"
```

**Rationale**: Allows csw to work from any checkout directory, not just `~/.claude-spec-workflow`.

**Validation**:
```bash
shellcheck bin/csw
./bin/csw --version  # Should still work
./bin/csw --help     # Should still work
```

---

### Task 2: Update commands/check.md
**File**: `commands/check.md`
**Action**: MODIFY
**Current**: ~400 lines including large bash block
**New**: ~20 lines with simple csw call

**Find the bash code block** (between triple backticks after the front matter).

**Replace entire bash block with**:
```bash
# Try csw in PATH first, fall back to project-local wrapper
if command -v csw &> /dev/null; then
    csw check "$@"
elif [ -f "./spec/csw" ]; then
    ./spec/csw check "$@"
else
    echo "❌ Error: csw not found"
    echo "   Run install.sh to set up csw globally"
    echo "   Or use: ./spec/csw check (if initialized)"
    exit 1
fi
```

**Validation**:
```bash
shellcheck commands/check.md  # Lint bash block
```

---

### Task 3: Update commands/spec.md
**File**: `commands/spec.md`
**Action**: MODIFY

**Replace bash block with**:
```bash
# Try csw in PATH first, fall back to project-local wrapper
if command -v csw &> /dev/null; then
    csw spec "$@"
elif [ -f "./spec/csw" ]; then
    ./spec/csw spec "$@"
else
    echo "❌ Error: csw not found"
    echo "   Run install.sh to set up csw globally"
    echo "   Or use: ./spec/csw spec (if initialized)"
    exit 1
fi
```

**Validation**:
```bash
shellcheck commands/spec.md
```

---

### Task 4: Update commands/plan.md
**File**: `commands/plan.md`
**Action**: MODIFY

**Replace bash block with**:
```bash
# Try csw in PATH first, fall back to project-local wrapper
if command -v csw &> /dev/null; then
    csw plan "$@"
elif [ -f "./spec/csw" ]; then
    ./spec/csw plan "$@"
else
    echo "❌ Error: csw not found"
    echo "   Run install.sh to set up csw globally"
    echo "   Or use: ./spec/csw plan (if initialized)"
    exit 1
fi
```

**Validation**:
```bash
shellcheck commands/plan.md
```

---

### Task 5: Update commands/build.md
**File**: `commands/build.md`
**Action**: MODIFY

**Replace bash block with**:
```bash
# Try csw in PATH first, fall back to project-local wrapper
if command -v csw &> /dev/null; then
    csw build "$@"
elif [ -f "./spec/csw" ]; then
    ./spec/csw build "$@"
else
    echo "❌ Error: csw not found"
    echo "   Run install.sh to set up csw globally"
    echo "   Or use: ./spec/csw build (if initialized)"
    exit 1
fi
```

**Validation**:
```bash
shellcheck commands/build.md
```

---

### Task 6: Update commands/ship.md
**File**: `commands/ship.md`
**Action**: MODIFY

**Replace bash block with**:
```bash
# Try csw in PATH first, fall back to project-local wrapper
if command -v csw &> /dev/null; then
    csw ship "$@"
elif [ -f "./spec/csw" ]; then
    ./spec/csw ship "$@"
else
    echo "❌ Error: csw not found"
    echo "   Run install.sh to set up csw globally"
    echo "   Or use: ./spec/csw ship (if initialized)"
    exit 1
fi
```

**Validation**:
```bash
shellcheck commands/ship.md
```

---

### Task 7: Check if commands/archive.md exists and update if present
**File**: `commands/archive.md` (may not exist)
**Action**: MODIFY (if exists) or SKIP (if doesn't exist)

**Check first**:
```bash
if [ -f "commands/archive.md" ]; then
    # Update it following same pattern as other commands
fi
```

**If exists, replace bash block with**:
```bash
# Try csw in PATH first, fall back to project-local wrapper
if command -v csw &> /dev/null; then
    csw archive "$@"
elif [ -f "./spec/csw" ]; then
    ./spec/csw archive "$@"
else
    echo "❌ Error: csw not found"
    echo "   Run install.sh to set up csw globally"
    echo "   Or use: ./spec/csw archive (if initialized)"
    exit 1
fi
```

**Validation**:
```bash
if [ -f "commands/archive.md" ]; then
    shellcheck commands/archive.md
fi
```

---

### Task 8: Update install.sh - Add csw installation
**File**: `install.sh`
**Action**: MODIFY
**Insert after**: Line ~60 (after command installation, before final messaging)

**Add this section**:
```bash
# Install csw to ~/.local/bin
echo ""
echo "🔧 Installing csw CLI..."

# Detect installation directory
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure ~/.local/bin exists
mkdir -p "$HOME/.local/bin"

# Create symlink (force refresh if exists)
ln -sf "$INSTALL_DIR/bin/csw" "$HOME/.local/bin/csw"
chmod +x "$HOME/.local/bin/csw"
chmod +x "$INSTALL_DIR/bin/csw"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo ""
    echo "ℹ️  For best results, add ~/.local/bin to your \$PATH"
    echo ""
    echo "Add this to your shell config (~/.bashrc, ~/.zshrc, etc):"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "Or use: ./spec/csw <command>"
    echo ""
else
    echo "✅ csw is ready to use: csw <command>"
fi
```

**Update final message** to include csw info:
```bash
echo "Available commands:"
echo "  /spec   - Convert conversation to specification"
echo "  /plan   - Generate implementation plan (interactive)"
echo "  /build  - Execute implementation with validation"
echo "  /check  - Pre-release validation check"
echo "  /ship   - Complete feature and prepare PR"
echo ""
echo "Also available as CLI:"
echo "  csw <command>           - Run from anywhere"
echo "  ./spec/csw <command>    - Project-local wrapper"
```

**Validation**:
```bash
shellcheck install.sh
```

---

### Task 9: Update init-project.sh - Add spec/csw symlink
**File**: `init-project.sh`
**Action**: MODIFY
**Insert after**: Line ~115 (after .gitignore update, before final success message)

**Add this section**:
```bash
# Create project-local csw symlink
echo "🔗 Setting up project-local csw wrapper..."

# Find csw installation via the symlink in PATH
CSW_PATH="$(command -v csw 2>/dev/null)" || true

if [ -n "$CSW_PATH" ]; then
    # Resolve symlink to find actual installation
    if command -v readlink &> /dev/null; then
        CSW_TARGET="$(readlink -f "$CSW_PATH" 2>/dev/null || realpath "$CSW_PATH" 2>/dev/null)" || CSW_TARGET="$CSW_PATH"
    else
        CSW_TARGET="$CSW_PATH"
    fi
    CSW_INSTALL_DIR="$(dirname "$(dirname "$CSW_TARGET")")"

    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        # Windows: Create wrapper script instead of symlink
        cat > "$PROJECT_DIR/spec/csw" << EOF
#!/bin/bash
exec "$CSW_INSTALL_DIR/bin/csw" "\$@"
EOF
        chmod +x "$PROJECT_DIR/spec/csw"
    else
        # Unix: Use symlink
        ln -sf "$CSW_INSTALL_DIR/bin/csw" "$PROJECT_DIR/spec/csw"
    fi

    echo "✅ Project-local wrapper created: ./spec/csw"
else
    echo "⚠️  csw not found in PATH - skipping project-local wrapper"
    echo "   Run install.sh first, then rerun init-project.sh to create wrapper"
fi
```

**Update final message** to mention spec/csw:
```bash
echo "Next steps:"
echo "1. Create your first spec:"
echo "   cd $PROJECT_DIR"
echo "   mkdir spec/my-feature"
echo "   cp spec/template.md spec/my-feature/spec.md"
echo ""
echo "2. Edit the spec with your requirements"
echo ""
echo "3. Generate implementation plan:"
echo "   /plan my-feature"
echo "   # Or: csw plan my-feature"
echo "   # Or: ./spec/csw plan my-feature"
```

**Validation**:
```bash
shellcheck init-project.sh
```

---

### Task 10: Test slash commands (via Claude Code)
**Action**: Manual testing
**Prerequisites**: Tasks 1-9 complete, commands reinstalled

**Test each command**:
```bash
# In Claude Code, run each:
/check
/spec test-feature  # Creates spec/test-feature/spec.md
/plan test-feature
# Edit spec to be trivial (just add a comment or echo)
/build
/check
/ship test-feature
```

**Expected**: All commands work identically to before refactor, just calling csw internally.

**Validation**:
- Commands execute without errors
- Output format unchanged
- Scripts are invoked correctly

---

### Task 11: Test direct csw CLI
**Action**: Manual testing
**Prerequisites**: Task 8 complete (install.sh updated and rerun)

**Test direct csw**:
```bash
# Verify installation
ls -la ~/.local/bin/csw
readlink -f ~/.local/bin/csw  # Should point to actual installation

# Test help/version
csw --help
csw --version

# Test commands
csw check
csw spec test-feature-2
csw plan test-feature-2
```

**Expected**:
- csw symlink exists in ~/.local/bin
- Points to actual installation (not hardcoded ~/.claude-spec-workflow)
- All commands work

**Validation**:
- Commands execute without errors
- Same output as slash commands

---

### Task 12: Test project-local ./spec/csw
**Action**: Manual testing
**Prerequisites**: Task 9 complete (init-project.sh updated)

**Test in a fresh project**:
```bash
cd /tmp
mkdir test-csw-project
cd test-csw-project
git init

# Run init-project
/path/to/claude-spec-workflow/init-project.sh .

# Verify spec/csw created
ls -la spec/csw
readlink -f spec/csw  # Should point to installation

# Test commands
./spec/csw --help
./spec/csw --version
./spec/csw check
```

**Expected**:
- spec/csw exists (symlink on Unix, wrapper on Windows)
- Points to installation
- Commands work without csw in PATH

**Validation**:
- All commands execute
- Works even if ~/.local/bin not in PATH

---

### Task 13: Test PATH fallback (resilience check)
**Action**: Manual testing
**Prerequisites**: Tasks 10-12 complete

**Temporarily remove csw from PATH**:
```bash
# Backup PATH
OLD_PATH="$PATH"

# Remove ~/.local/bin from PATH
export PATH=$(echo "$PATH" | sed -e 's|:$HOME/.local/bin||g' -e 's|$HOME/.local/bin:||g')

# Verify csw not in PATH
command -v csw  # Should fail

# Test that slash commands fall back to ./spec/csw
cd /path/to/project/with/spec/csw
/check  # Should work via ./spec/csw fallback

# Restore PATH
export PATH="$OLD_PATH"
```

**Expected**: Commands work via ./spec/csw fallback when csw not in PATH.

**Validation**: Fallback mechanism works as intended.

---

### Task 14: Full workflow integration test
**Action**: Complete feature lifecycle test
**Prerequisites**: All previous tasks complete

**Run complete cycle**:
```bash
cd /home/mike/claude-spec-workflow
git checkout main
git pull

# Use /spec to create a trivial test feature
/spec test-phase3-integration

# Add minimal spec content
cat > spec/test-phase3-integration/spec.md << 'EOF'
# Test Feature

## Outcome
Add a comment to README.md

## Validation
- [ ] Comment added to README
EOF

# Plan, build, check, ship
/plan test-phase3-integration
/build
/check
/ship test-phase3-integration

# Verify all steps completed successfully
```

**Expected**: Entire workflow works end-to-end with new csw integration.

**Validation**: Complete feature lifecycle with zero regressions.

---

### Task 15: Fresh installation test
**Action**: Test install.sh in clean environment
**Prerequisites**: Tasks 1-9 complete

**Simulate fresh install**:
```bash
cd /tmp
rm -rf test-csw-install
git clone https://github.com/trakrf/claude-spec-workflow test-csw-install
cd test-csw-install

# Run installation
./install.sh

# Verify csw installed
ls -la ~/.local/bin/csw
csw --version

# Test project initialization
cd /tmp
mkdir test-project
cd test-project
git init
csw init-project .  # Note: May need path to init-project.sh depending on implementation

# Verify spec/csw exists
ls -la spec/csw
./spec/csw --version
```

**Expected**: Clean installation works, csw available globally and project-locally.

**Validation**: Installation script sets up csw correctly from scratch.

---

### Task 16: Cross-platform compatibility check (if accessible)
**Action**: Test on Windows Git Bash (if available)
**Prerequisites**: Tasks 1-15 complete

**Windows-specific checks**:
```bash
# In Git Bash on Windows
./install.sh

# Verify wrapper script created (not symlink)
cat spec/csw  # Should be a bash script with 'exec' line

# Test wrapper works
./spec/csw --version
./spec/csw check
```

**Expected**: Windows wrapper script works identically to Unix symlink.

**Validation**: Cross-platform compatibility maintained.

---

## Risk Assessment

### Risk: Bash block extraction errors
**Impact**: Commands fail to execute
**Likelihood**: Low (simple replacement)
**Mitigation**:
- shellcheck validation after each command update
- Test each command immediately after modification
- Keep old bash blocks in git history for reference

### Risk: Path detection fails in edge cases
**Impact**: csw can't find scripts
**Likelihood**: Low (common bash idiom)
**Mitigation**:
- Test with symlinked installations
- Test with spaces in path
- Use robust `cd && pwd` pattern

### Risk: init-project.sh fails if csw not installed
**Impact**: No project-local wrapper created
**Likelihood**: Medium (user might init before install)
**Mitigation**:
- Make wrapper creation optional (warn but don't fail)
- Provide clear instructions to rerun after install
- Already implemented in task 9

### Risk: Fallback logic complexity
**Impact**: Commands harder to debug if issues arise
**Likelihood**: Low (simple if/elif/else)
**Mitigation**:
- Clear error messages for each failure mode
- Consistent fallback pattern across all commands
- Test PATH fallback explicitly (task 13)

## Integration Points

- **Command files → bin/csw**: Commands now delegate to csw CLI
- **install.sh → ~/.local/bin/csw**: Creates global symlink
- **init-project.sh → spec/csw**: Creates project-local symlink
- **bin/csw → scripts/**: CLI routes to script files
- **Slash commands → command files**: Unchanged (transparency)

## VALIDATION GATES (MANDATORY)

This is a bash/shell project. Validation uses shellcheck:

**After each command file modification (tasks 2-7)**:
```bash
shellcheck commands/*.md
```

**After installer modifications (tasks 8-9)**:
```bash
shellcheck install.sh
shellcheck init-project.sh
```

**After bin/csw modification (task 1)**:
```bash
shellcheck bin/csw
```

**Manual testing gates (tasks 10-16)**:
- Each access method must work: `/command`, `csw command`, `./spec/csw command`
- PATH fallback must work when csw not in PATH
- Fresh installation must set up csw correctly
- Full workflow must complete without errors

**Enforcement Rules**:
- If shellcheck fails → Fix syntax errors immediately
- If manual test fails → Debug and fix before proceeding
- All 3 access methods must work before considering complete
- Zero regression: output must match pre-refactor behavior

## Validation Sequence

**Per-file validation** (after tasks 1-9):
```bash
shellcheck <modified-file>
```

**Comprehensive validation** (after task 9, before testing):
```bash
shellcheck bin/csw
shellcheck install.sh
shellcheck init-project.sh
shellcheck commands/*.md
```

**Functional validation** (tasks 10-16):
- Test via Claude Code slash commands
- Test via direct csw CLI
- Test via project-local ./spec/csw
- Test PATH fallback mechanism
- Test full workflow integration
- Test fresh installation
- Test cross-platform (if accessible)

## Plan Quality Assessment

**Complexity Score**: 6/10 (MEDIUM-HIGH)
- 8 files to modify (2pts)
- 2 subsystems (1pt)
- ~13 subtasks (3pts)
- 0 new dependencies (0pts)
- Existing patterns (0pts)

**Confidence Score**: 9/10 (HIGH)

**Confidence Factors**:
✅ Clear requirements from spec - every change specified
✅ Existing scripts from Phase 2 - no new script logic needed
✅ Simple mechanical refactor - delete bash, add one line
✅ All clarifying questions answered
✅ Comprehensive test strategy in place
✅ bin/csw pattern already exists - just fixing hardcoded path
✅ install.sh pattern exists - just adding section
✅ Fallback pattern is simple and well-tested (command -v)

**Assessment**: High-confidence implementation. The changes are mechanical (copy-paste), well-specified, and incrementally testable. The only complexity is in the number of files, but each change is independent and validated separately.

**Estimated one-pass success probability**: 85%

**Reasoning**:
- All bash code is copy-paste from spec (eliminates syntax errors)
- Each file change is independent (one failure doesn't cascade)
- shellcheck catches any bash issues immediately
- Manual testing catches integration issues before full workflow test
- The 15% risk accounts for edge cases in path detection, cross-platform issues, or testing environment differences
- Phase 1 & 2 already validated the underlying scripts work correctly

**Mitigation for the 15%**:
- Task ordering ensures early detection (bin/csw first, commands second)
- Incremental testing catches issues before they compound
- Fallback mechanism provides resilience to PATH issues
- Clear error messages guide debugging if issues arise
