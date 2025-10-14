# Feature: Robust Pull Request Creation

## Origin
Discovered during dogfooding: `/ship` command silently falls back to manual PR creation when GitHub CLI is not authenticated, breaking CSW's automation promise and leaving users confused at the final step.

## Outcome
The `/ship` command reliably creates pull requests using multiple authentication methods, only falling back to manual instructions as a last resort with clear explanation of what failed and how to fix it.

## User Story
As a **developer using CSW**
I want **`/ship` to create my PR automatically**
So that **the spec→plan→build→ship workflow is truly autonomous**

As a **CI/CD pipeline running CSW**
I want **PR creation to work with `GH_TOKEN` environment variable**
So that **I can automate deployments without interactive authentication**

## Context

### Current Behavior (Broken)
```bash
$ /ship spec/active/my-feature/

# Silently attempts gh pr create
# Fails because gh not authenticated
# Falls back to manual instructions with no explanation
# Leaves SHIPPED.md with "PR: pending" forever

⚠️  User confused: "Did it work? Why no PR?"
```

**Problems:**
1. Silent degradation from automated to manual
2. No clear error explaining why automation failed
3. No attempt to use alternative auth methods (GH_TOKEN, config)
4. SHIPPED.md never updated with actual PR URL
5. Breaks automation promise at the final step
6. PR display formatting runs together without proper line breaks (e.g., "PR #2: urlTitle: featState: OPEN")

### Current Auth Dependencies
`/ship` (in commands/ship.md) only tries:
```bash
gh pr create --title "..." --body "..."
```

If this fails → immediate fallback to manual instructions.

**What it should try:**
1. gh CLI (if authenticated)
2. GH_TOKEN environment variable
3. Token from gh config file
4. Manual instructions (last resort)

### Desired Behavior (Robust)
```bash
$ /ship spec/active/my-feature/

🔍 Checking GitHub authentication...
✅ Found: GH_TOKEN environment variable
🚀 Creating pull request via GitHub API...

🔗 Pull Request:

  PR #42: https://github.com/user/repo/pull/42
  Title: feat: add authentication system
  State: OPEN

📦 Updated SHIPPED.md with PR URL
```

**OR if all methods fail:**
```bash
$ /ship spec/active/my-feature/

🔍 Checking GitHub authentication...
❌ No GitHub authentication found

Tried:
  ❌ gh CLI: not authenticated (run: gh auth login)
  ❌ GH_TOKEN: environment variable not set
  ❌ gh config: no token found in ~/.config/gh/hosts.yml

Cannot create PR automatically. Please authenticate:

Option 1 (Recommended): GitHub CLI
  gh auth login

Option 2: Personal Access Token
  export GH_TOKEN=your_token_here
  # Get token: https://github.com/settings/tokens

After authenticating, run:
  /ship spec/active/my-feature/

Or create PR manually:
  https://github.com/user/repo/compare/feature/my-feature
```

## Technical Requirements

### 1. Multi-Method PR Creation Function

Add to commands/ship.md (or shared utility):

```bash
create_github_pr() {
  local title="$1"
  local body="$2"
  local branch="$3"

  # Extract repo info from git remote
  local remote_url=$(git remote get-url origin)
  local repo_path=$(echo "$remote_url" | sed -E 's/.*[:/]([^/]+\/[^/]+)(\.git)?$/\1/')
  local owner=$(echo "$repo_path" | cut -d'/' -f1)
  local repo=$(echo "$repo_path" | cut -d'/' -f2)

  echo "🔍 Checking GitHub authentication..."

  # Method 1: Try gh CLI (if authenticated)
  if command -v gh &> /dev/null; then
    if gh auth status &> /dev/null 2>&1; then
      echo "✅ Found: GitHub CLI authenticated"
      echo "🚀 Creating pull request..."

      PR_URL=$(gh pr create --title "$title" --body "$body" 2>&1)
      if [ $? -eq 0 ]; then
        echo "✅ PR created: $PR_URL"
        return 0
      fi
    else
      echo "❌ gh CLI: installed but not authenticated"
    fi
  else
    echo "ℹ️  gh CLI: not installed"
  fi

  # Method 2: Try GH_TOKEN environment variable
  if [ -n "$GH_TOKEN" ]; then
    echo "✅ Found: GH_TOKEN environment variable"
    echo "🚀 Creating pull request via GitHub API..."

    # Get base branch (usually main or master)
    local base_branch=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)

    PR_RESPONSE=$(curl -s -X POST \
      -H "Authorization: token $GH_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$owner/$repo/pulls" \
      -d "{\"title\":\"$title\",\"body\":\"$body\",\"head\":\"$branch\",\"base\":\"$base_branch\"}")

    PR_URL=$(echo "$PR_RESPONSE" | grep -o '"html_url": "[^"]*' | grep -o 'http[^"]*' | head -1)

    if [ -n "$PR_URL" ]; then
      echo "✅ PR created: $PR_URL"
      return 0
    else
      echo "❌ GH_TOKEN: API call failed"
      echo "   Response: $PR_RESPONSE"
    fi
  else
    echo "❌ GH_TOKEN: environment variable not set"
  fi

  # Method 3: Try extracting token from gh config
  if [ -f ~/.config/gh/hosts.yml ]; then
    echo "ℹ️  Found gh config file, attempting token extraction..."

    # Extract token from gh config (YAML format)
    GH_CONFIG_TOKEN=$(grep -A 2 'github.com:' ~/.config/gh/hosts.yml | grep 'oauth_token:' | awk '{print $2}')

    if [ -n "$GH_CONFIG_TOKEN" ]; then
      echo "✅ Found: Token in gh config"
      echo "🚀 Creating pull request via GitHub API..."

      local base_branch=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)

      PR_RESPONSE=$(curl -s -X POST \
        -H "Authorization: token $GH_CONFIG_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$owner/$repo/pulls" \
        -d "{\"title\":\"$title\",\"body\":\"$body\",\"head\":\"$branch\",\"base\":\"$base_branch\"}")

      PR_URL=$(echo "$PR_RESPONSE" | grep -o '"html_url": "[^"]*' | grep -o 'http[^"]*' | head -1)

      if [ -n "$PR_URL" ]; then
        echo "✅ PR created: $PR_URL"
        return 0
      fi
    else
      echo "❌ gh config: no token found"
    fi
  else
    echo "ℹ️  gh config: file not found"
  fi

  # Method 4: Manual fallback (LAST RESORT)
  echo ""
  echo "❌ Cannot create PR automatically"
  echo ""
  echo "Tried:"
  echo "  ❌ gh CLI: not authenticated (run: gh auth login)"
  echo "  ❌ GH_TOKEN: environment variable not set"
  echo "  ❌ gh config: no token found"
  echo ""
  echo "Please authenticate with GitHub:"
  echo ""
  echo "Option 1 (Recommended): GitHub CLI"
  echo "  gh auth login"
  echo ""
  echo "Option 2: Personal Access Token"
  echo "  export GH_TOKEN=your_token_here"
  echo "  # Get token: https://github.com/settings/tokens"
  echo ""
  echo "After authenticating, re-run:"
  echo "  /ship spec/active/$(basename $(dirname $PWD))/"
  echo ""
  echo "Or create PR manually:"
  echo "  https://github.com/$owner/$repo/compare/$branch"
  echo ""

  return 1
}
```

### 2. Update /ship Command

Replace current gh pr create section with:

```bash
# Create Pull Request (using multi-method approach)
create_github_pr \
  "feat: ${FEATURE_NAME}" \
  "$(cat pr-body.txt)" \
  "$(git branch --show-current)"

if [ $? -eq 0 ]; then
  # PR created successfully - update SHIPPED.md
  sed -i "s/PR: pending/PR: $PR_URL/g" spec/SHIPPED.md
  git add spec/SHIPPED.md
  git commit -m "docs: update SHIPPED.md with PR URL"
  git push

  echo ""
  echo "✅ Feature Shipped Successfully!"
  echo ""
  echo "🔗 Pull Request: $PR_URL"
else
  # Manual fallback - leave SHIPPED.md as "pending"
  echo ""
  echo "⚠️  PR creation requires manual steps"
  echo "📝 SHIPPED.md marked as 'PR: pending'"
  echo ""
  echo "After creating PR manually, update SHIPPED.md:"
  echo "  sed -i 's|PR: pending|PR: <your-pr-url>|' spec/SHIPPED.md"
  echo "  git add spec/SHIPPED.md"
  echo "  git commit -m 'docs: update SHIPPED.md with PR URL'"
  echo "  git push"
fi
```

### 3. Add /update-pr Command

New command at `commands/update-pr.md`:

```markdown
# Update PR URL in SHIPPED.md

Updates the most recent "PR: pending" entry in SHIPPED.md with actual PR URL.

Usage: /update-pr <pr-url>

Example: /update-pr https://github.com/user/repo/pull/42

\```bash
#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: /update-pr <pr-url>"
  echo "Example: /update-pr https://github.com/user/repo/pull/42"
  exit 1
fi

PR_URL="$1"

# Validate URL format
if [[ ! "$PR_URL" =~ ^https://github\.com/.+/pull/[0-9]+$ ]]; then
  echo "❌ Invalid PR URL format"
  echo "Expected: https://github.com/owner/repo/pull/123"
  exit 1
fi

# Update SHIPPED.md (replace first occurrence of "PR: pending")
if grep -q "PR: pending" spec/SHIPPED.md; then
  sed -i "0,/PR: pending/s||PR: $PR_URL|" spec/SHIPPED.md

  git add spec/SHIPPED.md
  git commit -m "docs: update SHIPPED.md with PR URL"
  git push

  echo "✅ Updated SHIPPED.md with PR URL"
  echo "🔗 $PR_URL"
else
  echo "⚠️  No 'PR: pending' entry found in spec/SHIPPED.md"
fi
\```
```

### 4. Fix PR Display Formatting

Update `commands/ship.md` Output Format section to ensure proper line breaks in PR display:

**Current (Broken):**
```
🔗 Pull Request:
{Either PR URL or instructions}
```

**Fixed:**
```
🔗 Pull Request:

  PR #{number}: {url}
  Title: {title}
  State: {state}
```

This ensures each field appears on its own line with proper spacing.

### 5. Update Documentation

**README.md - Add Prerequisites section update:**

```markdown
## Prerequisites

**All Platforms:**
- Git installed
- Bash shell
- **GitHub authentication** (for automatic PR creation)

**GitHub Authentication Setup:**

CSW can create pull requests automatically using any of these methods:

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

3. **gh config**: If gh CLI installed, CSW will use stored credentials

**Without authentication**: CSW will provide manual PR creation instructions.
```

**Add to Troubleshooting:**

```markdown
### PR Creation Issues

**`/ship` doesn't create PR automatically**

CSW tries multiple authentication methods in order:
1. GitHub CLI (if authenticated)
2. GH_TOKEN environment variable
3. Token from gh config

If all fail, you'll get manual instructions.

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

**After manual PR creation**:
```bash
/update-pr https://github.com/owner/repo/pull/123
```
```

## Rationale

### Why Multi-Method Authentication

**1. Flexibility Across Environments**
- Local dev: gh CLI (most convenient)
- CI/CD: GH_TOKEN (standard practice)
- Existing gh users: Reuse stored credentials
- Corporate: Any method works

**2. Maximizes Automation**
- Try every available method before giving up
- Increases likelihood of successful PR creation
- Reduces manual intervention

**3. Clear Failure Feedback**
- Shows exactly what was tried
- Explains why each method failed
- Provides specific fix instructions
- Tells user what to do next

**4. Production-Ready**
- Works in CI/CD pipelines (GH_TOKEN)
- Works in GitHub Actions (automatic GH_TOKEN)
- Works in local dev (gh CLI or token)
- Graceful degradation to manual

### Why /update-pr Command

- Completes SHIPPED.md after manual PR creation
- Maintains traceability
- Simple recovery path
- Clean git history

### Ecosystem Precedent

**Heroku CLI**: Tries multiple auth methods (netrc, env var, interactive)
**AWS CLI**: Tries credentials chain (env → file → instance role)
**gcloud CLI**: Tries service account → user account → interactive
**Docker CLI**: Tries config file → env var → credential helper

Pattern: **Production tools have robust auth with multiple fallbacks**

## Validation Criteria

### Functional
- [ ] gh CLI authenticated: PR created successfully
- [ ] GH_TOKEN set: PR created via API successfully
- [ ] Token in gh config: Extracted and used successfully
- [ ] No auth methods: Clear error with instructions
- [ ] /update-pr updates SHIPPED.md correctly
- [ ] PR URL format validated in /update-pr

### Error Handling
- [ ] Invalid GH_TOKEN: Clear error message
- [ ] Network failure: Handled gracefully
- [ ] Invalid repo format: Detected and reported
- [ ] Permission denied: Clear error with fix instructions

### Documentation
- [ ] README explains authentication options
- [ ] Troubleshooting covers PR creation issues
- [ ] /update-pr command documented
- [ ] Success messages show which method was used

### User Experience
- [ ] User knows which auth method worked
- [ ] Clear feedback at each step
- [ ] Manual fallback is last resort
- [ ] Recovery path is simple (/update-pr)
- [ ] PR information displays with proper line breaks between fields
- [ ] PR details are readable and well-formatted

## Success Metrics

### Quantitative
- 95%+ PR creation success rate (auto vs manual)
- <1% of users need manual PR creation
- 100% of users understand why auth failed (if it does)

### Qualitative
- No user confusion about PR creation
- Clear feedback at every step
- Automation works in CI/CD
- Recovery is straightforward

## Edge Cases & Considerations

### Token Permissions Insufficient
**Scenario**: GH_TOKEN lacks repo scope
**Response**: API returns 403, error message explains needed scopes

### Multiple Remote Origins
**Scenario**: Git repo has multiple remotes
**Response**: Use `origin` by default, detect from current branch's upstream

### Private Repository
**Scenario**: User tries to create PR for private repo
**Response**: Works if authenticated correctly, fails with clear permission error if not

### GitHub Enterprise
**Scenario**: User's repo is on GitHub Enterprise
**Response**: Extract base URL from remote, use for API calls

### Rate Limiting
**Scenario**: GitHub API rate limit exceeded
**Response**: Show rate limit error, suggest waiting or using gh CLI (has higher limits)

## Implementation Notes

**Order of Operations**:
1. Fix PR display formatting in commands/ship.md Output Format section
2. Implement multi-method PR creation function
3. Test each auth method independently
4. Test fallback chain (1 → 2 → 3 → manual)
5. Add /update-pr command
6. Update documentation
7. Test in real workflow end-to-end

**Testing Matrix**:
- [ ] PR display formatting shows proper line breaks
- [ ] Local with gh CLI authenticated
- [ ] Local with GH_TOKEN set
- [ ] Local with gh config but not active
- [ ] Local with no authentication
- [ ] CI/CD with GH_TOKEN (GitHub Actions)
- [ ] CI/CD with no authentication (should fail clearly)
- [ ] Manual PR creation + /update-pr

**Security Considerations**:
- Never log tokens (gh config extraction is read-only)
- Don't expose tokens in error messages
- Validate token format before using
- Don't store tokens (use them directly)

## Open Questions

None - ready to implement!
