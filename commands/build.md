# Execute Implementation Plan

You are tasked with implementing a feature based on the generated plan, with continuous validation and progress tracking.

---
**⚠️  VALIDATION GATES ARE MANDATORY**

This workflow enforces validation gates - not suggestions, but GATES:
- Lint must be clean
- Types must be correct
- Tests must pass
- Build must succeed

If any gate fails: Fix → Re-run → Repeat until pass

Do NOT treat validation as optional. These are blocking requirements.
---

## Input
The user will provide the path to a feature directory (e.g., `spec/active/auth/`).

## Process

1. **Load Context**
    - Read `spec.md` for requirements
    - Read `plan.md` for implementation strategy
    - Read `log.md` if it exists (resuming work)
    - Note current task number from log
    - **Check for `spec/config.md`** - If it exists, read it for project-specific commands
    - **Detect project type**:
      - **Monorepo**: If `spec/config.md` contains a `workspaces:` section
      - **Single-stack**: If `spec/config.md` has flat config (e.g., `lint:`, `test:`)
      - **No config**: Use sensible defaults
    - **Detect workspace** (monorepo only):
      - Check for explicit `Workspace: backend` in spec.md metadata
      - Look at file paths mentioned in plan.md (e.g., `backend/internal/`)
      - User can override with `--workspace=backend` flag

2. **Initialize Progress Log**
   Create/append to `spec/active/{feature}/log.md`:
   ```markdown
   # Build Log: {Feature Name}
   
   ## Session: {timestamp}
   Starting task: {N}
   Total tasks: {total}
   ```

3. **Execute Tasks Sequentially**
   For each task in plan.md:

   a. **Log Task Start**
   ```markdown
   ### Task {N}: {Task Name}
   Started: {timestamp}
   File: {path}
   ```

   b. **Implement Code**
    - Follow the pattern identified in plan
    - Write actual code (not pseudocode)
    - Include error handling
    - Add appropriate comments

   c. **Validate Immediately**

   **For monorepo**, use workspace-specific commands:
   ```bash
   # Use commands from spec/config.md workspaces.{workspace}.validation
   {config.workspaces.backend.validation.lint.autofix}
   {config.workspaces.backend.validation.typecheck.command}
   {config.workspaces.backend.validation.test.pattern}
   ```

   **For single-stack projects**, use project commands:
   ```bash
   # Use commands from spec/config.md
   {config.lint.autofix}
   {config.typecheck.command}
   {config.test.pattern}
   ```

   **Otherwise**, use defaults:
   ```bash
   # Syntax check
   pnpm lint {file} --fix

   # Type check
   pnpm typecheck

   # Run relevant tests
   pnpm test {test-pattern}
   ```

   d. **Handle Validation Results** (STRICT ENFORCEMENT)
    - ✅ Pass: Log success, continue to next task
    - ❌ Fail: MUST fix immediately, re-run validation
    - 🔄 Loop: Re-run until ALL gates pass
    - 🛑 After 3 failed attempts: STOP - Log blocker, ask for help

    **Remember**: Validation gates are BLOCKING. Cannot proceed until all pass.

   e. **Update Log**
   ```markdown
   Status: ✅ Complete | ❌ Failed | ⚠️ Partial
   Validation: {results}
   Issues: {any problems encountered}
   Completed: {timestamp}
   ```

4. **Create/Update Tests**
    - For new functions: Create corresponding test file
    - For modifications: Update existing tests
    - Run tests to ensure they pass

5. **Final Validation**
   After all tasks, use commands from `spec/config.md` if available:
   ```bash
   # Use project-specific commands from spec/config.md
   {config.test.command}
   {config.build.command}
   {config.typecheck.command}
   ```

   Or defaults if no config:
   ```bash
   # Full test suite
   pnpm test:run

   # Build check
   pnpm build

   # Type check entire project
   pnpm typecheck
   ```

6. **Summary Report**
   Append to log.md:
   ```markdown
   ## Summary
   Total tasks: {N}
   Completed: {X}
   Failed: {Y}
   Duration: {time}
   
   Ready for /check: {YES/NO}
   ```

## VALIDATION GATES (MANDATORY - NOT OPTIONAL)

**CRITICAL ENFORCEMENT RULES**:

🚫 **NEVER** skip validation to "save time"
🚫 **NEVER** proceed if validation fails
🚫 **NEVER** commit code that doesn't pass gates

✅ **ALWAYS** run validation after EVERY file change
✅ **ALWAYS** fix failures before proceeding
✅ **ALWAYS** re-run until ALL gates pass
✅ **ALWAYS** log all validation attempts and results

**Failure Handling**:
- 1st failure: Fix and retry immediately
- 2nd failure: Analyze error pattern, fix and retry
- 3rd failure: STOP - Log blocker and ask for help

These gates protect code quality. Treat them as mandatory, not suggestions.

## Error Recovery
- On lint errors: Use --fix flag first
- On type errors: Read error carefully, fix types
- On test failures: Understand why, fix code (not test)
- On build errors: Check for circular dependencies

## Progress Tracking
The log.md file should be detailed enough that another session can resume work by reading:
- What was completed
- What failed and why
- What's left to do
- Any open questions/blockers

## Output Format
After each task:
```
📝 Task {N}/{total}: {name}
✅ Implementation complete
✅ Validation passed
💾 Progress saved to log.md
```

Final report:
```
🏗️ Build Summary for {feature}
✅ Tasks completed: {X}/{N}
⚠️  Issues encountered: {count}
📋 Next: Run /check for pre-release validation
```
