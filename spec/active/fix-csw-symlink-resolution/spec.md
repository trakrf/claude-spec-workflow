# Feature: Fix CSW Symlink Resolution

## Origin
This specification emerged from debugging the `csw cleanup` command failure. When running `csw` via the symlink at `~/.local/bin/csw`, the wrapper script was looking for scripts in the wrong directory (`~/.local/scripts/` instead of `~/claude-spec-workflow/scripts/`).

## Outcome
The `csw` wrapper correctly resolves symlinks to find the actual project directory, allowing all csw commands to work properly when invoked via the `~/.local/bin/csw` symlink.

## User Story
As a developer using the Claude Spec Workflow
I want to run `csw` commands from anywhere via the symlink
So that the wrapper finds the actual scripts in my project directory without duplicating files

## Context

**Discovery**: Running `csw cleanup` failed with:
```
/home/mike/.local/bin/csw: line 38: /home/mike/.local/scripts/cleanup.sh: No such file or directory
```

**Current Architecture** (by design):
- `~/.local/bin/csw` → symlink to `~/claude-spec-workflow/bin/csw`
- Scripts remain in git repo at `~/claude-spec-workflow/scripts/`
- No duplicate files, single source of truth

**Problem**: The wrapper script was using:
```bash
CSW_HOME="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)"
```

When called via symlink:
- `${BASH_SOURCE[0]}` = `/home/mike/.local/bin/csw` (symlink path)
- Calculated `CSW_HOME` = `/home/mike/.local/` (wrong!)
- Looked for scripts in `/home/mike/.local/scripts/` (doesn't exist)

**Desired**: Wrapper should:
1. Detect it's running from a symlink
2. Resolve the symlink to find actual project directory
3. Use scripts from the project directory
4. Work on Linux, macOS, WSL, Git Bash for Windows

## Technical Requirements

### Core Fix
- Implement symlink resolution loop before calculating `CSW_HOME`
- Follow symlinks to find the actual script location
- Handle both absolute and relative symlink targets

### Cross-Platform Compatibility
- Must work on Linux (GNU userland)
- Must work on macOS (BSD userland)
- Must work on WSL (Linux environment on Windows)
- Must work on Git Bash for Windows (MSYS2 environment)

### Architecture Principles
- **Principle of Least Surprise**: Use `~/.local/bin/` (standard Unix location for user binaries)
- **Single Source of Truth**: Scripts stay in git repo, no duplicates
- **Updates via Git**: `git pull` updates everything, no reinstall needed
- **No Privilege Escalation**: User-local installation only

## Code Examples

### Solution Implemented
```bash
# Detect installation directory from this script's location
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

**How it works**:
1. Start with `${BASH_SOURCE[0]}` (could be symlink)
2. Loop while `SOURCE` is a symlink (`-h` test)
3. Get the directory of the current symlink
4. Read the symlink target with `readlink`
5. If target is relative, resolve it relative to symlink's directory
6. Continue until we reach the actual file
7. Calculate project home from the resolved path

**Pattern origin**: This is the standard symlink resolution pattern used by Node.js, Homebrew, and other cross-platform tools.

## Validation Criteria

- [x] `csw cleanup` runs successfully from any directory
- [x] Wrapper resolves symlink correctly (tested)
- [x] Scripts are found in project directory, not `~/.local/scripts/`
- [ ] Works on Linux (verified)
- [ ] Works on macOS (needs testing)
- [ ] Works on WSL (needs testing)
- [ ] Works on Git Bash for Windows (needs testing)

## Conversation References

**Key Insight**:
> "wait when did that happen? when did we introduce ~/.local/scripts/? i dont want that. my thought was that we have the csw wrapper in ~/.local/bin and have that linked back to ~/claude-spec-workflow"

**Design Question**:
> "ultrathink. what would principle of least surprise tell us to do? what will work consistently across git bash for windows, wsl, macos, and linux?"

**Decision**:
- Use `~/.local/bin/` for symlink (standard Unix convention)
- Keep scripts in project directory (single source of truth)
- Resolve symlinks properly (cross-platform standard pattern)

**Architecture Never Changed**:
> "We never introduced ~/.local/scripts/ - that was a bug in the old symlink resolution logic. Your original instinct was correct!"

## Edge Cases

1. **Relative Symlinks**: Handle with `[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"`
2. **Multi-level Symlinks**: Loop handles chains of symlinks
3. **Broken Symlinks**: Will fail gracefully (bash will error on `cd -P`)
4. **No Symlink**: Works fine, just skips the loop

## Architecture: Why This Fix is in Only One Place

**This is strictly a change to `<project>/bin/csw`** (the wrapper that gets symlinked).

**The architecture is ALREADY DRY by design:**

1. **Single symlinked entry point**: `~/.local/bin/csw` → `~/claude-spec-workflow/bin/csw`
   - Only the project's `bin/csw` wrapper needs symlink resolution (it's the only file that gets symlinked)
   - All other scripts are called with absolute paths by this wrapper

2. **Symlink resolution happens once**: The wrapper resolves its own location at startup

3. **Scripts called with absolute paths**: `exec "$SCRIPT_DIR/$COMMAND.sh"` passes full paths

4. **Library scripts use relative sourcing**: `source "$(dirname "${BASH_SOURCE[0]}")/common.sh"`
   - They receive absolute paths from the wrapper, so `dirname` works correctly
   - No symlink resolution needed in library files

**Result**: Fix symlink resolution in one place (`<project>/bin/csw`), everything else works.

## Implementation Notes

- File modified: `bin/csw` (lines 6-15)
- Change type: Bug fix (symlink resolution)
- Breaking changes: None (fixes existing broken behavior)
- Testing: Verified with `csw cleanup` command
