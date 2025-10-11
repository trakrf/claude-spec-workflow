# Ship Feature for Pull Request

You are tasked with completing a feature implementation and preparing it for merge.

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

2. **Pre-flight Check**
   Run /check first (programmatically):
    - If critical failures: ABORT with message
    - If warnings only: Note them but continue
    - If all green: Proceed

3. **Update Documentation**
   Check if any docs need updating:
    - README.md - new features or setup changes
    - API documentation - new endpoints
    - Configuration docs - new env vars
    - CHANGELOG.md - if it exists

4. **Clean Up Code**
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

5. **Commit Changes**
   ```bash
   # Stage all changes
   git add .
   
   # Create semantic commit
   git commit -m "feat: {feature-description}

   - {key change 1}
   - {key change 2}
   - {key change 3}
   
   Closes #{issue-number}"
   ```

6. **Update Shipped Log**
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
   - **PR**: {pending|url}
   ```

7. **Archive Feature Directory**
   ```bash
   # Remove the active feature directory
   rm -rf spec/active/{feature}/

   # Stage the removal
   git add spec/active/{feature}/
   git add spec/SHIPPED.md

   # Commit the cleanup
   git commit -m "chore: archive {feature} specs"
   ```

8. **Push Branch**
   ```bash
   # Push to remote
   git push -u origin feature/{name}
   ```

9. **Create Pull Request**
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

## Validation Before Ship
Must pass:
- All tests passing
- No type errors
- Lint clean
- Build successful
- No uncommitted changes

Can have warnings:
- Small bundle size increase
- Non-critical TODOs
- Documentation updates pending

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
❌ Cannot ship - Pre-release check failed

Critical issues found:
- {Issue 1}
- {Issue 2}

Run /check to see full report
Fix issues then try /ship again
```

## Error Handling
- If uncommitted changes: Prompt to commit or stash first
- If on main branch: Refuse to ship, must be on feature branch
- If /check fails: Show specific failures and abort
- If no specs found: Error with path tried