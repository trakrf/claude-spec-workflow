# Feature: Optimize SHIPPED.md Workflow

## Origin
Discovered during dogfooding the fix-csw-symlink-resolution feature. The `/ship` command creates two commits and two pushes for SHIPPED.md updates: first with "PR: pending", then updating with the actual PR URL. This creates noise in git history and is inefficient.

## Outcome
The `/ship` command updates SHIPPED.md once with complete information (commit + PR URL) in a single commit after PR creation, eliminating the double-commit pattern.

## User Story
As a **developer using CSW to ship features**
I want **SHIPPED.md updated in one commit with complete info**
So that **git history is clean and I don't create temporary "PR: pending" states**

## Context

### Current Workflow (Inefficient)
```bash
# Step 7: Update SHIPPED.md
- Add entry with "PR: pending"
- Commit: "docs: add feature to SHIPPED.md"

# Step 8: Push branch

# Step 9: Create PR
- Run gh pr create
- Capture PR URL
- Update SHIPPED.md: "PR: pending" → "PR: https://..."
- Commit: "docs: update SHIPPED.md with PR #N URL"
- Push again
```

**Result**: Two commits, two pushes
```
e1bda9b docs: add fix-csw-symlink-resolution to SHIPPED.md
9db83eb docs: update SHIPPED.md with PR #13 URL
```

### Proposed Workflow (Optimized)
```bash
# Step 7: Push branch FIRST (no SHIPPED.md yet)
- Push feature branch to remote
- git push -u origin feature/name

# Step 8: Create PR (using pushed branch)
- Run gh pr create
- Capture PR URL immediately
- Now we have BOTH commit hash AND PR URL

# Step 9: Update SHIPPED.md (single commit with complete info)
- Add entry with both commit + PR in one go
- Commit: "docs: ship feature-name (#13)"
- Push this one commit
```

**Result**: One commit, one push
```
abc123 docs: ship fix-csw-symlink-resolution (#13)
```

### Additional Improvement: PR Placement

**Current format** (PR buried at bottom):
```markdown
## Feature Name
- **Date**: 2025-10-15
- **Branch**: feature/name
- **Commit**: abc123
- **Summary**: ...
[40 lines of metrics]
- **PR**: https://...  ← way down here
```

**Proposed format** (PR next to commit):
```markdown
## Feature Name
- **Date**: 2025-10-15
- **Branch**: feature/name
- **Commit**: abc123 | **PR**: #13
- **Summary**: ...
```

**Rationale**: PR contains that commit, so they're related. Keep related data together.

## Technical Requirements

### 1. Update commands/ship.md Workflow

**Current order** (lines ~140-180):
```
7. Update Shipped Log (with "PR: pending")
8. Push Branch
9. Create Pull Request (then update SHIPPED.md again)
```

**New order**:
```
7. Push Branch (no SHIPPED.md changes yet)
8. Create Pull Request (capture URL)
9. Update Shipped Log (single commit with complete info)
```

### 2. Update SHIPPED.md Template Format

**Change this** (in commands/ship.md):
```markdown
## {Feature Name}
- **Date**: {YYYY-MM-DD}
- **Branch**: feature/{name}
- **Commit**: {git rev-parse HEAD}
...
- **PR**: {pending|url}
```

**To this**:
```markdown
## {Feature Name}
- **Date**: {YYYY-MM-DD}
- **Branch**: feature/{name}
- **Commit**: {short-hash} | **PR**: #{number}
...
```

**Technical details**:
- Use short hash: `git rev-parse --short HEAD` (7-8 chars)
- Use PR number format: `#13` instead of full URL
- Keep full URL accessible via GitHub's automatic linking

### 3. Update Commit Message

**Current**: Two separate commits
- "docs: add {feature} to SHIPPED.md"
- "docs: update SHIPPED.md with PR #{N} URL"

**New**: Single commit
- "docs: ship {feature} (#{N})"

**Example**: `docs: ship fix-csw-symlink-resolution (#13)`

### 4. Remove PR Update Logic

**In commands/ship.md, Method 1-3 success blocks**, remove:
```bash
# Current (after PR created):
- Update SHIPPED.md with PR URL
- Commit again
- Push again
```

**Replace with**: Return PR info to calling code (command already handles single SHIPPED.md commit)

### 5. Optional: Update Existing SHIPPED.md Entries

Consider (but not required) updating existing entries for consistency:
```bash
# Before:
- **Commit**: 72193403c6434db266d7be42669490b34f31eeac
...
- **PR**: https://github.com/trakrf/claude-spec-workflow/pull/13

# After:
- **Commit**: 7219340 | **PR**: #13
```

**Decision**: Do this only if it's a quick find/replace, otherwise skip for historical entries.

## Validation Criteria

### Functional
- [ ] `/ship` pushes branch BEFORE creating PR
- [ ] `/ship` creates PR and captures URL/number
- [ ] `/ship` updates SHIPPED.md with complete info in ONE commit
- [ ] Zero commits with "PR: pending" in SHIPPED.md
- [ ] Git log shows single "docs: ship {feature} (#{N})" commit

### Format
- [ ] SHIPPED.md shows `Commit: abc1234 | PR: #13` format
- [ ] PR number uses GitHub shorthand `#13` (not full URL)
- [ ] Commit hash is short form (7-8 chars)

### Edge Cases
- [ ] Works with all PR creation methods (gh CLI, GH_TOKEN, config)
- [ ] Manual PR creation fallback still works
- [ ] If PR creation fails, SHIPPED.md not updated (no incomplete entries)

## Success Metrics

### Efficiency
- ✅ **One commit instead of two** - Result: TBD
- ✅ **One push instead of two** - Result: TBD
- ✅ **No "PR: pending" temporary states** - Result: TBD

### Code Quality
- ✅ **Cleaner git history** - Result: TBD (fewer noise commits)
- ✅ **More scannable SHIPPED.md** - Result: TBD (PR visible with commit)
- ✅ **Simpler command logic** - Result: TBD (remove update-PR branch)

## Implementation Notes

### Files to Modify
- `commands/ship.md` - Resequence steps 7-9, update template
- Maybe: existing SHIPPED.md entries (optional cleanup)

### Backward Compatibility
- No breaking changes (internal workflow optimization)
- Existing SHIPPED.md entries remain valid
- Users see no difference (just fewer commits in their history)

### Testing Strategy
1. Ship a test feature with new workflow
2. Verify single commit created
3. Verify SHIPPED.md format correct
4. Verify PR created successfully

## Risk Assessment

**Risk**: PR creation fails after push (branch pushed but no SHIPPED.md entry)
**Mitigation**: This is actually better than current state (no incomplete "PR: pending" entry). User can manually create PR and then update SHIPPED.md.

**Risk**: Users expect "PR: pending" pattern
**Mitigation**: None - this is internal implementation detail. Users see cleaner result.

**Risk**: Short hash collisions
**Mitigation**: 7-8 chars provides ~268M unique hashes. GitHub uses 7 char hashes by default.

## Open Questions

None - scope is clear and straightforward.

## Related Work

**Previous specs** that addressed related concerns:
- "Fix /plan Auto-Cleanup Workflow" (Oct 14) - Removed breadcrumbs, added direct SHIPPED.md updates
- "Script Library Phase 2" (Oct 14) - Simplified paths
- "/cleanup Command" (Oct 15) - Separate cleanup workflow

This spec builds on that work by optimizing the SHIPPED.md update pattern.
