# Feature: Fix csw install symlink creation

## Origin
Bug discovered when `./csw install` failed to create `~/.local/bin/csw` symlink despite reporting success.

## Outcome
The `csw install` command will successfully complete and create the CLI symlink in `~/.local/bin/csw`.

## User Story
As a user
I want `csw install` to create the global CLI symlink
So that I can use `csw` commands from anywhere in my system

## Context
**Discovery**: Running `./csw install` appeared to succeed but stopped after "↻ Updated build.md" without creating the symlink.

**Current**: Script exits prematurely during command installation loop due to arithmetic operation failure.

**Desired**: Script completes all installation steps including symlink creation.

## Root Cause
The script uses `set -e` (exit on error). Post-increment operators `((updated++))` and `((installed++))` return the old value before incrementing. When the counter is 0, the expression evaluates to 0, which bash treats as a failure, causing premature exit.

## Technical Requirements
- Fix arithmetic increment operations in csw:86,89
- Change from `((var++))` to `var=$((var + 1))`
- Maintain accurate counters for installed/updated commands
- Ensure script completes all installation steps

## Code Examples

**Before (broken):**
```bash
if [ -f "$target" ]; then
    echo "   ↻ Updated $filename"
    ((updated++))
else
    echo "   ✓ Installed $filename"
    ((installed++))
fi
```

**After (fixed):**
```bash
if [ -f "$target" ]; then
    echo "   ↻ Updated $filename"
    updated=$((updated + 1))
else
    echo "   ✓ Installed $filename"
    installed=$((installed + 1))
fi
```

## Validation Criteria
- [ ] Delete `~/.local/bin/csw` if it exists
- [ ] Run `./csw install` completes without errors
- [ ] Verify `~/.local/bin/csw` symlink is created
- [ ] Symlink points to correct location: `~/claude-spec-workflow/csw`
- [ ] All 6 command files are processed and reported
- [ ] Final summary shows correct count of installed/updated commands
