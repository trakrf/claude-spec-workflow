# Feature: Consolidate Bootstrap into csw

## Status
**Backlog** - Not yet prioritized for implementation

## Origin
Currently installation and project initialization use separate shell scripts (`install.sh` and `init-project.sh`). This creates an awkward bootstrap experience and inconsistent interface. Everything should go through `csw` for a unified, self-contained CLI tool.

## Outcome
- `./csw install` replaces `./install.sh`
- `csw init <project-dir> [preset]` replaces `init-project.sh`
- Move `bin/csw` to project root for minimal bootstrap friction
- Delete `install.sh` and `init-project.sh`
- All functionality accessible through consistent `csw` interface
- Cleaner bootstrap, simpler mental model, easier to maintain

## User Story
As a developer adopting claude-spec-workflow
I want to use csw for all operations including installation
So that I have a consistent, self-contained CLI experience

## Context

**Current bootstrap flow** (awkward):
```bash
git clone https://github.com/trakrf/claude-spec-workflow.git
cd claude-spec-workflow
./install.sh                    # Shell script
csw init-project /path/to/proj  # Wait, is this csw or init-project.sh?
```

**Proposed flow** (clean):
```bash
git clone https://github.com/trakrf/claude-spec-workflow.git
cd claude-spec-workflow
./csw install                   # csw installs itself
cd /path/to/my-project
csw init . typescript           # csw initializes project
```

**Why this is better**:
- Single interface: everything through `csw`
- Self-documenting: `csw --help` shows all operations including install/init
- No PATH confusion: `csw install` knows where it lives
- Cleaner repo: delete 2 shell scripts
- Easier to test: all logic in one place

## Technical Requirements

### 1. Add `csw install` subcommand

Replace install.sh functionality:

```bash
csw install [options]
```

**Behavior**:
- Detect own installation directory: `INSTALL_DIR="$(cd "$(dirname "$0")/.." && pwd)"`
- Ensure `~/.local/bin` exists: `mkdir -p "$HOME/.local/bin"`
- Create symlink: `ln -sf "$INSTALL_DIR/bin/csw" "$HOME/.local/bin/csw"`
- Set permissions: `chmod +x "$HOME/.local/bin/csw" "$INSTALL_DIR/bin/csw"`
- Check if `~/.local/bin` in PATH
- Display appropriate success message or PATH setup instructions

**Options** (future):
- `--global`: Install to /usr/local/bin (requires sudo)
- `--user-bin DIR`: Install to custom directory

### 2. Add `csw init` subcommand

Replace init-project.sh functionality:

```bash
csw init <project-dir> [preset]
```

**Arguments**:
- `<project-dir>`: Required. Path to project directory (relative or absolute)
- `[preset]`: Optional. Preset name (default: "default")

**Behavior**:
1. **Directory validation**:
   - If `<project-dir>` doesn't exist: prompt "Directory does not exist. Create it? (y/n)"
   - If user says no: exit with error
   - If user says yes: create directory

2. **Existing spec check**:
   - If `<project-dir>/spec/` exists: prompt "spec/ already exists. Reinitialize? (y/n)"
   - If no: exit gracefully
   - If yes: continue (will overwrite structure)

3. **Create spec structure**:
   ```
   spec/
   ├── active/
   ├── backlog/
   ├── README.md
   ├── SHIPPED.md
   ├── stack.md
   ├── template.md
   └── csw           # symlink to csw
   ```

4. **Apply preset** (if specified):
   - Copy preset files from `presets/<preset>/` to project
   - Error if preset doesn't exist

5. **Create spec/csw symlink**:
   - Try to resolve `~/.local/bin/csw` first (if exists and valid)
   - Fallback to direct path: `INSTALL_DIR/bin/csw`
   - Use symlink on Unix, wrapper script on Windows

6. **Success message**:
   ```
   ✓ Initialized claude-spec-workflow in /path/to/project
   ✓ Created spec/ directory structure
   ✓ Project-local wrapper: ./spec/csw

   Next steps:
     cd /path/to/project
     csw spec my-first-feature
   ```

### 3. Add `csw uninstall` subcommand (backlog)

Future enhancement for completeness:

```bash
csw uninstall [options]
```

**Behavior**:
- Remove `~/.local/bin/csw` symlink
- Optionally remove checkout directory (with confirmation)
- Scan for and report any project-local `spec/csw` symlinks (don't remove, just inform)

**Options**:
- `--remove-checkout`: Remove installation directory too (dangerous, confirm)
- `--keep-projects`: Don't scan for project symlinks

### 4. Delete install.sh and init-project.sh

Clean break, no wrappers, no deprecation:
- Delete `install.sh`
- Delete `init-project.sh`
- Delete `uninstall.sh` (will be replaced by `csw uninstall`)

### 5. Update Documentation

Update all references:

**README.md**:
```markdown
## Installation

git clone https://github.com/trakrf/claude-spec-workflow.git
cd claude-spec-workflow
./csw install

## Quick Start

cd /path/to/your-project
csw init .
csw spec my-feature
```

**Other docs**:
- Search for references to `install.sh` → update to `./csw install`
- Search for references to `init-project.sh` → update to `csw init`
- Update CONTRIBUTING.md if it mentions installers
- Update any example commands in spec/ templates
- Upsert to README.md Backlog or Future Enhancements section: "Convenience install script (curl-based one-liner for installation without checkout)"

### 6. Move csw to Project Root

**Action**: Move `bin/csw` → `csw` (project root)

**Rationale**:
- Maximum discoverability: `ls` shows `csw` immediately after clone
- Bootstrap simplicity: `./csw install` is shortest possible path
- Industry patterns: `./gradlew`, `./configure`, `./mvnw` live at root
- Mental model: csw is THE entry point - root placement signals this
- Documentation brevity: cleaner in all docs and examples

**Post-move structure**:
```
claude-spec-workflow/
├── csw              # Main CLI (moved from bin/)
├── scripts/         # Command implementations
├── commands/        # Command docs
└── spec/
```

The `bin/` directory is removed (only held csw).

### 7. Implementation Strategy

**Option A: Inline in csw**
- Add `install` and `init` cases directly in csw
- Simple, everything in one file
- Good for relatively simple logic

**Option B: Script delegation**
- Move logic to `scripts/install.sh` and `scripts/init-project.sh`
- csw calls them: `exec "$SCRIPTS_DIR/install.sh" "$@"`
- Better separation of concerns
- Easier to test independently

**Recommendation**: Start with Option A (inline). Move to Option B if logic gets complex.

## Validation Criteria

- [ ] `bin/csw` moved to project root as `csw`
- [ ] `bin/` directory removed
- [ ] `./csw install` creates `~/.local/bin/csw` symlink correctly
- [ ] `./csw install` checks PATH and provides appropriate guidance
- [ ] `csw init <dir>` creates proper spec/ directory structure
- [ ] `csw init` prompts when directory doesn't exist
- [ ] `csw init` prompts when spec/ already exists
- [ ] `csw init . <preset>` applies preset correctly
- [ ] `spec/csw` symlink works (prefers ~/.local/bin/csw, falls back to direct)
- [ ] `csw init` works with relative paths: `csw init .`, `csw init ./subdir`
- [ ] `csw init` works with absolute paths: `csw init /tmp/test-project`
- [ ] Windows compatibility: wrapper script instead of symlink
- [ ] All documentation updated (README, CONTRIBUTING, etc.)
- [ ] Zero references to `install.sh` or `init-project.sh` remain
- [ ] install.sh and init-project.sh deleted
- [ ] `csw --help` shows install and init subcommands

## Success Metrics

- **2 files deleted**: install.sh, init-project.sh
- **1 directory removed**: bin/ (csw moved to root)
- **2 subcommands added**: install, init (+ uninstall in backlog)
- **Cleaner bootstrap**: `./csw install` vs `./install.sh`
- **Unified interface**: Everything through csw
- **Self-documenting**: `csw --help` shows all operations
- **Zero regression**: All installation functionality preserved

## Testing Strategy

### Install Testing

```bash
# Test basic install
cd /tmp
git clone https://github.com/trakrf/claude-spec-workflow.git test-csw
cd test-csw
./csw install

# Verify symlink created
ls -la ~/.local/bin/csw
readlink -f ~/.local/bin/csw  # Should point to test-csw/csw

# Verify csw works
csw --version
csw --help
```

### Init Testing

```bash
# Test init in existing directory
cd /tmp
mkdir test-project-1
cd test-project-1
git init
csw init .

# Verify structure
ls -la spec/
./spec/csw --version

# Test init with directory creation (confirm yes)
cd /tmp
csw init test-project-2  # Type 'y' when prompted
cd test-project-2
ls -la spec/

# Test init with preset
cd /tmp
mkdir test-typescript
cd test-typescript
csw init . typescript
# Verify preset files copied

# Test init with existing spec/ (confirm no)
cd /tmp/test-project-1
csw init .  # Type 'n' when prompted
# Should exit without changes

# Test init with existing spec/ (confirm yes)
cd /tmp/test-project-1
csw init .  # Type 'y' when prompted
# Should reinitialize
```

### Regression Testing

```bash
# Complete workflow with new bootstrap
cd /tmp
git clone ... test-workflow
cd test-workflow
./csw install

cd /tmp
mkdir my-feature-project
cd my-feature-project
git init
csw init .

# Run through feature lifecycle
csw spec test-feature
csw plan spec/active/test-feature/spec.md
csw build
csw check
csw ship spec/active/test-feature/
csw archive test-feature
```

## Implementation Notes

**Bootstrap self-reference**:
When `csw init` creates `spec/csw`, it should:
1. Check if `~/.local/bin/csw` exists and is valid: `[ -L "$HOME/.local/bin/csw" ] && [ -e "$HOME/.local/bin/csw" ]`
2. If yes: symlink to `~/.local/bin/csw`
3. If no: get own path and symlink directly

**Interactive prompts**:
Use `read -p "prompt" -r` for confirmations. Default to safe behavior (no changes) if non-interactive.

**Error handling**:
- Validate arguments before doing anything
- Exit with clear error messages
- Don't leave partial state on failure

**Preserving functionality**:
Every feature from install.sh and init-project.sh must be preserved:
- All directory creation
- All permission setting
- All PATH checking
- All success/error messages
- All cross-platform handling

## Migration Path

**For existing users** (just you):
- Delete old symlinks manually if needed: `rm ~/.local/bin/csw`
- Run `./csw install` to reinstall
- Projects with `spec/csw` continue to work (just point to new location)

**For new users** (future):
- Clean bootstrap experience from day one
- No confusion about install.sh vs csw

## Design Decisions

**Why move csw to project root instead of keeping in bin/?**
- Maximum discoverability: `ls` shows csw immediately after clone
- Bootstrap simplicity: `./csw install` is the shortest possible path
- Industry patterns: `./gradlew`, `./configure`, `./mvnw` all live at root
- Mental model clarity: csw is THE entry point - root placement signals this
- Documentation brevity: cleaner in all docs and examples
- bin/ only held csw, so removing the directory reduces clutter

**Why delete install.sh instead of wrapping?**
- Cleaner: one clear path
- User is you: no backwards compatibility needed
- Simpler to maintain: one less file
- More honest: `./csw install` shows exactly what's happening

**Why not implement curl-based convenience install script?**
- Scope control: keep consolidate-bootstrap focused
- Solo dev context: checkout-based install works fine for now
- Iteration value: ship this first, learn from usage
- YAGNI: may never need convenience install
- Future option: can add as separate enhancement if needed (upsert to README backlog during implementation)

**Why require project-dir to exist?**
- Matches mental model: create repo/README first, add csw second
- Safer: no surprise directory creation
- Simple prompt handles edge case: "Create it? (y/n)"

**Why prefer ~/.local/bin/csw over direct path?**
- Follows installation expectations
- Makes updates easier (just git pull + reinstall)
- Falls back gracefully if not installed

**Why positional args over flags?**
- Simpler: `csw init . typescript` vs `csw init --dir . --preset typescript`
- Common pattern: `git clone <url> [dir]`, `mkdir <dir>`
- Preset is clearly optional (fewer chars = optional)

## Future Enhancements

**Auto-update**:
```bash
csw update  # git pull in installation directory
```

**Project detection**:
```bash
csw init  # No args, defaults to current directory
```

**Preset management**:
```bash
csw preset list
csw preset show typescript
csw preset validate my-custom-preset
```

**Installation variants**:
```bash
csw install --global        # Install to /usr/local/bin
csw install --link-only     # Don't copy, just symlink checkout
```

## References

- **Related spec**: script-library-phase3-wiring (wiring commands to csw)
- **Current installers**: install.sh, init-project.sh, uninstall.sh
- **Target**: csw (main CLI entry point, moved to project root)
- **Scripts**: Will use scripts/ for install/init logic if complexity warrants
