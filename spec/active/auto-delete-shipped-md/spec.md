# Feature: Auto-Delete Retired SHIPPED.md

## Origin
User feedback: "We don't have any real users yet, so just delete it and let it slip away into history."

## Outcome
Remove interactive confirmation prompt for SHIPPED.md deletion. Just delete it automatically during cleanup.

## User Story
As a developer using claude-spec-workflow
I want SHIPPED.md to be deleted automatically during cleanup
So that I don't have to answer prompts for files that are already retired

## Context

**Current State**:
- `scripts/cleanup.sh` has interactive `read -p "Delete spec/SHIPPED.md? (y/n)"` prompt
- `commands/cleanup.md` documents this interactive behavior
- Interactive prompts don't work well with Claude Code automation

**Desired State**:
- Auto-delete SHIPPED.md if it exists (no prompt)
- Simple info message: "Removed retired SHIPPED.md (preserved in git history)"
- Update docs to reflect automatic deletion

## Technical Requirements

1. **Update `scripts/cleanup.sh`**: Remove interactive prompt, just delete if exists
2. **Update `commands/cleanup.md`**: Remove mention of confirmation prompt
3. **Update `CHANGELOG.md`**: Add version 0.4.0 entry documenting the change
4. **Rationale**: Anyone who cares will see it in changelog, not surprised by behavior change

## Validation Criteria

- [ ] No interactive prompts in cleanup script
- [ ] SHIPPED.md deleted automatically if present
- [ ] Info message confirms deletion
- [ ] Documentation updated
- [ ] Version bumped to 0.4.0 in CHANGELOG.md
- [ ] Change documented in changelog

## Success Metrics

**Simplicity**: Zero interactive prompts for retired files
**Speed**: Cleanup runs without user intervention
**Transparency**: Change documented in changelog for anyone who cares
