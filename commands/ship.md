# Ship Feature for Pull Request

You are tasked with completing a feature implementation and preparing it for merge.

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

1. **Load Configuration**
    - Check for `spec/config.md` in project root
    - **Detect project type**:
      - **Monorepo**: If `spec/config.md` contains a `workspaces:` section
      - **Single-stack**: If `spec/config.md` has flat config (e.g., `lint:`, `test:`)
      - **No config**: Use sensible defaults
    - **Detect workspace** (monorepo only):
      - Read `Workspace:` from spec.md metadata
      - Detect from file paths in plan.md
    - Identify which validation commands to use

2. **Pre-flight Validation Gate Check**
   Run /check first (programmatically):

   **BLOCKING GATES** (MUST pass - cannot ship otherwise):
    - If lint errors: ABORT with "❌ BLOCKING: Fix lint errors first"
    - If type errors: ABORT with "❌ BLOCKING: Fix type errors first"
    - If test failures: ABORT with "❌ BLOCKING: Fix failing tests first"
    - If build failures: ABORT with "❌ BLOCKING: Fix build errors first"

   **QUALITY WARNINGS** (can proceed, but should address):
    - If console.log found: WARN with "⚠️  WARNING: Consider removing console.logs"
    - If TODOs found: WARN with "⚠️  WARNING: Consider addressing TODOs"
    - If skipped tests: WARN with "⚠️  WARNING: Consider enabling skipped tests"
    - If bundle size high: WARN with "⚠️  WARNING: Consider optimizing bundle size"

   **Only proceed if ALL BLOCKING GATES pass.**

3. **ULTRATHINK: Final Coherence and Completeness Check**

   **CRITICAL**: Before finalizing, think deeply about the overall feature.

   **You've now completed**:
   - All implementation tasks from plan
   - All validation gates passed
   - Code cleanup done

   **Spend time analyzing**:
   - Does this implementation actually solve the original problem from the spec?
   - Are all success metrics from spec.md achievable with this code?
   - What documentation needs updating beyond code comments?
   - Are there any rough edges that will confuse users?
   - What would make a reviewer question this PR?
   - Is there anything that works but feels "wrong"?

   **Ask yourself**:
   - If I deployed this to production right now, what would break?
   - What obvious questions will reviewers ask? Can I address them proactively?
   - Are there any TODOs that should be fixed before shipping vs after?
   - Does the commit message accurately reflect what changed?
   - Will the success metrics I'm claiming actually be true?
   - Is there any "clever" code that needs explanation?

   **Think about documentation**:
   - README changes - are they clear for new users?
   - API documentation - are new endpoints/functions documented?
   - Migration guide - does anything break existing usage?
   - Configuration - are new env vars or settings documented?

   **Think about the PR**:
   - What's the story I'm telling in the PR description?
   - What context from the spec should I include?
   - What testing did I do that gives me confidence?
   - What areas might need extra scrutiny from reviewers?

   **Red flags to check**:
   - ❌ Success metrics in spec can't actually be measured - need to revise claims
   - ❌ Breaking changes not documented - will surprise users
   - ❌ "It works on my machine" - did I test the full workflow?
   - ❌ Commit message is vague - reviewers won't understand intent
   - ❌ TODO comments for core functionality - should finish before shipping
   - ❌ Feels rushed or incomplete - take time to polish

   **Output from this step**: Confidence that this feature is production-ready and the PR tells a clear story.

4. **Update Documentation**
   Check if any docs need updating:
    - README.md - new features or setup changes
    - API documentation - new endpoints
    - Configuration docs - new env vars
    - CHANGELOG.md - if it exists

5. **Clean Up Code**
   If /check found minor issues, use config-specific commands:

   **For monorepo:**
   ```bash
   # Use workspace-specific lint fix
   {config.workspaces.{workspace}.validation.lint.autofix}
   ```

   **For single-stack project:**
   ```bash
   # Use project lint fix
   {config.lint.autofix}
   ```

   **Or defaults:**
   ```bash
   # Remove console.logs (TypeScript)
   find src -name "*.ts" -o -name "*.tsx" | xargs sed -i '/console\.log/d'

   # Final lint with fix
   pnpm lint --fix
   ```

6. **Commit Changes**

   Use **Conventional Commits** format for semantic versioning:

   **Format**: `<type>(<scope>): <description>`

   **Types**:
   - `feat:` - New feature (triggers MINOR version bump)
   - `fix:` - Bug fix (triggers PATCH version bump)
   - `docs:` - Documentation only
   - `refactor:` - Code change that neither fixes a bug nor adds a feature
   - `perf:` - Performance improvement
   - `test:` - Adding or fixing tests
   - `chore:` - Maintenance tasks, deps updates

   **Breaking changes**: Add `!` after type (triggers MAJOR version bump)
   - Example: `feat!: redesign authentication API`

   **Examples**:
   ```bash
   # New feature (most common)
   git commit -m "feat(auth): add JWT token refresh mechanism

   - Implement refresh token endpoint
   - Add token rotation logic
   - Update auth middleware to handle refresh

   Closes #123"

   # Bug fix
   git commit -m "fix(validation): prevent empty form submission

   - Add client-side validation for required fields
   - Add server-side validation fallback
   - Display error messages to user

   Fixes #456"

   # Breaking change
   git commit -m "feat(api)!: redesign user profile endpoint

   BREAKING CHANGE: /api/user response format changed from flat object to nested structure

   - Nested address fields under 'address' object
   - Phone numbers now array instead of single string
   - Migration guide in docs/migrations/v2.md

   Closes #789"

   # Documentation
   git commit -m "docs(readme): add installation instructions for Windows"

   # Refactor
   git commit -m "refactor(store): simplify user state management

   - Remove redundant state fields
   - Consolidate user actions
   - No behavior changes"
   ```

   **Commit your changes**:
   ```bash
   # Stage all changes
   git add .

   # Create conventional commit
   git commit -m "{type}({scope}): {description}

   - {key change 1}
   - {key change 2}
   - {key change 3}

   Closes #{issue-number}"
   ```

7. **Update Shipped Log**
   Create/append to `spec/SHIPPED.md`:
   ```markdown
   ## {Feature Name}
   - **Date**: {YYYY-MM-DD}
   - **Branch**: feature/{name}
   - **Commit**: {git rev-parse HEAD}
   - **Summary**: {one-line description}
   - **Key Changes**:
     - {major change 1}
     - {major change 2}
   - **Validation**: ✅ All checks passed

   ### Success Metrics
   (Copy from spec.md and mark actual results)
   - ✅ {Metric 1} - **Result**: {actual outcome}
   - ✅ {Metric 2} - **Result**: {actual outcome}
   - ⏳ {Metric 3} - **Result**: To be measured in production
   - ❌ {Metric 4} - **Result**: Did not meet target, needs follow-up

   **Overall Success**: {percentage}% of metrics achieved

   - **PR**: {pending|url}
   ```

8. **Archive Feature Directory**
   ```bash
   # Remove the active feature directory
   rm -rf spec/active/{feature}/

   # Stage the removal
   git add spec/active/{feature}/
   git add spec/SHIPPED.md

   # Commit the cleanup
   git commit -m "chore: archive {feature} specs"
   ```

9. **Push Branch**
   ```bash
   # Push to remote
   git push -u origin feature/{name}
   ```

10. **Create Pull Request**
   Either:
   a. Use GitHub CLI if available:
   ```bash
   gh pr create \
     --title "feat: {feature-description}" \
     --body "## Summary
     {description}
     
     ## Changes
     - {change 1}
     - {change 2}
     
     ## Validation
     - ✅ All tests passing
     - ✅ Lint clean
     - ✅ Build successful
     
     ## Related
     - Implements #{issue}
     - Spec: Archived in commit {hash}"
   ```

   b. Or provide manual instructions:
   ```markdown
   ## Ready to Create PR
   
   1. Visit: https://github.com/{owner}/{repo}/compare/feature/{name}
   2. Title: "feat: {feature-description}"
   3. Description: {template provided}
   4. Request review from: {team/person}
   ```

## Validation Gates Before Ship

**BLOCKING GATES** (Must pass - cannot ship):
- ❌ All tests passing
- ❌ No type errors
- ❌ Lint clean
- ❌ Build successful
- ❌ No uncommitted changes

**QUALITY WARNINGS** (Can have, should address):
- ⚠️  Small bundle size increase
- ⚠️  Non-critical TODOs
- ⚠️  Documentation updates pending
- ⚠️  console.log statements

If any blocking gate fails, you MUST fix before shipping.

## Output Format

Success case:
```
🚀 Feature Shipped Successfully!

📦 Archive Summary:
- Spec archived in commit: {hash}
- Entry added to SHIPPED.md
- Feature directory cleaned

🌿 Git Status:
- Branch: feature/{name}
- Commits: {N} ahead of main
- Pushed to origin

🔗 Pull Request:
{Either PR URL or instructions}

✅ Ready for code review!
```

Failure case:
```
❌ Cannot ship - BLOCKING GATES failed

BLOCKING issues found:
- {Issue 1 - e.g., "5 type errors in src/components/"}
- {Issue 2 - e.g., "3 test failures in auth.test.ts"}

These are MANDATORY gates that block shipping:
✅ Lint must be clean
✅ Types must be correct
✅ Tests must pass
✅ Build must succeed

Run /check to see full report
Fix all BLOCKING issues then try /ship again
```

## Error Handling
- If uncommitted changes: Prompt to commit or stash first
- If on main branch: Refuse to ship, must be on feature branch
- If /check BLOCKING GATES fail: Show specific failures and ABORT (cannot ship)
- If /check has warnings only: Show warnings but allow shipping
- If no specs found: Error with path tried

**Remember**: BLOCKING GATES are not negotiable. Fix them before shipping.