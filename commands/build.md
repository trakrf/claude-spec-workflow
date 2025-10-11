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
    - **First: Read `spec/README.md`** for workflow philosophy and standards
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

3. **ULTRATHINK: Plan Implementation Approach**

   **CRITICAL**: Before writing any code, think deeply about the implementation strategy.

   **You now have**:
   - Full spec with requirements and success metrics
   - Detailed plan with task breakdown
   - Reference patterns from plan (file paths and line numbers)
   - Validation commands from config
   - Progress log if resuming work

   **Spend time analyzing**:
   - What is the logical sequence to implement these tasks?
   - Which tasks are foundational vs dependent?
   - What patterns from the plan should I follow exactly?
   - Where might I deviate from the plan (and why)?
   - What validation failures are most likely? How to prevent?
   - What's my rollback strategy if a task fails validation repeatedly?

   **Ask yourself**:
   - If I implement Task 1, will it be easy to validate before Task 2?
   - Are there any tasks that would be easier in a different order?
   - What existing code patterns must I match for consistency?
   - What's the minimal implementation that passes the first validation gate?
   - Where should I be conservative vs innovative?
   - What would cause validation gates to fail? How do I avoid that?

   **Think about validation strategy**:
   - After which tasks should I commit? (Every 3-5 tasks recommended)
   - What tests exist that I need to keep passing?
   - What new tests do I need to write first (TDD approach)?
   - How do I validate each task incrementally before moving on?

   **Red flags to check**:
   - ❌ Trying to do too much in one task - break it down further
   - ❌ Not clear what "done" looks like for a task - define validation
   - ❌ Skipping existing patterns from plan - follow them unless you have a reason
   - ❌ No clear rollback point if validation fails - plan incremental commits
   - ❌ Unclear how to test incrementally - risks big bang integration

   **Output from this step**: Clear mental model of:
   - Exact implementation sequence
   - Validation strategy for each task
   - Commit points for incremental progress
   - Patterns to follow from existing code

4. **Execute Tasks Sequentially**
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

5. **Create/Update Tests**
    - For new functions: Create corresponding test file
    - For modifications: Update existing tests
    - Run tests to ensure they pass

6. **Code Cleanup** (MANDATORY BEFORE COMMIT)

   **CRITICAL**: Clean all temporary development artifacts before final validation.

   **Search and remove**:
   - `console.log()`, `console.debug()`, `console.error()` (except intentional logging)
   - `debugger;` statements
   - Commented-out code blocks (unless marked with TODO/FIXME)
   - Temporary test files or debug files
   - Dead code and unused imports
   - TODO comments for completed tasks

   **Verify cleanup**:
   ```bash
   # Search for common debug patterns
   grep -r "console\\.log" {affected-files}
   grep -r "debugger" {affected-files}
   grep -r "TODO.*TEMP" {affected-files}
   ```

   **If found**: Remove them before proceeding to final validation.

7. **Full Test Suite** (BLOCKING GATE - CANNOT SKIP)

   **CRITICAL**: You MUST run the complete test suite before committing.

   **This is NOT optional**. Do not commit without running ALL tests.

   Use commands from `spec/config.md` if available:
   ```bash
   # Use project-specific commands from spec/config.md
   {config.test.command}     # MUST pass 100%
   {config.build.command}    # MUST succeed
   {config.typecheck.command} # MUST be clean
   ```

   Or defaults if no config:
   ```bash
   # Full test suite (BLOCKING - must pass 100%)
   pnpm test:run

   # Build check (BLOCKING - must succeed)
   pnpm build

   # Type check entire project (BLOCKING - must be clean)
   pnpm typecheck
   ```

   **Enforcement**:
   - ✅ 100% tests passing → Proceed to commit
   - ❌ ANY test failing → Fix immediately, re-run full suite
   - ❌ Build fails → Fix immediately, re-run full suite
   - ❌ Type errors → Fix immediately, re-run typecheck

   **Do NOT**:
   - Skip failing tests as "technical debt"
   - Commit with "tests mostly passing"
   - Rationalize that "these tests were already failing"

   **If tests fail that weren't touched by your changes**:
   - STOP and investigate
   - You may have broken something indirectly
   - Fix the issue or ask for help

8. **Summary Report**
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
