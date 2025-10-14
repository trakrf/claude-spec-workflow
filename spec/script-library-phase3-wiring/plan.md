# Implementation Plan: Script Library Phase 3 - Wire It Up
Generated: 2025-10-14
Specification: spec.md

## Understanding

This is Phase 3 of a 3-phase refactoring to build a maintainable script library for the Claude Spec Workflow system. Phases 1 and 2 are complete and merged:
- Phase 1: Built library functions (scripts/lib/)
- Phase 2: Extracted command logic to scripts (scripts/*.sh)

**This phase** wires everything together by:
1. Updating 5 command files to call scripts instead of embedding bash
2. Fixing bin/csw hardcoded path to use dynamic detection
3. Updating installers to set up csw CLI access

**Key insight from clarifying discussion**: The scripts are utilities FOR CLAUDE TO CALL via the Bash tool, not for direct user usage. The prompts (commands/*.md) remain the primary interface - they guide Claude's behavior with personas, ULTRATHINK sections, and process steps. The bash blocks in those prompts just need to be cleaner (call scripts instead of embedding logic). The fallback pattern exists for Claude's bash execution environment, not to enable "three access methods" for users.

**Clarifications**:
- Question 1: plan.md uses `"$SPEC_FILE"` from scripts/plan.sh's smart resolution output
- Question 2: Commands assume execution from project root (./spec/csw is relative to root)
- Question 3: Only replace executable bash blocks, keep documentation/example blocks in prompt text
- **Descoped**: Shell-script usage for users - this is about cleaning up prompts for Claude
- **Focus**: Fast iterative Claude Code workflow (90% of value)

## Relevant Files

**Files to Modify**:
1. `bin/csw` (line 6) - Replace hardcoded path with dynamic detection
2. `commands/spec.md` (~line 126) - Replace 1 bash block with fallback pattern
3. `commands/plan.md` (multiple) - Replace 7 bash blocks with fallback pattern
4. `commands/build.md` (~line 176) - Replace 1 bash block with fallback pattern
5. `commands/check.md` (multiple) - Replace 13 bash blocks with fallback pattern
6. `commands/ship.md` (multiple) - Replace 6 bash blocks with fallback pattern
7. `install.sh` (after line 41) - Add csw installation section + update final message
8. `init-project.sh` (after line 123) - Add spec/csw symlink section + update usage instructions

**Reference Patterns**:
- `bin/csw` (line 6) - Current: `CSW_HOME="$HOME/.claude-spec-workflow"`
- Dynamic detection pattern: `CSW_HOME="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)"`
- Fallback pattern provided in spec (lines 31-43) - for Claude's bash environment

**Scripts Available** (no changes needed - Phase 2 complete):
- `scripts/spec.sh` - Handles spec creation
- `scripts/plan.sh` - Handles planning with smart resolution
- `scripts/build.sh` - Handles build execution
- `scripts/check.sh` - Handles validation suite
- `scripts/ship.sh` - Handles shipping/PR creation

## Architecture Impact

- **Subsystems affected**: CLI/Commands (all bash, single subsystem)
- **New dependencies**: None
- **Breaking changes**: None (commands work identically for Claude, just cleaner implementation)

## Task Breakdown

### Task 1: Fix bin/csw hardcoded path
**File**: bin/csw
**Action**: MODIFY (line 6)
**Pattern**: Replace hardcoded CSW_HOME with dynamic detection

**Implementation**:
Replace line 6:
```bash
# Before:
CSW_HOME="$HOME/.claude-spec-workflow"

# After:
# Detect installation directory from this script's location
CSW_HOME="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)"
```

**Why**: Allows csw to work from any checkout directory.

**Validation**:
```bash
shellcheck bin/csw
bash -n bin/csw
```

### Task 2: Update commands/spec.md
**File**: commands/spec.md
**Action**: MODIFY (replace bash block around line 126)
**Pattern**: Replace single executable bash block with fallback pattern

**Implementation**:
Find the ```bash...``` block (only 1 executable block in file) and replace with:
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

**Important**: Keep all prompt text (persona, ULTRATHINK, process steps) - only replace the executable bash block.

**Validation**:
```bash
# Extract and validate bash syntax
bash -n <(grep -Pzo '```bash\K[\s\S]*?(?=```)' commands/spec.md | head -c -1)
```

### Task 3: Update commands/plan.md
**File**: commands/plan.md
**Action**: MODIFY (replace 7 bash blocks with 1)
**Pattern**: Replace all executable bash blocks with single fallback pattern

**Implementation**:
Find all ```bash...``` blocks (7 total showing sequence/examples in documentation) and consolidate to SINGLE executable bash block:
```bash
# Try csw in PATH first, fall back to project-local wrapper
if command -v csw &> /dev/null; then
    csw plan "$SPEC_FILE"
elif [ -f "./spec/csw" ]; then
    ./spec/csw plan "$SPEC_FILE"
else
    echo "❌ Error: csw not found"
    echo "   Run install.sh to set up csw globally"
    echo "   Or use: ./spec/csw plan (if initialized)"
    exit 1
fi
```

**Note**: Uses `"$SPEC_FILE"` (from scripts/plan.sh smart resolution) not `"$@"`.

**Important**: This file has extensive process documentation with personas, ULTRATHINK, archive workflow - all that text stays. Only the executable bash blocks are replaced.

**Validation**:
```bash
bash -n <(grep -Pzo '```bash\K[\s\S]*?(?=```)' commands/plan.md | head -c -1)
```

### Task 4: Update commands/build.md
**File**: commands/build.md
**Action**: MODIFY (replace bash block around line 176)
**Pattern**: Replace single bash block with fallback pattern (no arguments)

**Implementation**:
Replace the ```bash...``` block with:
```bash
# Try csw in PATH first, fall back to project-local wrapper
if command -v csw &> /dev/null; then
    csw build
elif [ -f "./spec/csw" ]; then
    ./spec/csw build
else
    echo "❌ Error: csw not found"
    echo "   Run install.sh to set up csw globally"
    echo "   Or use: ./spec/csw build (if initialized)"
    exit 1
fi
```

**Validation**:
```bash
bash -n <(grep -Pzo '```bash\K[\s\S]*?(?=```)' commands/build.md | head -c -1)
```

### Task 5: Update commands/check.md
**File**: commands/check.md
**Action**: MODIFY (replace 13 bash blocks with 1)
**Pattern**: Replace all executable bash blocks with single fallback pattern (no arguments)

**Implementation**:
Find all ```bash...``` blocks (13 total showing validation examples) and consolidate to SINGLE executable bash block:
```bash
# Try csw in PATH first, fall back to project-local wrapper
if command -v csw &> /dev/null; then
    csw check
elif [ -f "./spec/csw" ]; then
    ./spec/csw check
else
    echo "❌ Error: csw not found"
    echo "   Run install.sh to set up csw globally"
    echo "   Or use: ./spec/csw check (if initialized)"
    exit 1
fi
```

**Important**: This file has extensive documentation (stack-aware validation, monorepo support, ULTRATHINK sections) - all that text stays, only executable bash blocks are replaced.

**Validation**:
```bash
bash -n <(grep -Pzo '```bash\K[\s\S]*?(?=```)' commands/check.md | head -c -1)
```

### Task 6: Update commands/ship.md
**File**: commands/ship.md
**Action**: MODIFY (replace 6 bash blocks with 1)
**Pattern**: Replace all executable bash blocks with single fallback pattern

**Implementation**:
Find all ```bash...``` blocks (6 total showing sequence/examples) and consolidate to SINGLE executable bash block:
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
bash -n <(grep -Pzo '```bash\K[\s\S]*?(?=```)' commands/ship.md | head -c -1)
```

### Task 7: Update install.sh - Add csw installation
**File**: install.sh
**Action**: MODIFY (add section after line 41, update final message)
**Pattern**: Add csw CLI installation after command installation loop

**Implementation**:
After the command installation loop (after line 41, after `done`), insert:

```bash
# Install csw CLI
echo ""
echo "🔧 Installing csw CLI..."
CSW_BIN_DIR="$HOME/.local/bin"
if [ ! -d "$CSW_BIN_DIR" ]; then
    echo "   📁 Creating $CSW_BIN_DIR..."
    mkdir -p "$CSW_BIN_DIR"
fi

echo "   🔗 Creating symlink: csw -> $SCRIPT_DIR/bin/csw"
ln -sf "$SCRIPT_DIR/bin/csw" "$CSW_BIN_DIR/csw"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$CSW_BIN_DIR:"* ]]; then
    echo ""
    echo "⚠️  Note: $CSW_BIN_DIR is not in your PATH"
    echo "   Add this line to your ~/.bashrc or ~/.zshrc:"
    echo ""
    echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "   Then run: source ~/.bashrc (or ~/.zshrc)"
    echo ""
    echo "   Alternatively, use ./spec/csw in your projects"
fi
```

Then update the final message section (around line 87) to:
```bash
echo "Available commands (use as /command in Claude or csw command in terminal):"
echo "  spec    - Convert conversation to specification"
echo "  plan    - Generate implementation plan (interactive)"
echo "  build   - Execute implementation with validation"
echo "  check   - Pre-release validation check"
echo "  ship    - Complete feature and prepare PR"
echo ""
echo "Usage:"
echo "  In Claude Code:  /plan spec/feature-name/spec.md"
echo "  In terminal:     csw plan spec/feature-name/spec.md"
echo "  In project:      ./spec/csw plan spec/feature-name/spec.md"
```

**Validation**:
```bash
shellcheck install.sh
bash -n install.sh
```

### Task 8: Update init-project.sh - Add spec/csw symlink
**File**: init-project.sh
**Action**: MODIFY (add section after line 123, update usage message)
**Pattern**: Add project-local csw symlink after .gitignore section

**Implementation**:
After the .gitignore section (after line 123, after `fi`), insert:

```bash
# Create spec/csw symlink for project-local csw access
echo "🔗 Creating spec/csw symlink..."
CSW_BIN="$SCRIPT_DIR/bin/csw"
if [ -f "$CSW_BIN" ]; then
    ln -sf "$CSW_BIN" "$PROJECT_DIR/spec/csw"
    echo "   ✓ Created: spec/csw -> $CSW_BIN"
else
    echo "   ⚠️  Warning: csw binary not found at $CSW_BIN"
    echo "   Run install.sh to set up csw CLI"
fi
```

Then update the "3. Generate implementation plan:" section (around line 150) to:
```bash
echo "3. Generate implementation plan:"
echo "   In Claude Code:  /plan my-feature"
echo "   In terminal:     csw plan my-feature"
echo "   In project:      ./spec/csw plan my-feature"
```

**Validation**:
```bash
shellcheck init-project.sh
bash -n init-project.sh
```

### Task 9: Final validation
**Action**: Run comprehensive validation suite
**Pattern**: Ensure all changes pass validation gates

**Implementation**:
```bash
# Validate all shell scripts
find . -name "*.sh" -not -path "*/\.*" -exec shellcheck {} +

# Syntax check all bash scripts
for script in $(find . -name "*.sh" -not -path "*/\.*"); do
  bash -n "$script" || exit 1
done

# Verify command bash blocks are syntactically valid (best effort)
for cmd in commands/*.md; do
  echo "Checking $cmd..."
  bash -n <(grep -Pzo '```bash\K[\s\S]*?(?=```)' "$cmd" | head -c -1) 2>/dev/null || echo "  (markdown file, syntax check may not apply)"
done

echo "✅ All validation gates passed"
```

**Success criteria**:
- All .sh files pass shellcheck
- All .sh files pass bash syntax check
- Command bash blocks are syntactically valid
- No regression in functionality

## Risk Assessment

**Low Risk - Mechanical Refactoring**:
- ✅ Well-defined transformation (replace bash blocks with fallback pattern)
- ✅ All logic already exists in scripts/ (Phase 2 complete)
- ✅ Copy-paste implementation from spec
- ✅ Simple validation (shellcheck + syntax check)
- ✅ Easy rollback (git revert individual files)

**Potential Issues**:
- **Risk**: Bash blocks in commands/*.md might not extract cleanly for validation
  **Mitigation**: Manual review of each file, verify bash syntax after replacement

- **Risk**: Accidentally removing prompt documentation while replacing bash blocks
  **Mitigation**: Only replace ```bash...``` blocks, preserve all persona/ULTRATHINK/process text

- **Risk**: $SPEC_FILE undefined if scripts/plan.sh changes
  **Mitigation**: Spec confirms $SPEC_FILE comes from scripts/plan.sh output (Phase 2)

## Integration Points

- **bin/csw**: Calls scripts/*.sh (already integrated in Phase 2)
- **install.sh**: Creates ~/.local/bin/csw symlink (for Claude's PATH)
- **init-project.sh**: Creates ./spec/csw symlink (for fallback)
- **commands/*.md**: Call csw via fallback pattern (Claude executes via Bash tool)

## VALIDATION GATES (MANDATORY)

**CRITICAL**: These are not suggestions - they are GATES that block progress.

After EVERY file change:
```bash
# Gate 1: Shellcheck (for .sh files)
shellcheck <file>.sh

# Gate 2: Syntax check
bash -n <file>
```

For command files (.md):
```bash
# Extract and syntax check bash blocks (best effort)
bash -n <(grep -Pzo '```bash\K[\s\S]*?(?=```)' commands/<file>.md | head -c -1)
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
# For .sh files:
shellcheck <file>.sh
bash -n <file>.sh

# For .md files (best effort):
bash -n <(grep -Pzo '```bash\K[\s\S]*?(?=```)' <file>.md | head -c -1)
```

Final validation (Task 9):
```bash
# All shell scripts
find . -name "*.sh" -not -path "*/\.*" -exec shellcheck {} +

# Syntax check all
for script in $(find . -name "*.sh" -not -path "*/\.*"); do
  bash -n "$script" || exit 1
done
```

## Plan Quality Assessment

**Complexity Score**: 4/10 (LOW-MEDIUM)
- Modifying 8 files, creating 0 files
- Single subsystem (CLI/commands)
- 9 discrete tasks
- No new dependencies
- Existing patterns (mechanical refactoring)

**Confidence Score**: 9/10 (HIGH)

**Confidence Factors**:
✅ Clear requirements from spec with concrete code examples
✅ Mechanical refactoring (copy-paste fallback pattern)
✅ All logic already exists in scripts/ (Phase 2 complete)
✅ Simple validation (shellcheck + syntax)
✅ Spec provides exact code for each transformation
✅ No external dependencies
✅ Easy rollback (independent file changes)
✅ Clarifying discussion resolved ambiguities

**Assessment**: This is a straightforward mechanical refactoring with high confidence. All implementation details are specified in the spec with copy-paste ready code. The clarifying discussion confirmed this is about cleaning up prompts for Claude's workflow, not enabling general shell usage. Tasks are independent (each file change stands alone). Validation is clear (shellcheck + syntax).

**Estimated one-pass success probability**: 95%

**Reasoning**: The spec provides exact code for every transformation. Tasks are independent. Validation is clear. Only minor risk is markdown bash block extraction for validation, but that's non-critical (manual review suffices). This is "copy from spec, validate, move to next file" implementation. The clarifying discussion removed scope creep and focused on the core value: fast iterative Claude Code workflow.
