# Feature: Script Library Phase 3 - Wire It Up

## Origin
Part 3 of 3-phase refactoring. Phase 1 built primitives, Phase 2 extracted logic to scripts. This phase wires everything together: update commands to call scripts, update installers, test end-to-end.

## Outcome
All commands use `csw {command}` instead of embedded bash. Installers set up csw in ~/.local/bin and spec/csw. Full workflow tested and working. ~400 lines deleted from commands/*.md, replaced with clean 1-line calls.

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

### Update Commands (Delete ~400 lines, Add ~6 lines)

Replace embedded bash with csw calls:

**commands/spec.md**:
```bash
# Before: ~50 lines of bash
# After:
csw spec "$@"
```

**commands/plan.md**:
```bash
# Before: ~120 lines of bash
# After:
csw plan "$SPEC_FILE"
```

**commands/build.md**:
```bash
# Before: ~60 lines of bash
# After:
csw build
```

**commands/check.md**:
```bash
# Before: ~80 lines of bash
# After:
csw check
```

**commands/ship.md**:
```bash
# Before: ~90 lines of bash
# After:
csw ship "$@"
```

**commands/archive.md**:
```bash
# Before: ~50 lines of bash
# After:
csw archive "$1"
```

### Update install.sh

Add csw installation section after command setup:

```bash
# Install csw to ~/.local/bin
echo ""
info "Installing csw CLI..."

# Detect installation directory
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure ~/.local/bin exists
mkdir -p "$HOME/.local/bin"

# Create symlink
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
    success "csw is ready to use: csw <command>"
fi
```

### Update init-project.sh

Add project-local csw symlink creation after spec directory setup:

```bash
# Create project-local csw symlink
info "Setting up project-local csw wrapper..."

# Find csw installation via the symlink in PATH
CSW_PATH="$(command -v csw)" || { error "csw not found in PATH. Run install.sh first."; exit 1; }
CSW_TARGET="$(readlink -f "$CSW_PATH" 2>/dev/null || realpath "$CSW_PATH" 2>/dev/null)" || CSW_TARGET="$CSW_PATH"
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

success "Project-local wrapper created: ./spec/csw"
```

## Validation Criteria

 **All commands updated**: 6 commands call csw instead of embedded bash
 **~400 lines deleted**: From commands/*.md files
 **install.sh updated**: csw installation section added
 **init-project.sh updated**: spec/csw symlink creation added
 **Commands work via /check**: Claude Code slash commands functional
 **Commands work via csw check**: Direct CLI execution functional
 **Commands work via ./spec/csw check**: Project-local execution functional
 **Zero regression**: All commands produce identical output to before refactor
 **Installation works**: Fresh install.sh creates csw in ~/.local/bin
 **Project setup works**: Fresh init-project.sh creates spec/csw symlink

## Success Metrics

 **6 commands simplified**: Average 15-20 lines per command (from ~100+)
 **~400 lines deleted**: Bash removed from commands
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
- Commands become thin wrappers (1-2 lines of bash)
- All logic now in scripts/ (testable, maintainable)
- Installation sets up global and project-local access
- Three access patterns all work identically

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
- **Commands to update**: commands/*.md (6 files)
- **Installers to update**: install.sh, init-project.sh
- **Full spec**: spec/active/script-library-enhancement/spec.md (original comprehensive spec)
