# Feature: Script Library Phase 3 - Wire It Up

## Origin
Part 3 of 3-phase refactoring. Phase 1 built primitives, Phase 2 extracted logic to scripts. This phase wires everything together: update commands to call scripts, update installers, test end-to-end.

## Outcome
5 existing commands (spec, plan, build, check, ship) use `csw {command}` instead of embedded bash blocks. Prompt text remains as before. Only inline bash code blocks replaced with single csw call per command. Installers set up csw in ~/.local/bin and spec/csw. Full workflow tested and working.

## User Story
As a developer using claude-spec-workflow
I want all commands to use the new script library
So that I can run commands via `/check`, `csw check`, or `./spec/csw check` interchangeably

## Context

**Phase 1 Complete**: Library functions merged
**Phase 2 Complete**: Script extraction merged
**This Phase**: Wire everything together and test

**Why this sequence**: Build primitives (✅) → compose primitives (✅) → integrate (this phase)

## Technical Requirements

### Update Commands

Replace all embedded bash blocks with single csw call per command. Keep all prompt text (persona, process steps, validation rules, etc.) - only replace the executable bash blocks.

**commands/spec.md**:
- Current: 1 bash block
- After: Single csw call with fallback
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

**commands/plan.md**:
- Current: 7 bash blocks (showing sequence/examples in prompt)
- After: Single csw call with fallback (same pattern as spec.md)
- Replace `"$@"` with `"$SPEC_FILE"` in the csw call
- All sequencing handled by scripts/plan.sh

**commands/build.md**:
- Current: 1 bash block
- After: Single csw call with fallback (same pattern as spec.md, no arguments)
- All implementation logic handled by scripts/build.sh

**commands/check.md**:
- Current: 13 bash blocks (showing examples in prompt)
- After: Single csw call with fallback (same pattern as spec.md, no arguments)
- All validation logic handled by scripts/check.sh

**commands/ship.md**:
- Current: 6 bash blocks (showing sequence/examples in prompt)
- After: Single csw call with fallback (same pattern as spec.md)
- All shipping logic handled by scripts/ship.sh

**Pattern**: All commands use the same fallback structure:
1. Try `csw {command}` if in PATH
2. Fall back to `./spec/csw {command}` if available
3. Error with helpful message if neither found

**Note**: commands/archive.md doesn't exist yet (script exists but command file will be created in future phase).

### Update bin/csw

Fix hardcoded path to use dynamic detection:

```bash
# Before (line 6):
CSW_HOME="$HOME/.claude-spec-workflow"

# After:
# Detect installation directory from this script's location
CSW_HOME="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)"
```

This allows csw to work regardless of installation location.

### Update install.sh

Add csw installation section after command installation loop (after line 41):

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

Also update the final message to mention csw CLI:

```bash
# Update the "Available commands:" section to show three access methods:
echo "Available commands (use as /command in Claude or csw command in terminal):"
echo "  spec    - Convert conversation to specification"
echo "  plan    - Generate implementation plan (interactive)"
echo "  build   - Execute implementation with validation"
echo "  check   - Pre-release validation check"
echo "  ship    - Complete feature and prepare PR"
echo ""
echo "Usage:"
echo "  In Claude Code:  /plan spec/active/feature-name/spec.md"
echo "  In terminal:     csw plan spec/active/feature-name/spec.md"
echo "  In project:      ./spec/csw plan spec/active/feature-name/spec.md"
```

### Update init-project.sh

Add project-local csw symlink creation after .gitignore section (after line 123):

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

Also update the final usage instructions to show three access methods:

```bash
# Update "3. Generate implementation plan:" section to:
echo "3. Generate implementation plan:"
echo "   In Claude Code:  /plan spec/active/my-feature"
echo "   In terminal:     csw plan spec/active/my-feature"
echo "   In project:      ./spec/csw plan spec/active/my-feature"
```

## Validation Criteria

 **All commands updated**: 5 commands (spec, plan, build, check, ship) call csw instead of embedded bash
 **Bash blocks replaced**: All executable bash blocks replaced with single csw call per command
 **Prompt text preserved**: All persona descriptions, process steps, validation rules remain unchanged
 **install.sh updated**: csw installation section added
 **init-project.sh updated**: spec/csw symlink creation added
 **Commands work via /check**: Claude Code slash commands functional
 **Commands work via csw check**: Direct CLI execution functional
 **Commands work via ./spec/csw check**: Project-local execution functional
 **Zero regression**: All commands produce identical output to before refactor
 **Installation works**: Fresh install.sh creates csw in ~/.local/bin
 **Project setup works**: Fresh init-project.sh creates spec/csw symlink

## Success Metrics

 **5 commands simplified**: spec, plan, build, check, ship now use single csw call
 **Bash blocks replaced**: 28 total bash blocks (1+7+1+13+6) replaced with 5 csw calls
 **Prompt text preserved**: All instructional content remains intact
 **3 access methods work**: /check, csw check, ./spec/csw check
 **Zero regression**: All workflow steps work identically
 **Cross-platform tested**: Linux, Mac, Windows Git Bash

## Testing Strategy

### Command Testing (via Claude Code)
```bash
# Test each slash command
/check
/spec test-feature
/plan spec/active/test-feature/spec.md
/build
/ship spec/active/test-feature/
/archive test-feature
```

### CLI Testing (direct csw)
```bash
# Test direct csw calls
csw --help
csw --version
csw check
csw spec test-feature
csw plan spec/active/test-feature/spec.md
```

### Project-local Testing
```bash
# Test project-local wrapper
./spec/csw check
./spec/csw --help
```

### Installation Testing
```bash
# Test fresh installation
cd /tmp
rm -rf test-csw-install
git clone https://github.com/trakrf/claude-spec-workflow test-csw-install
cd test-csw-install
./install.sh

# Verify csw exists
ls -la ~/.local/bin/csw
csw --version

# Test project setup
cd /tmp
mkdir test-project
cd test-project
git init
csw init-project  # Or wherever you cloned: /path/to/clone/init-project.sh

# Verify spec/csw exists
ls -la spec/csw
./spec/csw --version
```

### Full Workflow Test
```bash
# Complete cycle
cd /home/mike/claude-spec-workflow
git checkout main
git pull

# Create test feature
/spec test-enhancement
# Edit spec/active/test-enhancement/spec.md

# Plan and build
/plan spec/active/test-enhancement/spec.md
/build

# Validate
/check

# Ship
/ship spec/active/test-enhancement/

# Archive (after merge)
/archive test-enhancement
```

### Regression Testing
Run all the tests that were passing before the refactor:
- shellcheck on existing scripts
- Any test suite that exists
- Manual smoke test of each command

## Implementation Notes

**Key changes**:
- Commands become thin wrappers (~10 lines with fallback logic)
- All logic now in scripts/ (testable, maintainable)
- Installation sets up global (~/.local/bin/csw) and project-local (./spec/csw) access
- Three access patterns all work identically

**Fallback mechanism**:
- Commands try `csw` in PATH first (fastest)
- Fall back to `./spec/csw` if csw not in PATH
- Provides clear error if neither found

**Installation flow**:
1. User runs `install.sh` → creates ~/.local/bin/csw symlink to repo's bin/csw
2. User runs `init-project.sh` in their project → creates ./spec/csw symlink to repo's bin/csw
3. Commands work via /command (Claude), csw (terminal), or ./spec/csw (project-local)

**What this phase completes**:
- ✅ All bash extracted from commands
- ✅ Commands call csw
- ✅ Installers set up csw
- ✅ Full workflow tested
- ✅ Zero regression validated

**After this phase**:
- Ship to main
- Dogfood the new workflow
- Monitor for any issues
- Document learnings in SHIPPED.md

## Windows Compatibility Notes

**Symlink vs Wrapper**:
- Windows requires admin privileges for symlinks
- init-project.sh detects Windows and creates wrapper script instead
- Functionally identical to symlink
- Git Bash, WSL, MSYS2 all handle this correctly

## Error Scenarios to Test

 **csw not in PATH**: Should still work via ./spec/csw
 **Missing script**: csw should show clear error
 **Script fails**: Should exit with proper code
 **Wrong arguments**: Should show usage message
 **Git not available**: Should fail gracefully

## Example: check.md Transformation

**Before** (commands/check.md, ~100 lines):
```markdown
---
name: check
description: Validate code quality
---

Run validation suite.

```bash
echo "Running validation suite..."

# Detect package manager
if [ -f "package-lock.json" ]; then
    PM="npm"
elif [ -f "yarn.lock" ]; then
    PM="yarn"
else
    PM="npm"
fi

# Run tests
if [ -f "package.json" ]; then
    $PM test || exit 1
fi

# Run linter...
# (80 more lines of bash)
```

**After** (commands/check.md, ~15 lines):
```markdown
---
name: check
description: Validate code quality (tests, lint, types, build)
---

Run comprehensive validation suite.

```bash
csw check
```

This validates your code by running:
- Tests
- Linter
- Type checker
- Build process

Implementation: scripts/check.sh in the csw installation
```

## References

- **Phase 1**: Library functions (merged)
- **Phase 2**: Script extraction (merged)
- **Commands to update**: commands/*.md (5 files: spec, plan, build, check, ship)
- **bin/csw to fix**: Remove hardcoded path, add dynamic detection
- **Installers to update**: install.sh (add csw installation), init-project.sh (add spec/csw symlink)
- **Scripts available**: scripts/{spec,plan,build,check,ship,archive}.sh (archive.sh exists but commands/archive.md doesn't - future work)
- **Full spec**: spec/active/script-library-enhancement/spec.md (original comprehensive spec)

## Task Summary

**8 files to modify**:
1. bin/csw - Fix hardcoded CSW_HOME path
2. commands/spec.md - Replace bash block with csw call + fallback
3. commands/plan.md - Replace bash blocks with csw call + fallback
4. commands/build.md - Replace bash block with csw call + fallback
5. commands/check.md - Replace bash blocks with csw call + fallback
6. commands/ship.md - Replace bash blocks with csw call + fallback
7. install.sh - Add csw installation section + update final message
8. init-project.sh - Add spec/csw symlink section + update usage instructions

**Expected outcome**: ~28 bash blocks removed, replaced with 5 consistent fallback patterns + bin/csw fixed + 2 installers enhanced
