# Implementation Plan: End-of-Life PowerShell Installation Scripts
Generated: 2025-10-12
Specification: spec.md

## Understanding

This feature removes PowerShell installation scripts (`.ps1` files) and standardizes on bash-only installation. The rationale is clear: the tool requires bash for operation (all validation commands in `spec/stack.md` are bash), so PowerShell installers solve the wrong problem. They let users install a tool they can't actually use.

**Key principle**: Bash is required from step 0. Windows users need bash to run `./install.sh`, so prerequisites must come BEFORE installation instructions.

**Communication tone**: Focus on benefits - "We built a better tool by reducing surface area and focusing on one shell."

## Relevant Files

**Reference Patterns**:
- Current README structure (lines 42-76) - Platform-specific installation sections that need consolidation
- Current TESTING.md structure (lines 8-55) - PowerShell tests that need removal

**Files to Delete**:
- `install.ps1` - PowerShell installation script
- `init-project.ps1` - PowerShell project initialization
- `uninstall.ps1` - PowerShell uninstallation script

**Files to Modify**:
- `README.md` - Add Prerequisites section, consolidate Installation to single bash path, update Uninstalling section
- `CONTRIBUTING.md` - Add bash requirement to Development Setup
- `TESTING.md` - Remove PowerShell tests (Tests 2, 28), update Windows tests to require Git Bash

## Architecture Impact

- **Subsystems affected**: Documentation, Installation scripts
- **New dependencies**: None
- **Breaking changes**: Yes - Windows users who previously used PowerShell installers will need Git Bash or WSL
  - Impact: Low (Windows userbase is hypothetical per spec)
  - Migration: Brief note in commit message

## Task Breakdown

### Task 1: Update README.md - Add Prerequisites Section
**File**: README.md
**Action**: MODIFY
**Pattern**: Add new section before "## Installation"

**Implementation**:
```markdown
## Prerequisites

**All Platforms:**
- Git installed
- Bash shell

**Platform-Specific Setup:**
- **macOS/Linux**: Native bash support ✓
- **Windows**: Requires Git Bash or WSL2
  - [Install Git for Windows](https://git-scm.com/download/win) (includes Git Bash)
  - [Install WSL2](https://docs.microsoft.com/en-us/windows/wsl/install)

**Why bash?** This tool executes validation commands through bash (as defined in `spec/stack.md`). Git Bash or WSL2 provides the bash environment needed for installation and operation.
```

**Location**: Insert after line 40 (after "## Features" section, before "## Installation")

**Validation**:
```bash
# Verify section added
grep -A 5 "## Prerequisites" README.md
```

### Task 2: Update README.md - Consolidate Installation Section
**File**: README.md
**Action**: MODIFY
**Pattern**: Replace lines 42-76 with single bash installation path

**Implementation**:
Replace the entire "## Installation" section (lines 42-76) with:

```markdown
## Installation

```bash
# Clone the repository
git clone https://github.com/trakrf/claude-spec-workflow
cd claude-spec-workflow

# Install commands globally
./install.sh

# Initialize a project with default preset (TypeScript + React + Vite)
./init-project.sh /path/to/your/project

# Or initialize with a specific preset
./init-project.sh /path/to/your/project python-fastapi
```

**Windows users**: Run these commands in Git Bash or WSL2 terminal.
```

**Notes**:
- Remove "### macOS / Linux" heading
- Remove entire "### Windows (PowerShell)" section (lines 60-75)
- Single unified bash installation path
- Brief Windows note at the end

**Validation**:
```bash
# Verify no PowerShell references in Installation section
sed -n '/## Installation/,/## Quick Start/p' README.md | grep -i powershell
# Should return nothing
```

### Task 3: Update README.md - Consolidate Preset Instructions
**File**: README.md
**Action**: MODIFY
**Pattern**: Remove duplicate Windows preset examples (lines 140-147)

**Implementation**:
In the "### Using a Preset" section (around lines 129-147):
- Remove the "**Windows (PowerShell):**" subsection entirely
- Keep only the bash examples under "**macOS / Linux:**" but remove that heading
- Result: Single unified bash example

**Validation**:
```bash
# Verify preset section has no platform-specific headings
sed -n '/### Using a Preset/,/### Changing Your Stack/p' README.md | grep -E "(macOS|Windows|PowerShell)"
# Should return only brief notes, not section headers
```

### Task 4: Update README.md - Consolidate Uninstalling Section
**File**: README.md
**Action**: MODIFY
**Pattern**: Replace lines 388-400 with single bash path

**Implementation**:
Replace the "## Uninstalling" section with:

```markdown
## Uninstalling

```bash
./uninstall.sh
```

This removes the Claude commands but leaves your project spec directories intact.
```

**Validation**:
```bash
# Verify Uninstalling section simplified
sed -n '/## Uninstalling/,/## Troubleshooting/p' README.md | grep -i powershell
# Should return nothing
```

### Task 5: Update README.md - Remove Windows Path Issue from Troubleshooting
**File**: README.md
**Action**: MODIFY
**Pattern**: Update "### Cross-Platform Issues" section (around lines 492-500)

**Implementation**:
Update the Windows troubleshooting entry:

```markdown
### Cross-Platform Issues

**Windows setup**
- Use Git Bash or WSL2 terminal for all commands
- Use forward slashes in paths: `/plan spec/active/feature/spec.md`
- If using Git Bash: Right-click in directory → "Git Bash Here"

**Symlink issues on Unix**
- Scripts now handle symlinks correctly (v1.0.0+)
- If issues persist, use absolute paths
```

**Notes**:
- Remove PowerShell execution policy mention
- Focus on Git Bash usage
- Keep symlink section as-is

**Validation**:
```bash
# Verify Cross-Platform section updated
sed -n '/### Cross-Platform Issues/,/### Getting Help/p' README.md | grep -i "execution policy"
# Should return nothing
```

### Task 6: Update CONTRIBUTING.md - Add Bash Requirement
**File**: CONTRIBUTING.md
**Action**: MODIFY
**Pattern**: Update "### Prerequisites" section (lines 25-28)

**Implementation**:
Replace lines 25-28 with:

```markdown
### Prerequisites
- Git
- Bash (Git Bash on Windows, native on macOS/Linux)
- Claude Code installed

**Windows developers**: Use Git Bash or WSL2 for development and testing.
```

**Validation**:
```bash
# Verify bash requirement added
grep -A 5 "### Prerequisites" CONTRIBUTING.md | grep -i bash
```

### Task 7: Update CONTRIBUTING.md - Update Testing Instructions
**File**: CONTRIBUTING.md
**Action**: MODIFY
**Pattern**: Update lines 32-37 to remove Windows PowerShell mention

**Implementation**:
Replace the installation test example:

```markdown
1. **Clone and test installation**
   ```bash
   git clone https://github.com/trakrf/claude-spec-workflow
   cd claude-spec-workflow
   ./install.sh
   ```

   **Windows**: Run in Git Bash or WSL2 terminal.
```

**Validation**:
```bash
# Verify no PowerShell in testing instructions
sed -n '/### Testing Your Changes/,/## Contribution Guidelines/p' CONTRIBUTING.md | grep -i powershell
# Should return nothing
```

### Task 8: Update TESTING.md - Remove PowerShell Tests
**File**: TESTING.md
**Action**: MODIFY
**Pattern**: Delete Test 2 (lines 28-42) and update Test 3 (lines 44-51)

**Implementation**:

1. **Delete Test 2 entirely** (Windows PowerShell installation test)
2. **Update Test 3** to remove PowerShell reference:

```markdown
### Test 3: Re-installation (Idempotency)
Run installation script again.

**Expected:**
- No errors
- Commands updated/overwritten
- Warning or confirmation message
```

3. **Delete Test 28 reference** if it exists (PowerShell validation)

**Validation**:
```bash
# Verify no PowerShell tests remain
grep -i powershell TESTING.md
# Should return nothing
```

### Task 9: Update TESTING.md - Update Windows Tests to Require Git Bash
**File**: TESTING.md
**Action**: MODIFY
**Pattern**: Update Test 18 (lines 258-267) and Test 7 prerequisites (lines 8-9)

**Implementation**:

1. **Update Prerequisites section** (lines 8-9):
```markdown
## Prerequisites
- Claude Code installed and running
- Git installed
- Bash shell (Git Bash on Windows, native on macOS/Linux)
```

2. **Update Test 18**:
```markdown
### Test 18: Windows Path Handling
On Windows (Git Bash), test with forward slashes:
```
/plan spec/active/test-feature/spec.md
```

**Expected:**
- Commands work correctly in Git Bash
- Forward slashes handled properly
```

**Notes**:
- Remove backslash testing (Git Bash uses forward slashes)
- Clarify Git Bash requirement

**Validation**:
```bash
# Verify Windows tests updated
grep -B 2 -A 5 "Test 18" TESTING.md | grep "Git Bash"
```

### Task 10: Delete PowerShell Scripts
**File**: Multiple
**Action**: DELETE
**Pattern**: Remove all `.ps1` files

**Implementation**:
```bash
git rm install.ps1 init-project.ps1 uninstall.ps1
```

**Validation**:
```bash
# Verify files deleted
ls -la *.ps1
# Should error: No such file or directory

# Verify git staging
git status | grep deleted | grep .ps1
# Should show 3 deleted files
```

### Task 11: Validate Bash Scripts with Shellcheck
**File**: All bash scripts
**Action**: VALIDATE
**Pattern**: Run shellcheck validation from spec/stack.md

**Implementation**:
```bash
# Run shellcheck on all bash scripts
find . -name "*.sh" -not -path "*/\.*" -exec shellcheck {} +
```

**Expected Output**: No errors (scripts should already pass shellcheck per recent commits)

**Validation**:
```bash
# Verify all scripts pass
find . -name "*.sh" -not -path "*/\.*" -exec shellcheck {} + && echo "✅ All bash scripts pass shellcheck"
```

### Task 12: Final Documentation Sweep
**File**: Multiple
**Action**: VALIDATE
**Pattern**: Search for any remaining PowerShell references

**Implementation**:
```bash
# Search for PowerShell references
grep -r -i "powershell" --include="*.md" --include="*.sh" .

# Search for .ps1 references
grep -r "\.ps1" --include="*.md" --include="*.sh" .
```

**Expected Output**:
- Only references should be in `spec/active/eol-powershell-support/spec.md` and this plan
- No references in README.md, CONTRIBUTING.md, TESTING.md, or bash scripts

**If found**: Update those files to remove references

**Validation**:
```bash
# Verify only spec and plan contain references
grep -r -i "powershell" --include="*.md" --exclude-dir="spec/active/eol-powershell-support" . | wc -l
# Should return 0
```

## Risk Assessment

**Risk**: Windows users who previously bookmarked PowerShell installation instructions
**Mitigation**: Clear Prerequisites section explains bash requirement upfront

**Risk**: Missing PowerShell references in documentation
**Mitigation**: Task 12 comprehensive grep for all references

**Risk**: Confusion about "why bash is required"
**Mitigation**: Prerequisites section explains that validation commands are bash-based

**Risk**: WSL users confused by Git Bash focus
**Mitigation**: Provide both links, WSL users follow Linux instructions naturally

## Integration Points

- Git workflow: Standard file deletion + documentation updates
- No code integration (documentation and scripts only)
- No API changes
- No breaking changes to bash scripts themselves

## VALIDATION GATES (MANDATORY)

**CRITICAL**: These are not suggestions - they are GATES that block progress.

After EVERY code change, use commands from `spec/stack.md`:
```bash
# Gate 1: Lint - Shellcheck validation
find . -name "*.sh" -not -path "*/\.*" -exec shellcheck {} +

# Gate 2: Syntax validation
for script in $(find . -name "*.sh" -not -path "*/\.*"); do
  bash -n "$script" || exit 1
done
```

**Note**: No Gate 3 (tests) - this project has no test suite yet. Validation is shellcheck + manual review.

**Enforcement Rules**:
- If ANY gate fails → Fix immediately
- Re-run validation after fix
- Loop until ALL gates pass
- After 3 failed attempts → Stop and ask for help

**Do not proceed to next task until current task passes all gates.**

## Validation Sequence

After each documentation task:
```bash
# Visual inspection
git diff README.md
git diff CONTRIBUTING.md
git diff TESTING.md
```

After bash script validation:
```bash
find . -name "*.sh" -not -path "*/\.*" -exec shellcheck {} +
echo "✅ All bash scripts pass shellcheck"
```

After file deletion:
```bash
git status | grep deleted
echo "✅ All PowerShell files staged for deletion"
```

Final validation before commit:
```bash
# Comprehensive PowerShell reference check
grep -r -i "powershell" --include="*.md" --exclude-dir="spec/active/eol-powershell-support" .
grep -r "\.ps1" --include="*.md" --exclude-dir="spec/active/eol-powershell-support" .
# Both should return nothing

# Shellcheck final pass
find . -name "*.sh" -not -path "*/\.*" -exec shellcheck {} +
echo "✅ Ready to commit"
```

## Plan Quality Assessment

**Complexity Score**: 3/10 (LOW)
**Confidence Score**: 9/10 (HIGH)

**Confidence Factors**:
- ✅ Clear requirements from spec
- ✅ Straightforward file deletions
- ✅ Documentation updates are well-defined
- ✅ Existing bash scripts already pass shellcheck
- ✅ User provided detailed clarifying answers
- ✅ No code logic changes required
- ✅ No external dependencies
- ⚠️ Manual cross-platform testing deferred to 1.0.0 (per user decision)

**Assessment**: High confidence implementation. This is a well-scoped documentation and cleanup task with clear success criteria. The main work is documentation restructuring and file deletion - both low-risk operations. Bash scripts remain unchanged (already validated by shellcheck).

**Estimated one-pass success probability**: 95%

**Reasoning**: Clear spec, straightforward tasks, no complex logic. Main risk is missing a PowerShell reference somewhere, but Task 12 mitigates this with comprehensive grep. User's clear answers to clarifying questions eliminated ambiguity. No cross-platform testing required at this stage (dogfooding on Ubuntu first). This should be a clean implementation.

## Git Workflow

**Branch naming**: `feature/eol-powershell-support` (should already exist or will be created)

**Commit message**:
```
feat: simplify installation by standardizing on bash

Remove PowerShell installation scripts in favor of bash-only installation.
This simplifies maintenance and aligns with the tool's bash-centric
architecture (all validation commands in spec/stack.md are bash).

Benefits:
- 50% reduction in installer codebase (6 files → 3 files)
- Single source of truth for installation logic
- Eliminates dual-implementation maintenance overhead
- Faster iteration on installer features

Windows users: Install Git Bash or use WSL2 (see updated README.md).
The tool requires bash for operation regardless of installer language.

BREAKING CHANGE: PowerShell installers removed. Windows users must use
Git Bash or WSL2. See Prerequisites section in README.md for setup.

Closes #[issue-number if applicable]
```

**Files in commit**:
- `README.md` (modified)
- `CONTRIBUTING.md` (modified)
- `TESTING.md` (modified)
- `install.ps1` (deleted)
- `init-project.ps1` (deleted)
- `uninstall.ps1` (deleted)

**Post-commit verification**:
```bash
git show --stat
# Should show 3 deletions, 3 modifications
```
