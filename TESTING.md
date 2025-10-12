# Testing Guide

Manual test procedures to validate Claude Spec Workflow functionality.

## Prerequisites
- Claude Code installed and running
- Git installed
- Bash shell (Git Bash on Windows, native on macOS/Linux)

## Installation Tests

### Test 1: Fresh Installation (Unix)
```bash
cd claude-spec-workflow
./install.sh
```

**Expected:**
- Commands copied to `~/.claude/commands/`
- Success message displayed
- All 5 commands listed (spec, plan, build, check, ship)

**Verify:**
```bash
ls -la ~/.claude/commands/ | grep -E "(spec|plan|build|check|ship)\.md"
```

### Test 2: Re-installation (Idempotency)
Run installation script again.

**Expected:**
- No errors
- Commands updated/overwritten
- Warning or confirmation message

### Test 3: Uninstallation
```bash
./uninstall.sh
```

**Expected:**
- All 5 commands removed
- Success message with count
- No errors if already uninstalled

## Project Initialization Tests

### Test 4: Initialize New Project
```bash
mkdir /tmp/test-project
cd /tmp/test-project
git init
~/path/to/claude-spec-workflow/init-project.sh .
```

**Expected:**
- `spec/` directory created
- `spec/active/` subdirectory exists
- `spec/SHIPPED.md` file created
- `spec/template.md` copied
- `spec/README.md` copied
- `.gitignore` updated (if exists)

**Verify:**
```bash
ls -la spec/
cat .gitignore | grep "spec/active/\*/log.md"
```

### Test 6: Initialize with Different Preset
```bash
cd test-project
~/path/to/claude-spec-workflow/init-project.sh . python-fastapi
```

**Expected:**
- `spec/stack.md` updated with Python/FastAPI preset
- Contains pytest, ruff, mypy commands
- Success message displayed
- Prompts for confirmation if files exist

**Verify:**
```bash
cat spec/stack.md | grep "pytest"
cat spec/stack.md | grep "ruff"
```

### Test 7: View Available Presets
```bash
~/path/to/claude-spec-workflow/init-project.sh . invalid-preset
```

**Expected:**
- Error message about invalid preset
- Lists all available presets:
  - typescript-react-vite
  - nextjs-app-router
  - python-fastapi
  - go-standard
  - monorepo-go-react

## Command Workflow Tests

### Test 8: /spec Command
In Claude Code:
```
/spec test-feature

[Have a brief conversation about a simple feature]
```

**Expected:**
- Claude analyzes conversation
- Generates draft specification
- Asks for confirmation
- Creates `spec/active/test-feature/spec.md`

**Verify:**
```bash
cat spec/active/test-feature/spec.md
```

### Test 9: /plan Command
```
/plan spec/active/test-feature/spec.md
```

**Expected:**
- Claude reads the spec
- Asks clarifying questions
- Generates implementation plan
- Creates `spec/active/test-feature/plan.md`
- Creates feature branch
- Commits plan

**Verify:**
```bash
cat spec/active/test-feature/plan.md
git branch | grep "feature/test-feature"
```

### Test 10: /build Command
```
/build spec/active/test-feature/
```

**Expected:**
- Loads spec and plan
- Executes tasks sequentially
- Creates `spec/active/test-feature/log.md`
- Runs validation after each change
- Updates log with progress

**Verify:**
```bash
cat spec/active/test-feature/log.md
```

### Test 11: /check Command (No Stack Config)
In a project without `spec/stack.md`:
```
/check
```

**Expected:**
- Error message: "❌ Stack not configured"
- Suggests running init-project.sh with preset
- Shows available presets
- Does not proceed without stack.md

### Test 12: /check Command (With Stack Config)
In a project with `spec/stack.md`:
```
/check
```

**Expected:**
- Reads stack.md for validation commands
- Runs lint, typecheck, test, build commands
- Shows comprehensive validation report
- Indicates PR readiness status

### Test 13: /ship Command
```
/ship spec/active/test-feature/
```

**Expected:**
- Runs `/check` first
- Updates `spec/SHIPPED.md`
- Archives feature directory
- Commits changes
- Pushes to remote
- Creates pull request (or provides instructions)

**Verify:**
```bash
cat spec/SHIPPED.md
ls spec/active/ | grep test-feature  # Should NOT exist
git log -1
```

## Edge Case Tests

### Test 14: Missing spec/ Directory
Run `/plan` in project without spec/ directory.

**Expected:**
- Clear error message
- Suggests running init-project.sh
- Provides correct path

### Test 15: Invalid Spec Path
```
/plan spec/active/nonexistent/spec.md
```

**Expected:**
- Error: spec file not found
- Shows path that was tried
- Suggests checking path

### Test 16: Out-of-Order Commands
Try `/build` before `/plan`.

**Expected:**
- Error or warning about missing plan
- Suggests running /plan first

### Test 17: Workspace Detection (Monorepo)
In monorepo with workspace in spec metadata:
```
/build spec/active/backend-feature/
```

**Expected:**
- Detects "backend" workspace from metadata
- Uses backend-specific validation commands
- Reports workspace being used

## Cross-Platform Tests

### Test 18: Windows Path Handling
On Windows (Git Bash), test with forward slashes:
```
/plan spec/active/test-feature/spec.md
```

**Expected:**
- Commands work correctly in Git Bash
- Forward slashes handled properly

### Test 19: Symlink Handling (Unix)
```bash
ln -s ~/claude-spec-workflow/install.sh ~/test-symlink.sh
~/test-symlink.sh
```

**Expected:**
- Installation works correctly
- Scripts find their directory despite symlink

## Performance Tests

### Test 20: Large Specification
Create spec with 20+ requirements and complex architecture.

**Expected:**
- `/plan` generates comprehensive plan
- Handles large context without issues
- All tasks properly numbered

### Test 21: Long-Running Build
Create feature requiring 10+ file changes.

**Expected:**
- Progress log updated incrementally
- Validation runs after each change
- Can resume if interrupted

## Validation Tests

### Test 22: Preset Configuration Accuracy
For each preset, verify commands are correct:

```bash
# Test TypeScript preset
cd typescript-react-project
~/path/to/claude-spec-workflow/init-project.sh . typescript-react-vite
npm run lint  # Should work
npm run typecheck  # Should work
npm test  # Should work
```

Repeat for all presets with appropriate projects.

### Test 23: Monorepo Configuration
```bash
cd monorepo-project
~/path/to/claude-spec-workflow/init-project.sh . monorepo-go-react
```

**Verify:**
- `spec/stack.md` created with monorepo format
- All three workspaces defined (database, backend, frontend)
- Each workspace has validation commands
- Workspace sections use `## Workspace: [name]` headers

## Regression Tests

### Test 24: Existing Features Still Work
After any changes, verify:
- All installation scripts work
- All commands execute
- Documentation is accurate
- Examples are valid

## Test Checklist Summary

- [ ] Unix installation works
- [ ] Windows installation works
- [ ] Uninstallation works
- [ ] Project initialization works
- [ ] Stack configuration works
- [ ] All 5 commands execute successfully
- [ ] Error handling is clear
- [ ] Cross-platform compatibility verified
- [ ] Presets are accurate
- [ ] Documentation matches behavior

## Reporting Issues

If any test fails:
1. Note the test number and name
2. Record exact error message
3. Include OS and shell version
4. Attach relevant logs
5. Open issue at https://github.com/trakrf/claude-spec-workflow/issues
