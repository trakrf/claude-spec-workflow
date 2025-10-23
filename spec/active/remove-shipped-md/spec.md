# Feature: Remove SHIPPED.md from Workflow

## Origin
This specification emerged from investigating issue #39 about cleanup failing to delete merged branches. During investigation, we discovered that SHIPPED.md is redundant and causes confusion.

## Outcome
Remove SHIPPED.md from the workflow entirely. The completion truth is simpler: if `log.md` exists on main, the spec is done. GitHub PRs are the source of truth for what shipped.

## User Story
As a developer using claude-spec-workflow
I want a simpler workflow without redundant tracking files
So that I don't have to maintain commit SHAs that become invalid after squash merges

## Context

**Discovery**: While investigating branch cleanup issues, we found:
- SHIPPED.md stores feature branch commit SHAs (e.g., `e16b6fe`)
- After squash/rebase merge, those SHAs don't exist in main (become `8c351a5`)
- This creates confusion: "Why can't I find this commit?"

**Current State**:
- `/ship` creates SHIPPED.md entry with branch tip commit SHA
- `/cleanup` checks if SHIPPED.md exists, but **never reads its content**
- Cleanup uses `log.md` presence to decide what to delete
- SHIPPED.md is just a gate file, not a data source

**Key Insight**: We're reinventing GitHub's PR list. SHIPPED.md is cargo cult.

**Desired State**:
- No SHIPPED.md file
- Simpler truth: `log.md` on main = spec is complete
- GitHub PRs = canonical record of what shipped
- Less maintenance, no SHA confusion

## The Truth

```bash
# Proof a spec is complete:
if [ -f "spec/active/my-feature/log.md" ]; then
  # /build succeeded
  # This spec is done
  # Can be deleted
fi

# Want to see how it was implemented?
gh pr list --search "my-feature" --state merged
gh pr view 123
```

That's it. That's the whole story.

## Technical Requirements

### 1. Remove SHIPPED.md from /ship command
- **File**: `commands/ship.md`
- **Action**: Remove Step 9 "Update Shipped Log" (lines 226-260)
- **Result**: PR creation is the final step, no SHIPPED.md update

### 2. Remove SHIPPED.md gate from cleanup
- **File**: `scripts/cleanup.sh`
- **Action**: Remove SHIPPED.md existence checks (lines 17-21, 52, 89-91)
- **Keep**: The `log.md`-based deletion logic (lines 62-85) - it's correct
- **Result**: Cleanup works based on `log.md` only

### 3. Remove SHIPPED.md initialization from csw init
- **File**: `csw` init command
- **Action**: Remove SHIPPED.md creation (lines 256-259)
- **Result**: No empty SHIPPED.md created in new projects

### 4. Update documentation
- **File**: `spec/README.md` (if it mentions SHIPPED.md)
- **Action**: Remove references to SHIPPED.md
- **Result**: Docs reflect simpler workflow

## What Stays

The core cleanup logic is **already correct** and needs no changes:

```bash
# From scripts/lib/cleanup.sh:87-155
# This is the truth - keep this exactly as-is

# Find specs with log.md (proof of /build completion)
completed_specs=$(find spec -name "log.md" -type f 2>/dev/null || true)

# Delete specs that have log.md
if echo "$completed_specs" | grep -q "^${spec_dir}/log.md$"; then
    echo "  ✓ Removing completed spec: $spec_dir (has log.md)"
    rm -rf "$spec_dir"
fi
```

## Validation Criteria

- [ ] `/ship` command completes without creating SHIPPED.md
- [ ] `/cleanup` still deletes specs with log.md (existing logic works)
- [ ] No errors about missing SHIPPED.md during cleanup
- [ ] New projects initialized without SHIPPED.md file
- [ ] Documentation doesn't reference SHIPPED.md

## Success Metrics

**Simplicity**: Workflow has one less file to maintain
**Clarity**: No confusion about "orphaned" commit SHAs
**Truth**: Single source - GitHub PRs are canonical, `log.md` is local proof

## Migration

**For existing projects with SHIPPED.md**:
- Can keep the file as historical reference
- Or delete it - no workflow depends on its content
- New workflow won't create or update it

## Conversation References

**Key insight**:
> "Are we just reinventing the PR list with SHIPPED.md? Maybe it's stupid and we should bin it."

**Agreement**:
> "Bottom line, if a spec subdirectory has a log.md on main, it's done. We could go back to that PR if we care to see how the sausage was made."

**The simplicity**:
> "Is it really as simple as that? I think so" - Yes, it is.
