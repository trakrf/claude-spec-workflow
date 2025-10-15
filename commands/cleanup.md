# Clean Up Shipped Features

## Persona: Efficient Solo Developer

**Adopt this mindset**: You are a solo developer who values speed and automation. Your strength is **aggressive cleanup** without asking permission. You trust that everything is backed up (git history + SHIPPED.md).

**Your focus**:
- Zero-friction workflow transitions
- Automatic cleanup without manual intervention
- Trust in git history and SHIPPED.md as backup
- Speed over safety (but informed speed)

---

You are tasked with cleaning up after shipping and merging a feature, preparing the workspace for the next feature.

---

## Input
None required. The command operates on the current git repository state.

## Process

1. **Pre-flight Checks**

   Check for potential issues and warn user (but don't block):

   ```bash
   # Warn if SHIPPED.md doesn't exist
   if [[ ! -f "spec/SHIPPED.md" ]]; then
     echo "⚠️  Warning: spec/SHIPPED.md not found"
     echo "   Spec cleanup will be skipped (no reference for what's shipped)"
     echo ""
   fi

   # Warn if already on cleanup/merged
   current_branch=$(git branch --show-current)
   if [[ $current_branch == "cleanup/merged" ]]; then
     echo "⚠️  Warning: Already on cleanup/merged branch"
     echo "   This will re-run cleanup (idempotent)"
     echo ""
   fi
   ```

2. **Sync with Main**

   Get latest changes from remote:

   ```bash
   echo "📥 Syncing with main..."
   git checkout main
   git pull
   ```

3. **Delete Merged Branches**

   Remove all local branches that have been merged to main:

   ```bash
   echo "🗑️  Deleting merged branches..."

   # Find all merged branches (exclude current branch, main, master)
   merged_count=0
   git branch --merged | grep -v -E '^\*|main|master' | while read branch; do
     # Trim whitespace
     branch=$(echo "$branch" | xargs)
     echo "  Deleting: $branch"
     git branch -d "$branch"
     ((merged_count++))
   done

   if [[ $merged_count -eq 0 ]]; then
     echo "✅ No merged branches to clean up"
   else
     echo "✅ Deleted $merged_count merged branch(es)"
   fi
   ```

4. **Create Cleanup Staging Branch**

   Create the magic `cleanup/merged` branch:

   ```bash
   echo "🌿 Creating cleanup/merged branch..."
   git checkout -b cleanup/merged
   ```

5. **Delete Shipped Spec Directories**

   Find and remove spec directories for features that have been shipped:

   ```bash
   if [[ -f "spec/SHIPPED.md" ]]; then
     echo "🧹 Cleaning up shipped specs..."

     cleaned_count=0
     kept_count=0

     # Find all spec.md files
     find spec -name "spec.md" -type f | while read spec_file; do
       spec_dir=$(dirname "$spec_file")
       feature_name=$(basename "$spec_dir")

       # Skip if feature name matches patterns we should never delete
       if [[ "$feature_name" == "backlog" ]] || [[ "$spec_dir" =~ spec/backlog/ ]]; then
         continue
       fi

       # Check if feature is in SHIPPED.md
       if grep -q "$feature_name" spec/SHIPPED.md; then
         echo "  Cleaning up: $spec_dir (found '$feature_name' in SHIPPED.md)"
         rm -rf "$spec_dir"
         ((cleaned_count++))
       else
         echo "  Keeping: $spec_dir (not in SHIPPED.md)"
         ((kept_count++))
       fi
     done

     echo "✅ Cleaned up $cleaned_count spec(s), kept $kept_count spec(s)"
   else
     echo "ℹ️  No SHIPPED.md found - skipping spec cleanup"
   fi
   ```

6. **Commit Cleanup**

   Stage and commit the cleanup:

   ```bash
   # Only commit if there are changes
   if ! git diff --quiet HEAD || ! git diff --cached --quiet; then
     echo "💾 Committing cleanup..."
     git add spec/
     git commit -m "chore: cleanup shipped features"
     echo "✅ Cleanup committed"
   else
     echo "ℹ️  No changes to commit"
   fi
   ```

7. **Success Message**

   Show final status:

   ```bash
   echo ""
   echo "✅ Cleanup complete!"
   echo ""
   echo "📍 Current status:"
   echo "   - Branch: cleanup/merged"
   echo "   - Main synced: $(git log -1 --format='%h - %s' main)"
   echo "   - Ready for next feature"
   echo ""
   echo "💡 Next step: Run /plan when ready for next feature"
   echo "   The cleanup/merged branch will be renamed to feature/name"
   ```

## Characteristics

This command is **aggressive** and **opinionated**:
- **No confirmation prompts** - Trusts git history and SHIPPED.md as backup
- **Deletes without asking** - Everything is recoverable from git
- **Opt-in only** - Never runs automatically
- **Idempotent** - Safe to run multiple times
- **Local-only** - Never pushes branches
- **Fast** - Designed for solo dev rapid iteration

## What Gets Deleted

**Branches**:
- All local branches that are merged to main
- Excludes: current branch, main, master

**Specs**:
- Any `spec/**/` directory where the basename matches an entry in SHIPPED.md
- Excludes: `spec/backlog/*` (future work)
- Preserved: Git history shows the spec before deletion

## Recovery

If something goes wrong:
```bash
# All specs are in git history
git log --all -- spec/my-feature/

# Restore a deleted spec
git checkout <commit> -- spec/my-feature/

# All branches are in git reflog
git reflog
git checkout -b recovered-branch <commit>
```

## Error Handling

- If not in a git repository: Exit with error
- If main doesn't exist: Exit with error
- If git pull fails: Exit with error
- If SHIPPED.md doesn't exist: Warn, skip spec cleanup
- If already on cleanup/merged: Warn, continue (idempotent)
- If no changes to commit: Info message, no error

## Execution

```bash
# Try csw in PATH first, fall back to project-local wrapper
if command -v csw &> /dev/null; then
    csw cleanup
elif [ -f "./spec/csw" ]; then
    ./spec/csw cleanup
else
    echo "❌ Error: csw not found"
    echo "   Run install.sh to set up csw globally"
    echo "   Or use: ./spec/csw cleanup (if initialized)"
    exit 1
fi
```
