# Implementation Plan: Robust Pull Request Creation
Generated: 2025-10-12
Specification: spec.md

## Understanding

The `/ship` command currently has two critical issues:
1. **Silent auth failure**: Falls back to manual PR creation without explaining why automation failed
2. **Poor formatting**: PR details display without line breaks, running together

The solution is to make `/ship` robust with multi-method authentication and clear formatting:
- Try multiple auth methods (gh CLI → GH_TOKEN → gh config) with clear feedback
- Display PR information with proper line breaks
- Only fall back to manual instructions after exhausting all options
- Provide actionable error messages explaining what failed and how to fix it

**Key Architectural Decision**: Use guidance-based approach in ship.md rather than embedding full bash implementation. This minimizes token usage and allows Claude Code to adapt implementation to actual user environment.

## Relevant Files

**Files to Modify**:
- `commands/ship.md` (~line 265-296) - Replace PR creation section with multi-method auth guidance
- `commands/ship.md` (~line 331-332) - Fix PR display formatting (already updated, verify)
- `README.md` (~line 40-52) - Add GitHub authentication prerequisites section

**Reference Patterns** (existing code to follow):
- `commands/ship.md` (lines 265-296) - Current gh pr create section shows pattern for command guidance
- `commands/ship.md` (lines 331-335) - PR display format shows output formatting pattern (already fixed)
- `README.md` (lines 40-52) - Prerequisites section shows format for setup instructions

## Architecture Impact

- **Subsystems affected**: Commands (ship.md), Documentation (README.md)
- **New dependencies**: None (uses existing: gh CLI optional, curl, git, grep, sed)
- **Breaking changes**: None - improves existing /ship behavior, no API changes
- **User-facing changes**: Better PR creation success rate, clearer error messages

## Task Breakdown

### Task 1: Update ship.md with multi-method PR creation guidance
**File**: commands/ship.md
**Action**: MODIFY (lines ~265-296)
**Pattern**: Reference existing command guidance style in ship.md

**Implementation**:
Replace the current "Create Pull Request" section with clear guidance for trying multiple auth methods:

```markdown
9. **Create Pull Request**

   Try authentication methods in order until one succeeds:

   **Method 1: GitHub CLI (if available)**
   - Check if gh CLI is installed: `command -v gh`
   - Check if authenticated: `gh auth status`
   - If both true, create PR: `gh pr create --title "..." --body "..."`
   - Capture PR URL from output
   - If successful: Update SHIPPED.md, display success, exit

   **Method 2: GH_TOKEN environment variable**
   - Check if GH_TOKEN is set: `[ -n "$GH_TOKEN" ]`
   - Extract repo info: `git remote get-url origin`
   - Parse owner/repo from URL
   - Get base branch: `git remote show origin | grep 'HEAD branch'`
   - Call GitHub API with curl:
     ```bash
     curl -s -X POST \
       -H "Authorization: token $GH_TOKEN" \
       -H "Accept: application/vnd.github.v3+json" \
       "https://api.github.com/repos/$owner/$repo/pulls" \
       -d '{"title":"...","body":"...","head":"branch","base":"main"}'
     ```
   - Parse html_url from JSON response
   - If successful: Update SHIPPED.md, display success, exit

   **Method 3: gh config file**
   - Check if ~/.config/gh/hosts.yml exists
   - Extract oauth_token: `grep -A 2 'github.com:' ~/.config/gh/hosts.yml | grep 'oauth_token:' | awk '{print $2}'`
   - If token found, use same curl approach as Method 2
   - If successful: Update SHIPPED.md, display success, exit

   **Method 4: Manual fallback (last resort)**
   - Show clear error message listing all methods tried:
     ```
     ❌ Cannot create PR automatically

     Tried:
       ❌ gh CLI: [specific reason - not installed/not authenticated]
       ❌ GH_TOKEN: environment variable not set
       ❌ gh config: no token found

     Please authenticate with GitHub:

     Option 1 (Recommended): GitHub CLI
       gh auth login

     Option 2: Personal Access Token
       export GH_TOKEN=your_token_here
       # Get token: https://github.com/settings/tokens
       # Scopes needed: repo, workflow

     After authenticating, re-run:
       /ship spec/active/feature-name/

     Or create PR manually:
       https://github.com/owner/repo/compare/branch-name
     ```
   - Leave SHIPPED.md with "PR: pending"

   **Success output format** (when PR created):
   ```
   ✅ Found: [method that worked - e.g., "GitHub CLI authenticated"]
   🚀 Creating pull request...

   🔗 Pull Request:

     PR #42: https://github.com/user/repo/pull/42
     Title: feat: feature description
     State: OPEN

   📦 Updated SHIPPED.md with PR URL
   ```

   **Key principles**:
   - Show what you're trying at each step (transparency)
   - Clear success/failure for each method
   - Actionable error messages (tell user exactly how to fix)
   - Only try next method if current one fails
   - Update SHIPPED.md immediately upon success
```

**Validation**:
```bash
# Verify ship.md syntax
bash -n commands/ship.md 2>&1 || echo "No bash syntax to check (markdown file)"

# Check file was modified
git diff commands/ship.md | grep -q "Method 1: GitHub CLI"
```

### Task 2: Verify PR display formatting fix
**File**: commands/ship.md
**Action**: VERIFY (lines 331-335)
**Pattern**: Already updated in previous fix

**Implementation**:
Read lines 331-335 and confirm the format shows:
```
🔗 Pull Request:

  PR #{number}: {url}
  Title: {title}
  State: {state}
```

**Validation**:
```bash
# Verify proper formatting exists
grep -A 4 "🔗 Pull Request:" commands/ship.md | grep -q "PR #"
```

### Task 3: Add GitHub authentication section to README.md Prerequisites
**File**: README.md
**Action**: MODIFY (after line 52, in Prerequisites section)
**Pattern**: Follow existing Prerequisites formatting in README.md lines 40-52

**Implementation**:
Add new subsection after line 52 (after "Why bash?" paragraph):

```markdown
**GitHub Authentication (for automatic PR creation):**

The `/ship` command can create pull requests automatically if you authenticate with GitHub using any of these methods:

1. **GitHub CLI** (Recommended):
   ```bash
   gh auth login
   ```

2. **Personal Access Token**:
   ```bash
   export GH_TOKEN=your_token_here
   # Get token: https://github.com/settings/tokens
   # Scopes needed: repo, workflow
   ```

3. **gh config**: If gh CLI is installed, `/ship` will use stored credentials automatically

**Without authentication**: `/ship` will provide manual PR creation instructions.
```

**Validation**:
```bash
# Verify addition
grep -q "GitHub Authentication" README.md
grep -q "gh auth login" README.md
```

### Task 4: Add PR creation troubleshooting section to README.md
**File**: README.md
**Action**: MODIFY (in Troubleshooting section, after line 473)
**Pattern**: Follow existing troubleshooting section format

**Implementation**:
Add new subsection after "Cross-Platform Issues":

```markdown
### PR Creation Issues

**`/ship` doesn't create PR automatically**

The `/ship` command tries multiple authentication methods in order:
1. GitHub CLI (if authenticated)
2. GH_TOKEN environment variable
3. Token from gh config

If all fail, you'll get manual PR creation instructions.

**To fix**:
```bash
# Option 1: Use GitHub CLI
gh auth login

# Option 2: Set GH_TOKEN
export GH_TOKEN=your_token_here
# Add to ~/.bashrc or ~/.zshrc for persistence

# Then re-run
/ship spec/active/your-feature/
```

**After creating PR manually**:
Update SHIPPED.md:
```bash
# Find "PR: pending" in spec/SHIPPED.md and replace with actual URL
sed -i 's|PR: pending|PR: https://github.com/owner/repo/pull/123|' spec/SHIPPED.md
git add spec/SHIPPED.md
git commit -m "docs: update SHIPPED.md with PR URL"
git push
```
```

**Validation**:
```bash
# Verify troubleshooting section added
grep -q "PR Creation Issues" README.md
```

### Task 5: Test multi-method PR creation guidance with gh CLI
**File**: N/A (manual testing)
**Action**: VERIFY implementation
**Pattern**: Test actual /ship workflow

**Implementation**:
1. Ensure gh CLI is authenticated: `gh auth status`
2. Create a test branch with changes
3. Run `/ship spec/active/robust-pr-creation/`
4. Verify Claude Code:
   - Detects gh CLI authentication
   - Shows "✅ Found: GitHub CLI authenticated"
   - Creates PR successfully
   - Updates SHIPPED.md with PR URL
   - Displays PR details with proper formatting

**Expected output**:
```
✅ Found: GitHub CLI authenticated
🚀 Creating pull request...

🔗 Pull Request:

  PR #X: https://github.com/trakrf/claude-spec-workflow/pull/X
  Title: feat: add robust PR creation to /ship command
  State: OPEN

📦 Updated SHIPPED.md with PR URL
```

**Validation**:
```bash
# Check PR was created
gh pr list | grep "robust PR creation"

# Check SHIPPED.md was updated
grep -v "PR: pending" spec/SHIPPED.md | grep -q "PR: https://"
```

### Task 6: Test fallback behavior with no authentication
**File**: N/A (manual testing)
**Action**: VERIFY error handling
**Pattern**: Test error path

**Implementation**:
1. Temporarily disable gh authentication: `gh auth logout` or rename gh config
2. Unset GH_TOKEN: `unset GH_TOKEN`
3. Run `/ship` on a test branch
4. Verify Claude Code:
   - Shows "❌ Cannot create PR automatically"
   - Lists all methods tried with specific reasons
   - Provides clear authentication instructions
   - Shows manual PR creation URL
   - Leaves SHIPPED.md with "PR: pending"

**Expected output**:
```
❌ Cannot create PR automatically

Tried:
  ❌ gh CLI: not authenticated (run: gh auth login)
  ❌ GH_TOKEN: environment variable not set
  ❌ gh config: no token found

Please authenticate with GitHub:
[... instructions ...]
```

**Validation**:
```bash
# Check SHIPPED.md still shows pending
grep -q "PR: pending" spec/SHIPPED.md
```

### Task 7: Verify documentation accuracy
**File**: N/A (review pass)
**Action**: VERIFY consistency
**Pattern**: Cross-reference documentation

**Implementation**:
1. Read README.md Prerequisites section
2. Read README.md Troubleshooting section
3. Read commands/ship.md PR creation section
4. Verify:
   - All three sections describe same auth methods in same order
   - Error messages match between ship.md and README troubleshooting
   - Prerequisites accurately reflect what /ship needs
   - Examples use consistent formatting and placeholder names

**Validation**:
```bash
# Check consistency of authentication methods mentioned
grep -c "gh auth login" README.md    # Should be 2+ (Prerequisites + Troubleshooting)
grep -c "GH_TOKEN" README.md         # Should be 2+
grep -c "gh config" README.md        # Should be 2+
```

## Risk Assessment

- **Risk**: Guidance might be too vague, Claude Code could implement incorrectly
  **Mitigation**: Provide clear step-by-step guidance with actual commands, test with /ship execution

- **Risk**: GitHub API format changes could break Method 2/3
  **Mitigation**: GitHub API v3 is stable, document API version used, error handling shows response

- **Risk**: Token security - exposing tokens in error messages
  **Mitigation**: Guidance explicitly states "don't log tokens", only show success/failure not token values

- **Risk**: Users might not understand why auth failed
  **Mitigation**: Show specific reason for each method failure, provide exact fix commands

## Integration Points

- **Commands**: ship.md gets updated guidance for PR creation workflow
- **Documentation**: README.md Prerequisites and Troubleshooting get new sections
- **Validation**: Uses existing /check for shellcheck, no new validation gates needed
- **Git workflow**: No changes to branch/commit workflow, only PR creation step

## VALIDATION GATES (MANDATORY)

**CRITICAL**: These are not suggestions - they are GATES that block progress.

After EVERY code change, use commands from `spec/stack.md`:
```bash
# Gate 1: Syntax & Style
find . -name "*.sh" -not -path "*/\.*" -exec shellcheck {} +

# Gate 2: Syntax validation
for script in $(find . -name "*.sh" -not -path "*/\.*"); do
  bash -n "$script" || exit 1
done
```

**Note**: No tests or build for markdown documentation changes. Manual validation via /ship execution.

**Enforcement Rules**:
- If ANY gate fails → Fix immediately
- Re-run validation after fix
- After 3 failed attempts → Stop and ask for help

**Do not proceed to next task until current task passes all gates.**

## Validation Sequence

After each task:
```bash
# Check shell scripts if modified
find . -name "*.sh" -not -path "*/\.*" -exec shellcheck {} +

# Verify markdown formatting
grep -q "Method 1: GitHub CLI" commands/ship.md
grep -q "GitHub Authentication" README.md
grep -q "PR Creation Issues" README.md
```

Final validation:
```bash
# Full shellcheck pass
find . -name "*.sh" -not -path "*/\.*" -exec shellcheck {} +

# Test actual /ship execution (manual)
/ship spec/active/robust-pr-creation/
```

## Plan Quality Assessment

**Complexity Score**: 3/10 (LOW)
- 📁 File Impact: 0 new files, 2 modified files (ship.md, README.md)
- 🔗 Subsystems: 2 (Commands, Documentation)
- 🔢 Task Estimate: 7 subtasks
- 📦 Dependencies: 0 (uses optional gh CLI, standard curl/git)
- 🆕 Pattern Novelty: Existing patterns (command guidance + docs)

**Confidence Score**: 9/10 (HIGH)

**Confidence Factors**:
✅ Clear requirements from spec - multi-method auth with specific order
✅ Similar patterns found in codebase - ship.md command guidance style
✅ All clarifying questions answered - guidance-based approach, github.com only, no /update-pr
✅ Minimal new code - mostly documentation and guidance
✅ No external dependencies - uses standard tools
✅ Already fixed PR formatting in previous session
⚠️ Testing requires actual GitHub auth - manual verification needed

**Assessment**: This is a well-scoped documentation and guidance update with minimal risk. The hardest part (bash implementation) is delegated to Claude Code with clear guidance, minimizing context pollution.

**Estimated one-pass success probability**: 90%

**Reasoning**: The spec is extremely detailed with actual bash code examples to reference. The main modifications are documentation updates and adding structured guidance to ship.md. The complexity is low (3/10), confidence is high (9/10), and the only uncertainty is whether the guidance is clear enough for Claude Code to implement correctly - which will be validated during actual /ship execution. The architecture decision to use guidance rather than embedded code significantly reduces risk of context pollution while maintaining implementation quality.
