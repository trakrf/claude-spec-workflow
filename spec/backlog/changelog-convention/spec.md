# Feature: Adopt CHANGELOG.md Convention

## Origin
Discovered during onboarding-bootstrap PR review. `spec/SHIPPED.md` is essentially a changelog - it records what shipped, when, and with what impact. The format is already perfect (detailed, metrics-focused, with PR links), but the name and location don't follow the industry convention that everyone expects.

## Outcome
Replace `spec/SHIPPED.md` with `./CHANGELOG.md` at repository root. Maintain the detailed format (better than typical changelogs), but use the conventional name and location for discoverability and tooling integration.

## User Story
As a **developer evaluating CSW**
I want **to check ./CHANGELOG.md for release history**
So that **I can see what's changed without learning CSW-specific conventions**

As a **contributor to CSW**
I want **changelogs in the standard location**
So that **GitHub release automation and other tools work correctly**

As a **CSW user checking for updates**
I want **detailed changelog entries with metrics**
So that **I understand what was actually accomplished, not just vague summaries**

## Context

### Current State
- `spec/SHIPPED.md` contains detailed feature entries
- Format includes: date, branch, commit, summary, key changes, validation, success metrics, PR links
- Written by `/ship` command
- Read by `/plan` command for archive detection
- Referenced in workflow documentation

### Problem
- **Non-conventional name**: Developers expect `CHANGELOG.md`, not `SHIPPED.md`
- **Non-conventional location**: Changelogs belong at repository root (`./CHANGELOG.md`), not in `spec/`
- **Poor discoverability**: Contributors won't know to look in `spec/SHIPPED.md`
- **Tool integration**: GitHub release automation, changelog aggregators, and other tools expect `./CHANGELOG.md`
- **Convention matters**: Using standard names/locations reduces cognitive load

### Desired State
- `./CHANGELOG.md` at repository root (industry standard)
- Same detailed format (don't dumb it down - the metrics are valuable)
- Add version markers at release time (group by version)
- `/ship` writes to `./CHANGELOG.md`
- `/plan` reads from `./CHANGELOG.md` for archive detection
- All documentation updated to reference CHANGELOG.md

## Technical Requirements

### 1. Rename and Move
- Move `spec/SHIPPED.md` → `./CHANGELOG.md`
- Preserve all existing entries
- Add header explaining format (Keep a Changelog inspired, but more detailed)

### 2. Update /ship Command
Current (from commands/ship.md or scripts/ship.sh):
```bash
# Update spec/SHIPPED.md
```

New:
```bash
# Update ./CHANGELOG.md
```

### 3. Update /plan Archive Detection
Current:
```bash
# Check spec/SHIPPED.md for shipped features
```

New:
```bash
# Check ./CHANGELOG.md for shipped features
```

### 4. Add Changelog Header
Add to `./CHANGELOG.md`:
```markdown
# Changelog

All notable changes to this project will be documented in this file.

This changelog follows a detailed format optimized for developer tools:
- **Success metrics**: Actual results achieved (e.g., 16/16 metrics met)
- **Validation**: What tests/checks passed
- **Key changes**: Implementation details
- **PR links**: Full context for reviewers

For standard changelog format, see [Keep a Changelog](https://keepachangelog.com/).

---
```

### 5. Update Documentation References

**Files to update**:
- `spec/README.md` - Multiple references to SHIPPED.md
- `templates/README.md` - Quick Start mentions SHIPPED.md
- `commands/*.md` - /ship, /plan references
- Any other docs mentioning SHIPPED.md

**Find all references**:
```bash
grep -r "SHIPPED.md" . --include="*.md" --include="*.sh"
```

### 6. Version Markers (Future)
Document that at release time, add version headers:
```markdown
## v1.3.0 - 2025-10-15

### Feature entries here...

## v1.2.0 - 2025-10-14

### Feature entries here...
```

## Rationale

### Why CHANGELOG.md is Better Than SHIPPED.md

**1. Industry Convention**
- Every developer knows `./CHANGELOG.md` exists
- GitHub auto-detects it for releases
- Tools expect it (changelog aggregators, release automation)
- Reduces cognitive load (don't learn CSW-specific names)

**2. Discoverability**
- First place people look: root directory
- Standard filenames are easier to find
- Better for onboarding contributors

**3. Tool Integration**
- GitHub release notes can auto-link
- Changelog parsing tools work out of box
- CI/CD release automation expects it
- Package managers look for it

**4. SEO and Documentation**
- Search engines index standard filenames better
- Documentation tools recognize CHANGELOG.md
- Easier to reference in external docs

### Why Keep the Detailed Format

Most changelogs are too vague:
```markdown
## v1.3.0
### Added
- Bootstrap feature
```

CSW's detailed format is **better**:
```markdown
## v1.3.0

### Onboarding Bootstrap - Auto-Generate Bootstrap Spec
- **Date**: 2025-10-14
- **Summary**: Automatically create bootstrap validation spec
- **Key Changes**:
  - Created templates/bootstrap-spec.md
  - Added stack detection functions
- **Validation**: ✅ All checks passed
- **Success Metrics**: 100% (16/16)
- **PR**: #10
```

This gives developers:
- Exact dates (not just version)
- What actually changed (implementation details)
- Success metrics (was it complete?)
- Validation status (can I trust it?)
- PR links (full context)

**Don't dumb it down** - the detail is valuable for a developer tool.

### Why Root Location

CSW already writes to repository root:
- Git commits (via `/ship`)
- .gitignore updates (via `init-project.sh`)
- PR creation (GitHub API)

There's no reason to isolate the changelog in `spec/`. It's **infrastructure metadata** - it belongs at root alongside README.md, LICENSE, .gitignore, etc.

## Validation Criteria

### Functional
- [ ] `./CHANGELOG.md` exists at repository root
- [ ] All entries from `spec/SHIPPED.md` migrated
- [ ] `/ship` command writes to `./CHANGELOG.md`
- [ ] `/plan` command reads from `./CHANGELOG.md` for archive detection
- [ ] No broken references to SHIPPED.md in code
- [ ] No broken references to SHIPPED.md in documentation

### Documentation
- [ ] `spec/README.md` updated (all SHIPPED.md → CHANGELOG.md)
- [ ] `templates/README.md` updated (Quick Start references)
- [ ] Command documentation updated (/ship, /plan)
- [ ] CHANGELOG.md header explains detailed format

### User Experience
- [ ] Contributors immediately find changelog at root
- [ ] Format remains detailed and valuable
- [ ] No confusion about where to find release history
- [ ] GitHub release pages can link to CHANGELOG.md

## Success Metrics

### Quantitative
- [ ] Zero references to SHIPPED.md remain in codebase
- [ ] `./CHANGELOG.md` exists and validates (markdown linting)
- [ ] All historical entries preserved (entry count matches)
- [ ] Archive workflow still works (test with next /plan)

### Qualitative
- [ ] Changelog is discoverable (ask new contributor where to find release history)
- [ ] GitHub release pages show better integration
- [ ] Contributors recognize standard conventions

## Edge Cases & Considerations

### Project Already Has ./CHANGELOG.md
**Scenario**: User already created their own CHANGELOG.md before this change
**Response**: Detect conflict, prompt user:
```
⚠️  ./CHANGELOG.md already exists. CSW wants to manage this file.
   Backup: ./CHANGELOG.md.backup
   Merge entries? (y/n)
```

### Monorepo Usage
**Scenario**: CSW used in monorepo with multiple packages
**Response**: Document that CHANGELOG.md should be at repo root (tracks CSW infrastructure changes), each package can have its own changelog for package releases.

### Git History References
**Scenario**: Old commits reference spec/SHIPPED.md
**Response**: No action needed. Git history is immutable. Old commits will reference old path. Documentation notes the change.

### Backward Compatibility
**Scenario**: Should we support both names during transition?
**Response**: No. Clean cut is better. Migration script handles the one-time move.

## Implementation Notes

**Order of Operations**:
1. Find all SHIPPED.md references (grep)
2. Update /ship command to write CHANGELOG.md
3. Update /plan command to read CHANGELOG.md
4. Update all documentation references
5. Move spec/SHIPPED.md → ./CHANGELOG.md (preserve entries)
6. Add changelog header
7. Test archive detection with next /plan

**Migration Script** (optional):
```bash
# scripts/migrate-to-changelog.sh
# 1. Move spec/SHIPPED.md → ./CHANGELOG.md
# 2. Add header
# 3. Update all references
# 4. Commit with: "refactor: adopt CHANGELOG.md convention"
```

**Testing**:
- [ ] Run `/ship` on test feature - verify writes to ./CHANGELOG.md
- [ ] Run `/plan` on new feature - verify reads ./CHANGELOG.md for archive detection
- [ ] Verify all markdown links work
- [ ] Check GitHub release page integration

## Open Questions

**Q: Should we support both spec/SHIPPED.md and ./CHANGELOG.md during transition?**
A: No. Clean migration is better. One-time breaking change is acceptable for an alpha-stage tool.

**Q: Should we add version markers to existing entries?**
A: Not immediately. Document that version markers should be added at release time. Existing entries remain chronological.

**Q: What about tools that generate CHANGELOG.md automatically?**
A: CSW *is* the tool generating CHANGELOG.md (via /ship). This is the source of truth, not generated from commits.

**Q: Keep detailed format or adopt Keep a Changelog exactly?**
A: Keep detailed format. It's better. Just add a header explaining it's Keep a Changelog "inspired" but more detailed for developer tools.
