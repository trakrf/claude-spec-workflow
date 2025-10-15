# Feature: Simplify Workflow for Rebase-Only Repos

## Origin
Discovered during onboarding-bootstrap planning. Current workflow uses breadcrumb pattern (`.shipped-entry`, `.pr-url`) designed for merge commits, but this repo uses rebase-only merges. This creates unnecessary complexity.

## Outcome
Simplified workflow where `/ship` updates SHIPPED.md directly and `/plan` just verifies + deletes shipped specs. No breadcrumb files needed.

## User Story
As a **developer using CSW with rebase-only workflow**
I want **SHIPPED.md updated immediately when I ship**
So that **I don't have orphaned breadcrumb files and simpler archive process**

## Context

### Current Workflow (Breadcrumb Pattern)
1. `/ship` → creates `.shipped-entry` and `.pr-url` breadcrumb files
2. PR merged (merge commit hash unknown during /ship)
3. `/plan` next feature → reads breadcrumbs, updates SHIPPED.md, deletes spec

**Why breadcrumbs?** Designed for merge commits where GitHub creates the commit hash during merge.

### With Rebase-Only Repos
- `/ship` → HEAD commit is `abc123`
- PR rebased onto main → commit hash might change if conflicts, but PR link always works
- Hash in SHIPPED.md is reference point, not critical link

### Proposed Workflow (Direct Update)
1. `/ship` → updates SHIPPED.md directly with HEAD commit + PR link
2. PR merged (rebase)
3. `/plan` next feature → verifies PR merged (via `gh pr view --json state`), deletes spec

## Technical Requirements

### 1. Update `/ship` Command
Remove breadcrumb creation, add direct SHIPPED.md update:
```bash
# Instead of creating .shipped-entry
# Directly append to SHIPPED.md with current HEAD commit
```

### 2. Update `/plan` Archive Detection
Remove breadcrumb reading, add PR merge verification:
```bash
# Check if spec is in SHIPPED.md
# If yes, verify PR is merged: gh pr view {pr-url} --json state
# If merged, delete spec/
# If not merged, warn user and skip
```

### 3. Update Documentation
- **spec/README.md**: Document rebase-only requirement
- **spec/README.md**: Update Feature Lifecycle diagram to remove breadcrumbs
- Note: CONTRIBUTING.md should inherit understanding from README context

### 4. Remove Breadcrumb Logic
Clean up:
- Remove `.shipped-entry` creation code
- Remove `.pr-url` file handling
- Remove breadcrumb reading in archive logic
- Update gitignore if breadcrumb files were ignored

## Rationale

### Pros
- ✅ Simpler - no breadcrumb files
- ✅ SHIPPED.md immediately up to date
- ✅ Less moving pieces
- ✅ Rebase-only is modern best practice

### Cons
- ⚠️ Less flexible - mandates rebase workflow
- ⚠️ Hash might be stale if rebase creates new commit (but PR link still valid)

### Risk: Manual Merges
**Scenario**: Someone merges PR without using `/ship`
**Response**: Off-process behavior. SHIPPED.md won't have entry (their responsibility). Next `/plan` can still detect and offer archive based on directory presence vs SHIPPED.md.

**Philosophy**: Optimize for happy path (using tools as intended), not every edge case.

## Validation Criteria
- [ ] `/ship` updates SHIPPED.md directly with HEAD commit
- [ ] `/ship` includes PR link in SHIPPED.md
- [ ] `/plan` verifies PR merged before archiving
- [ ] `/plan` deletes shipped spec after verification
- [ ] No breadcrumb files created
- [ ] Documentation updated in spec/README.md
- [ ] Feature Lifecycle diagram updated (mermaid)

## Success Metrics
- Zero breadcrumb files in repo after `/ship`
- SHIPPED.md always current (no stale entries)
- Archive process simpler (one step fewer)

## Implementation Notes
- Requires `gh` CLI for PR state verification
- Should fail gracefully if `gh` not installed
- Test with actual PR merge workflow to ensure hash handling correct

## Open Questions
- Should we support both workflows (rebase + merge commit) with detection?
  - **Leaning no** - keep it simple, mandate rebase-only
- What if hash changes during rebase?
  - **Non-issue** - PR link is source of truth, hash is just reference
