# Pre-Release Validation Check

You are tasked with comprehensively validating that the codebase is ready for a pull request.

## Input
Optional: Workspace name for monorepo projects (e.g., `/check frontend`, `/check backend`)
- If no argument provided: validates entire codebase (all workspaces in monorepo)
- If workspace provided: validates only that specific workspace

## Process

1. **Load Project Configuration**
    - Check for `spec/config.md` in project root
    - If exists, read validation commands from config
    - **Detect project type**:
      - **Monorepo**: If `spec/config.md` contains a `workspaces:` section
      - **Single-stack**: If `spec/config.md` has flat config (e.g., `lint:`, `test:`, `build:`)
      - **No config**: Use sensible defaults and inform user
    - **Handle workspace argument** (if provided):
      - Verify workspace exists in config
      - If monorepo and workspace is valid, set target to that workspace only
      - If not monorepo and workspace provided, warn that workspace argument is ignored
      - If workspace invalid, list available workspaces

2. **Run Comprehensive Validation Suite**

   **For Monorepo** (if config has `workspaces` section):

   If workspace argument provided, validate only that workspace.
   Otherwise, validate each workspace in the order specified by `check_order`:

   ```bash
   # For each workspace (e.g., database, backend, frontend)
   echo "=== Validating Workspace: {workspace} ==="

   # Linting
   {config.workspaces.{workspace}.validation.lint.command}

   # Type checking (if applicable)
   {config.workspaces.{workspace}.validation.typecheck.command}

   # Tests
   {config.workspaces.{workspace}.validation.test.command}

   # Build (if applicable)
   {config.workspaces.{workspace}.validation.build.command}

   # Track results per workspace
   ```

   Report aggregate results:
   ```
   Workspace Results:
   - database: ✅ All checks passed
   - backend: ✅ All checks passed
   - frontend: ⚠️  2 warnings (console.log found)

   Overall: READY WITH WARNINGS
   ```

   **For Single-Stack Project** (if `spec/config.md` exists without workspaces):
   ```bash
   # Linting
   echo "=== Linting ==="
   {config.lint.command}
   LINT_STATUS=$?

   # Type checking
   echo "=== Type Checking ==="
   {config.typecheck.command}
   TYPE_STATUS=$?

   # Unit tests
   echo "=== Unit Tests ==="
   {config.test.command}
   TEST_STATUS=$?

   # Build
   echo "=== Build ==="
   {config.build.command}
   BUILD_STATUS=$?

   # E2E tests (if configured)
   if [ -f "{config.e2e.exists_if}" ]; then
     echo "=== E2E Tests ==="
     {config.e2e.command}
     E2E_STATUS=$?
   fi
   ```

   **Otherwise, use defaults:**
   ```bash
   # Linting
   echo "=== Linting ==="
   pnpm lint
   LINT_STATUS=$?

   # Type checking
   echo "=== Type Checking ==="
   pnpm typecheck
   TYPE_STATUS=$?

   # Unit tests
   echo "=== Unit Tests ==="
   pnpm test:run
   TEST_STATUS=$?

   # Build
   echo "=== Build ==="
   pnpm build
   BUILD_STATUS=$?

   # E2E tests (if exists)
   echo "=== E2E Tests ==="
   if [ -f "playwright.config.ts" ]; then
     pnpm test:e2e
     E2E_STATUS=$?
   fi
   ```

3. **Code Quality Checks**
   Use patterns from `spec/config.md` if available, otherwise use defaults.

   **With config:**
   ```bash
   # Console/debug statements
   grep -r "{config.console_logs.pattern}" {config.source_dirs} --exclude="{config.console_logs.exclude}"

   # TODO comments
   grep -r "{config.todos.pattern}" {config.source_dirs}

   # Skipped tests
   grep -r "{config.skipped_tests.pattern}" {config.source_dirs}
   ```

   **Defaults (TypeScript/JavaScript):**
   ```bash
   # Console.log statements (except in error handlers)
   grep -r "console\.log" src/ --exclude="*.test.*" | grep -v "catch\|error"

   # TODO comments
   grep -r "TODO\|FIXME\|XXX" src/

   # Skipped tests
   grep -r "test\.skip|it\.skip|describe\.skip" src/

   # Commented out code blocks
   grep -r "^[[:space:]]*\/\*[\s\S]*?\*\/" src/
   grep -r "^[[:space:]]*\/\/" src/ | grep -E "(function|class|const|let|var|if|for|while)"
   ```

3. **Bundle Size Analysis**
   ```bash
   # Get current bundle size
   BUNDLE_SIZE=$(du -sk dist/assets/*.js | awk '{sum += $1} END {print sum}')
   
   # Check against threshold (e.g., 500KB)
   if [ $BUNDLE_SIZE -gt 500 ]; then
     echo "⚠️  Bundle size: ${BUNDLE_SIZE}KB exceeds threshold"
   fi
   ```

4. **Git Status Check**
   ```bash
   # Uncommitted changes
   git status --porcelain
   
   # Current branch
   git branch --show-current
   
   # Commits ahead of main
   git rev-list --count main..HEAD
   
   # Divergence from main
   git fetch origin main
   git rev-list --left-right --count origin/main...HEAD
   ```

5. **Security Audit**
   ```bash
   # Check for known vulnerabilities
   pnpm audit
   ```

## Generate Report

Create a formatted report:

```markdown
# Pre-Release Check Report
Generated: {timestamp}
Branch: {current-branch}

## Validation Results
| Check | Status | Details |
|-------|--------|---------|
| Lint | {✅/❌} | {errors/warnings or "Clean"} |
| TypeScript | {✅/❌} | {error count or "No errors"} |
| Unit Tests | {✅/❌} | {X passing, Y failing} |
| Build | {✅/❌} | {Success/Failed} |
| E2E Tests | {✅/❌/➖} | {Results or "Not configured"} |
| Security | {✅/⚠️} | {No issues/X vulnerabilities} |

## Code Quality
| Issue | Count | Severity |
|-------|-------|----------|
| console.log | {N} | Low |
| TODO comments | {N} | Info |
| Skipped tests | {N} | Medium |
| Bundle size | {X}KB | {OK/Warning} |

## Git Status
- Uncommitted files: {N}
- Branch: {name}
- Commits ahead: {N}
- Up to date with main: {Yes/No}

## Critical Issues
{List any blocking issues that must be fixed}

## Warnings
{List non-blocking issues that should be considered}

## PR Readiness: {READY/NOT READY/READY WITH WARNINGS}

{If not ready, provide specific steps to fix}
```

## Decision Logic
- **READY**: All validations pass, no critical issues
- **READY WITH WARNINGS**: Validations pass but quality issues exist
- **NOT READY**: Any validation fails or critical issues found

## Output Format

**For full validation (no workspace specified):**
```
🔍 Pre-Release Check Complete

{Show summary table}

📊 PR Readiness: {status}
{If not ready: "❌ {N} issues must be fixed before PR"}
{If warnings: "⚠️  {N} warnings to consider"}
{If ready: "✅ Ready to ship with /ship"}
```

**For workspace-specific validation:**
```
🔍 Workspace Check: {workspace}

{Show validation results for that workspace}

📊 Status: {PASS/FAIL/WARNINGS}
⚡ Faster feedback - full validation with /check (no args)
```
