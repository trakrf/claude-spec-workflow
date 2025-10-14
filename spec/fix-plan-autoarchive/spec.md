# Fix /plan Auto-Archive Workflow

**Status**: Backlog
**Created**: 2025-10-14
**Priority**: High (blocks proper workflow execution)

## Problem Statement

The `/plan` command's "Archive Shipped Features" workflow has two critical issues:

1. **Doesn't detect merged branch scenario**: When you're still on a feature branch that's been merged and shipped (exists in `SHIPPED.md`), `/plan` should detect this and:
   - Pull latest main
   - Create new branch for the next feature
   - Delete the merged branch
   - Delete the completed spec (relies on git history)

2. **Outdated path assumptions**: The archive section looks for `spec/active/*` but the current structure uses `spec/*/` (flattened, no active/ directory)

### Current Behavior

When running `/plan changelog-convention` while on `feature/onboarding-bootstrap` (which was already shipped in PR #10):
- ❌ Didn't detect we're on a merged branch
- ❌ Didn't pull main automatically
- ❌ Didn't prompt to delete onboarding-bootstrap spec
- ❌ Didn't create new branch feature/changelog-convention
- ❌ Required manual intervention to clean up

### Expected Behavior

When running `/plan <feature-name>`:

1. **Check current branch status**:
   ```bash
   current_branch=$(git branch --show-current)

   # If current branch is in SHIPPED.md:
   if grep -q "Branch: $current_branch" spec/SHIPPED.md; then
     echo "🧹 Current branch $current_branch has been shipped"
     echo "📥 Pulling latest main..."
     git checkout main && git pull origin main

     echo "🗑️  Deleting merged branch $current_branch..."
     git branch -d "$current_branch"

     # Extract feature name from branch
     feature=$(echo "$current_branch" | sed 's/feature\///')

     # Delete the spec (relies on git history for retrieval)
     if [ -d "spec/$feature" ]; then
       echo "🗑️  Deleting spec/$feature..."
       rm -rf "spec/$feature"
       git add "spec/$feature"
       git commit -m "chore: delete $feature spec (shipped in PR #X)"
     fi
   fi
   ```

2. **Then check for OTHER shipped features to delete**:
   - Scan `spec/*/spec.md` (not `spec/active/*/spec.md`)
   - Cross-reference with `spec/SHIPPED.md`
   - Prompt to delete each shipped feature found

3. **Create new branch if needed**:
   ```bash
   # If planning a specific feature and not on its branch:
   if [ "$current_branch" = "main" ]; then
     git checkout -b "feature/$new_feature_name"
   fi
   ```

## Requirements

### Must Have
- ✅ Detect if current branch is in SHIPPED.md
- ✅ Auto-pull main when on shipped branch
- ✅ Auto-delete merged branch after switching to main
- ✅ Auto-delete the shipped feature's spec
- ✅ Fix path scanning from `spec/active/*` to `spec/*`
- ✅ Exclude `spec/backlog/*` from cleanup prompts
- ✅ Create new feature branch if planning from main
- ✅ All delete operations committed properly

### Should Have
- Validate branch is actually merged before deleting (safety check)
- Show user what's happening at each step (transparency)
- Handle edge cases:
  - Current branch not in SHIPPED.md (normal planning)
  - Already on correct feature branch (resume planning)
  - Multiple shipped features in spec/ (prompt for each)

### Nice to Have
- Detect if remote branch can be deleted (was merged via PR)
- Offer to delete remote branch: `git push origin --delete feature/x`

## Success Metrics

### Functional (6/6)
- [ ] Running `/plan <feature>` while on merged branch switches to main
- [ ] Merged branch is deleted automatically
- [ ] Completed spec is deleted (preserved in git history)
- [ ] Delete commit is created automatically
- [ ] New feature branch is created
- [ ] Additional shipped features are detected and prompted for deletion

### Developer Experience (4/4)
- [ ] Zero manual git commands required for branch cleanup
- [ ] Clear console output showing each step
- [ ] No confusing "you're on the wrong branch" situations
- [ ] Workflow feels automatic and intelligent

### Edge Case Handling (3/3)
- [ ] Works when current branch NOT in SHIPPED.md (normal flow)
- [ ] Works when already on correct feature branch (resume)
- [ ] Works when spec/ has multiple shipped features

**Total**: 13 metrics

## Non-Requirements

- ❌ Deleting features not in SHIPPED.md (they're still active)
- ❌ Handling uncommitted changes (user should commit first)
- ❌ Creating SHIPPED.md entries (that's /ship's job)
- ❌ Pushing to remote (user does that manually)

## Technical Approach

### 1. Update commands/plan.md

Add new section BEFORE "Archive Shipped Features":

```markdown
## Pre-Flight: Branch Cleanup

**Check if current branch has been shipped**:

\`\`\`bash
current_branch=$(git branch --show-current)

# Check if this branch is in SHIPPED.md
if grep -q "Branch: $current_branch" spec/SHIPPED.md; then
  echo "🧹 Cleaning up shipped branch: $current_branch"

  # Pull latest main
  echo "📥 Pulling latest main..."
  git checkout main
  git pull origin main

  # Delete merged branch
  echo "🗑️  Deleting merged branch..."
  git branch -d "$current_branch"

  # Delete spec if exists (preserved in git history)
  feature=$(echo "$current_branch" | sed 's/feature\///')
  if [ -d "spec/$feature" ]; then
    echo "🗑️  Deleting spec/$feature..."
    rm -rf "spec/$feature"
    git add "spec/$feature"
    git commit -m "chore: delete $feature spec (shipped in PR #X)"
  fi

  echo "✅ Workspace cleaned - ready for new feature"
fi
\`\`\`
```

### 2. Fix Cleanup Section Paths

Replace:
```bash
for dir in spec/active/*/; do
```

With:
```bash
for dir in spec/*/; do
  # Skip backlog and non-directory files
  [[ "$dir" =~ spec/backlog/ ]] && continue
  [[ ! -f "$dir/spec.md" ]] && continue
```

### 3. Add Branch Creation Logic

After cleanup section, before planning:

```bash
# Ensure we're on the right branch
target_branch="feature/$feature_name"
current_branch=$(git branch --show-current)

if [ "$current_branch" = "main" ]; then
  echo "🌿 Creating new branch: $target_branch"
  git checkout -b "$target_branch"
elif [ "$current_branch" != "$target_branch" ]; then
  echo "⚠️  Current branch: $current_branch"
  echo "⚠️  Expected: $target_branch"
  echo "Continue planning on current branch? (y/n)"
  # Wait for user input...
fi
```

## Testing Strategy

### Manual Testing Scenarios

1. **Shipped branch cleanup**:
   ```bash
   # Setup: Be on feature/foo which is in SHIPPED.md
   git checkout feature/foo
   /plan bar
   # Expected: Switches to main, deletes foo, deletes spec/foo/, creates feature/bar
   ```

2. **Normal planning from main**:
   ```bash
   git checkout main
   /plan new-feature
   # Expected: Creates feature/new-feature, no archive prompts
   ```

3. **Multiple shipped features**:
   ```bash
   # Setup: spec/foo/ and spec/bar/ both in SHIPPED.md, on main
   /plan baz
   # Expected: Prompts to delete foo, then bar, then creates feature/baz
   ```

4. **Resume planning**:
   ```bash
   # Setup: Already on feature/foo, spec/foo/ exists but not shipped
   /plan foo
   # Expected: Continues on feature/foo, no branch changes
   ```

### Validation Commands

After implementation:
```bash
# Shellcheck
shellcheck commands/plan.md (if extracted to script)

# Syntax
bash -n <script>

# Integration test
./test-plan-archive-workflow.sh
```

## Constraints

- Must not require user to answer prompts for obvious cleanup (shipped branch)
- Must preserve all existing /plan functionality
- Must work with both `spec/feature/` and `spec/nested/feature/` structures
- Must not delete specs still in development
- Must be safe (don't delete branches that aren't merged)

## Dependencies

- Git must be available
- spec/SHIPPED.md must exist and follow current format
- Branch naming convention: `feature/<name>`

## Migration Notes

**Breaking Changes**: None - this is purely additive behavior

**User Impact**:
- Users will see automatic cleanup when resuming work after shipping
- Less manual git commands required
- Workspace stays cleaner automatically

## Open Questions

1. Should we validate branch is actually merged before deleting? (use `git branch --merged main`)
2. Should we offer to delete remote branch too?
3. What if spec/SHIPPED.md has malformed entries?
4. Should delete operation be atomic (all or nothing)?

## References

- Current workflow: `spec/README.md` - Feature Lifecycle & Archive Workflow (lines 122-130: "Archive = DELETE")
- SHIPPED.md format: `spec/SHIPPED.md`
- Existing cleanup logic: `commands/plan.md` (Archive Shipped Features section - needs updating)
- Git branch safety: `git branch -d` vs `git branch -D`
