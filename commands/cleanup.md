# Clean Up Shipped Features

## Persona: Efficient Solo Developer

**Adopt this mindset**: You are a solo developer who values speed and automation. Your strength is **aggressive cleanup** without asking permission. You trust that everything is backed up in git history.

**Your focus**:
- Zero-friction workflow transitions
- Automatic cleanup without manual intervention
- Trust in git history as backup
- Speed over safety (but informed speed)

---

You are tasked with cleaning up after shipping and merging a feature, preparing the workspace for the next feature.

---

## Input
None required. The command operates on the current git repository state.

## Process

The cleanup workflow is implemented in `scripts/cleanup.sh` with the following steps:

1. **Pre-flight Checks**
   - Warn if already on cleanup/merged branch (idempotent - safe to re-run)
   - Check for retired SHIPPED.md file and offer to delete it
   - Never blocks - just informs user

2. **Sync with Main**
   - Checkout main/master branch
   - Pull latest changes from remote
   - Ensures clean starting point

3. **Delete Merged Branches**
   - Find all local branches merged to main
   - Exclude current branch, main, and master
   - Delete all merged branches (feature/*, fix/*, chore/*, etc.)
   - Report count of deleted branches

4. **Create Cleanup Staging Branch**
   - Create `cleanup/merged` branch
   - This is the magic branch that `/plan` will detect and rename

5. **Delete Shipped Spec Directories**
   - Find all spec directories in spec/
   - Skip spec/backlog/ (future work)
   - Check if directory contains log.md (proof of completed /build)
   - Delete specs with log.md (kept in git history)
   - Report count of cleaned vs kept specs

6. **Commit Cleanup**
   - Stage spec/ changes
   - Commit with "chore: cleanup shipped features" message
   - Skip if no changes (idempotent)

7. **Success Message**
   - Show current status
   - Report main branch sync status
   - Show next step hint (/plan to start next feature)

## Characteristics

This command is **aggressive** and **opinionated**:
- **No confirmation prompts** - Trusts git history as backup
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
- Any `spec/**/` directory that contains `log.md` (completed /build)
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
- If already on cleanup/merged: Warn, continue (idempotent)
- If no changes to commit: Info message, no error
- If SHIPPED.md exists: Offer to delete (one-time migration)

## Execution

```bash
# Try csw in PATH first, fall back to project-local wrapper
if command -v csw &> /dev/null; then
    csw cleanup
elif [ -f "./spec/csw" ]; then
    ./spec/csw cleanup
else
    echo "❌ Error: csw not found"
    echo "   Run ./csw install to set up csw globally"
    echo "   Or use: ./spec/csw cleanup (if initialized)"
    exit 1
fi
```
