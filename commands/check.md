# Pre-Release Validation Check

## Persona: Senior Test Engineer

**Adopt this mindset**: You are a thorough test engineer who assesses production readiness. Your strength is **risk assessment** and quality gates. You don't just run tests - you interpret results, prioritize issues, and provide actionable guidance. You know the difference between blocking issues and acceptable warnings.

**Your focus**:
- Comprehensive validation across all quality dimensions
- Assessing real risk, not just tool output
- Prioritizing issues (BLOCKING → HIGH → MEDIUM → LOW)
- Providing specific, actionable fixes

---

You are tasked with comprehensively validating that the codebase is ready for a pull request.

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
Optional: Workspace name for monorepo projects (e.g., `/check frontend`, `/check backend`)
- If no argument provided: validates entire codebase (all workspaces in monorepo)
- If workspace provided: validates only that specific workspace

## Process

1. **Load Project Configuration**
    - **Read `spec/stack.md`** for validation commands (required)
    - **Detect project type**:
      - **Monorepo**: If `spec/stack.md` contains `## Workspace:` sections
      - **Single-stack**: If `spec/stack.md` has only top-level commands
    - **Handle workspace argument** (if provided):
      - If monorepo and workspace specified, validate only that workspace
      - If not monorepo and workspace provided, warn that argument is ignored
      - If workspace invalid, list available workspaces from spec/stack.md

    If `spec/stack.md` not found, show error and stop:
    ```
    ❌ Stack not configured

    This workflow requires stack configuration. Run:
      /path/to/claude-spec-workflow/init-project.sh . [preset]

    This creates spec/stack.md with validation commands.
    Available presets: typescript-react-vite, python-fastapi, go-standard, monorepo-go-react

    Cannot proceed without spec/stack.md.
    ```

2. **Run Comprehensive Validation Suite**

   **Read commands from `spec/stack.md`:**

   **For Monorepo** (if spec/stack.md has `## Workspace:` sections):

   If workspace argument provided, validate only that workspace.
   Otherwise, validate each workspace in order listed:

   ```bash
   # For each workspace section in spec/stack.md
   echo "=== Validating Workspace: {workspace} ==="

   # Run commands from that workspace's section:
   # - Lint
   # - Typecheck (if present)
   # - Test
   # - Build (if present)

   # Track results per workspace
   ```

   Report aggregate results:
   ```
   Workspace Results:
   - database: ✅ All checks passed
   - backend: ✅ All checks passed
   - frontend: ⚠️  2 warnings (debug statements found)

   Overall: READY WITH WARNINGS
   ```

   **For Single-Stack** (if spec/stack.md has only top-level commands):

   ```bash
   echo "=== Linting ==="
   # Run Lint command from spec/stack.md
   LINT_STATUS=$?

   echo "=== Type Checking ==="
   # Run Typecheck command from spec/stack.md (if present)
   TYPE_STATUS=$?

   echo "=== Unit Tests ==="
   # Run Test command from spec/stack.md
   TEST_STATUS=$?

   echo "=== Build ==="
   # Run Build command from spec/stack.md
   BUILD_STATUS=$?

   echo "=== E2E Tests ==="
   # Run E2E command from spec/stack.md (if present)
   E2E_STATUS=$?
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

   **Stack-aware defaults:**

   **Node/TypeScript**:
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

   **Rust**:
   ```bash
   # Debug print statements
   grep -r "println!\|dbg!\|eprintln!" src/ --exclude="*test*" | grep -v "// OK:"

   # TODO comments
   grep -r "TODO\|FIXME\|XXX" src/

   # Skipped/ignored tests
   grep -r "#\[ignore\]" src/

   # Commented out code
   grep -r "^[[:space:]]*//.*fn \|//.*let \|//.*struct " src/
   ```

   **Go**:
   ```bash
   # Debug print statements
   grep -r "fmt\.Println\|log\.Println" . --include="*.go" --exclude="*_test.go"

   # TODO comments
   grep -r "TODO\|FIXME\|XXX" . --include="*.go"

   # Skipped tests
   grep -r "t\.Skip" . --include="*_test.go"

   # Commented out code
   grep -r "^[[:space:]]*//.*func \|//.*var \|//.*type " . --include="*.go"
   ```

   **Python**:
   ```bash
   # Debug print statements
   grep -r "print(" . --include="*.py" --exclude="*test*" | grep -v "# OK:"

   # TODO comments
   grep -r "TODO\|FIXME\|XXX" . --include="*.py"

   # Skipped tests
   grep -r "@pytest\.mark\.skip\|@unittest\.skip" . --include="*test*.py"

   # Commented out code
   grep -r "^[[:space:]]*#.*def \|#.*class " . --include="*.py"
   ```

3. **Bundle Size Analysis** (Node/TypeScript projects only)
   ```bash
   # Only for projects with dist/build output
   if [ -d "dist" ] || [ -d "build" ]; then
     # Get current bundle size
     BUNDLE_SIZE=$(du -sk dist/assets/*.js 2>/dev/null || du -sk build/static/*.js 2>/dev/null | awk '{sum += $1} END {print sum}')

     # Check against threshold (e.g., 500KB)
     if [ -n "$BUNDLE_SIZE" ] && [ $BUNDLE_SIZE -gt 500 ]; then
       echo "⚠️  Bundle size: ${BUNDLE_SIZE}KB exceeds threshold"
     fi
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

5. **Security Audit** (stack-aware)

   **Node/TypeScript**:
   ```bash
   if command -v pnpm &> /dev/null; then
     pnpm audit
   elif command -v npm &> /dev/null; then
     npm audit
   elif command -v yarn &> /dev/null; then
     yarn audit
   fi
   ```

   **Rust**:
   ```bash
   if command -v cargo-audit &> /dev/null; then
     cargo audit
   else
     echo "ℹ️  Install cargo-audit for security scanning: cargo install cargo-audit"
   fi
   ```

   **Go**:
   ```bash
   if command -v gosec &> /dev/null; then
     gosec ./...
   else
     echo "ℹ️  Install gosec for security scanning: go install github.com/securego/gosec/v2/cmd/gosec@latest"
   fi
   ```

   **Python**:
   ```bash
   if command -v safety &> /dev/null; then
     safety check
   elif command -v pip-audit &> /dev/null; then
     pip-audit
   else
     echo "ℹ️  Install pip-audit for security scanning: pip install pip-audit"
   fi
   ```

6. **ULTRATHINK: Interpret Results and Provide Guidance**

   **CRITICAL**: Before generating the report, think about what the results mean.

   **You now have**:
   - Validation results (lint, types, tests, build, e2e, security)
   - Code quality metrics (console.log, TODOs, skipped tests)
   - Bundle size analysis
   - Git status
   - Divergence from main

   **Spend time analyzing**:
   - What is the REAL severity of each issue?
   - Are there patterns in the failures (e.g., all in one file)?
   - Which issues are quick fixes vs significant work?
   - What would a reviewer notice immediately?
   - Are quality warnings masking deeper issues?
   - Is the bundle size increase justified?

   **Ask yourself**:
   - If this PR landed in production, what's the actual risk?
   - Are test failures in new code or existing code?
   - Do type errors indicate a design problem?
   - Are console.logs debugging artifacts or intentional logging?
   - Which warnings should absolutely be fixed vs can wait?
   - Is there a "smell" suggesting something deeper is wrong?

   **Think about the report**:
   - What's the one-sentence summary of readiness?
   - What specific actions would make this PR ready?
   - Should I recommend splitting this PR if it's too big?
   - What context helps the developer fix issues quickly?

   **Prioritize issues**:
   - **BLOCKING**: Must fix before ship (security, test failures, build breaks)
   - **HIGH**: Should fix before ship (type errors, critical TODOs)
   - **MEDIUM**: Consider fixing (code quality, warnings)
   - **LOW**: Nice to have (minor optimizations, info-level issues)

   **Output from this step**: Clear understanding of:
   - Overall PR readiness (READY/NOT READY/READY WITH WARNINGS)
   - Specific actionable fixes needed
   - Priority order for addressing issues
   - Context that helps developer fix issues quickly

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

## VALIDATION GATE ENFORCEMENT

**CRITICAL - BLOCKING GATES**:
These MUST pass before merge - they are not negotiable:
- ❌ Lint errors → BLOCKING (cannot ship)
- ❌ Type errors → BLOCKING (cannot ship)
- ❌ Test failures → BLOCKING (cannot ship)
- ❌ Build failures → BLOCKING (cannot ship)

**QUALITY WARNINGS**:
These should be addressed but don't block merge:
- ⚠️  console.log statements → WARNING (should fix)
- ⚠️  TODO comments → WARNING (should address)
- ⚠️  Skipped tests → WARNING (should enable)
- ⚠️  Bundle size increase → WARNING (should optimize)

**DECISION RULE**:
- ANY blocking gate fails → Status: **NOT READY** (cannot ship until fixed)
- All gates pass + warnings → Status: **READY WITH WARNINGS** (can ship, should fix)
- All gates pass + no warnings → Status: **READY** (ship it!)

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
