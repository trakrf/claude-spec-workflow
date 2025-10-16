# Implementation Plan: Fix Output Formatting Across All Workflow Commands
Generated: 2025-10-16
Specification: spec.md

## Understanding

The workflow commands (`/plan`, `/check`, `/build`, `/ship`) are rendering list items without proper line breaks, concatenating them into unreadable walls of text. The issue is not in the source files (which are correctly formatted), but in the AI's rendering behavior when displaying output to users.

The fix adds explicit "OUTPUT FORMATTING RULES" sections to each command file with clear examples showing correct vs incorrect formatting. This guides the AI to preserve line breaks when rendering lists.

## Relevant Files

**Files to Modify**:
- `commands/plan.md` (line 238) - Add formatting rules before "Example ONE-AT-A-TIME flow"
- `commands/check.md` (line 223) - Add formatting rules before "## Output Format"
- `commands/build.md` (line 251) - Add formatting rules before "## Output Format"
- `commands/ship.md` (line 279) - Add formatting rules before "## Output Format"

**Reference Patterns** (existing usage to follow):
- `commands/*.md` (various) - Already use `---` separators (16 occurrences across 6 files)
- `commands/plan.md` (lines 238-275) - Examples already correctly formatted in source
- All commands use `**CRITICAL**` for emphasis on important directives

## Architecture Impact

- **Subsystems affected**: Documentation/Command specifications
- **New dependencies**: None
- **Breaking changes**: None (additive changes only)

## Task Breakdown

### Task 1: Add formatting rules to commands/plan.md
**File**: commands/plan.md
**Action**: MODIFY
**Pattern**: Insert new section before line 238

**Implementation**:
Insert before line 238 ("**Example ONE-AT-A-TIME flow**:"):

```markdown
---
## OUTPUT FORMATTING RULES

**CRITICAL**: When displaying clarifying questions with multiple choice options, each choice MUST appear on its own line. Do NOT concatenate choices together.

✅ CORRECT:
   a) First option
   b) Second option
   c) Third option

❌ WRONG:
   a) First optionb) Second optionc) Third option

This applies to ALL multiple choice questions. Preserve line breaks exactly as shown in the examples below.
---

```

**Validation**:
- Read the modified section in context to ensure it flows naturally
- Verify the tone matches the surrounding content (Senior Software Architect persona)
- Check that `---` separators align with existing separator usage in the file

### Task 2: Add formatting rules to commands/check.md
**File**: commands/check.md
**Action**: MODIFY
**Pattern**: Insert new section before line 223

**Implementation**:
Insert before line 223 ("## Output Format"):

```markdown
---
## OUTPUT FORMATTING RULES

**CRITICAL**: When displaying validation results and check summaries, each checkmark item MUST appear on its own line. Do NOT concatenate items together.

✅ CORRECT:
   ✅ Feature validation: 7/7 tasks complete
   ✅ Code quality: Clean (no issues)
   ✅ Git status: On feature branch, 1 commit ahead
   ✅ Ready to ship: YES

❌ WRONG:
   ✅ Feature validation: 7/7 tasks complete✅ Code quality: Clean (no issues)✅ Git status: On feature branch, 1 commit ahead✅ Ready to ship: YES

This applies to ALL output examples below. Each line in tables, lists, and summaries must be rendered on its own line.
---

```

**Validation**:
- Read the modified section in context
- Verify tone matches Senior Test Engineer persona
- Check separator consistency

### Task 3: Add formatting rules to commands/build.md
**File**: commands/build.md
**Action**: MODIFY
**Pattern**: Insert new section before line 251

**Implementation**:
Insert before line 251 ("## Output Format"):

```markdown
---
## OUTPUT FORMATTING RULES

**CRITICAL**: When displaying task progress and build summaries, each status line MUST appear on its own line. Do NOT concatenate consecutive updates together.

✅ CORRECT:
   📝 Task 1/5: Setup database schema
   ✅ Implementation complete
   ✅ Validation passed
   💾 Progress saved to log.md

❌ WRONG:
   📝 Task 1/5: Setup database schema✅ Implementation complete✅ Validation passed💾 Progress saved to log.md

This applies to ALL output examples below. Preserve line breaks exactly as shown.
---

```

**Validation**:
- Read the modified section in context
- Verify tone matches Senior Software Engineer persona
- Check separator consistency

### Task 4: Add formatting rules to commands/ship.md
**File**: commands/ship.md
**Action**: MODIFY
**Pattern**: Insert new section before line 279

**Implementation**:
Insert before line 279 ("## Output Format"):

```markdown
---
## OUTPUT FORMATTING RULES

**CRITICAL**: When displaying ship summaries, PR information, and validation gates, each item MUST appear on its own line. Do NOT concatenate list items together.

✅ CORRECT:
   🌿 Git Status:
   - Branch: feature/auth
   - Commits: 3 ahead of main
   - Pushed to origin

❌ WRONG:
   🌿 Git Status:
   - Branch: feature/auth- Commits: 3 ahead of main- Pushed to origin

This applies to ALL output examples below, including validation gates, error messages, and success summaries. Preserve line breaks exactly as shown.
---

```

**Validation**:
- Read the modified section in context
- Verify tone matches Tech Lead persona
- Check separator consistency

### Task 5: Verify consistency across all commands
**Action**: REVIEW
**Pattern**: Cross-file consistency check

**Implementation**:
1. Read all 4 formatting rules sections in sequence
2. Verify structural consistency:
   - All use `---` separators
   - All use `## OUTPUT FORMATTING RULES` header
   - All use `**CRITICAL**:` emphasis
   - All show ✅ CORRECT and ❌ WRONG examples
   - All end with applicability statement
3. Verify customization appropriateness:
   - plan.md focuses on multiple choice options
   - check.md focuses on checkmark items in summaries
   - build.md focuses on task progress status lines
   - ship.md focuses on structured lists (git status, PR info, etc.)
4. Ensure no existing content was modified (additive only)

**Validation**:
- All 4 sections follow same structure
- Each section's examples match that command's output patterns
- Tone is appropriate for each command's persona
- No regressions in existing content

## Risk Assessment

- **Risk**: Formatting instructions might not be clear enough
  **Mitigation**: Using explicit ✅/❌ examples with visual comparison makes intent unmistakable

- **Risk**: AI might still ignore the instructions
  **Mitigation**: Separators and **CRITICAL** emphasis maximize visibility; positioned directly before output examples for immediate context

- **Risk**: Breaking existing command behavior
  **Mitigation**: Changes are purely additive (no existing content modified), easy to rollback

## Integration Points

- No integration points - pure documentation changes
- Commands will reference these rules when rendering output
- Changes take effect immediately when AI reads updated command files

## VALIDATION GATES (MANDATORY)

**CRITICAL**: These are not suggestions - they are GATES that block progress.

Since this is markdown documentation (not code), validation is primarily visual:
- Visual inspection: Read each modified section in full context
- Consistency check: Verify all 4 sections follow same pattern
- No syntax errors: Markdown renders correctly
- Additive only: No existing content was changed

**Note**: No lint/typecheck/test commands needed for markdown documentation files.

## Validation Sequence

After each task (1-4): Visual inspection of the modified file
After task 5: Cross-file consistency verification
Final: Read each command file completely to ensure natural flow

## Plan Quality Assessment

**Complexity Score**: 2/10 (LOW)
**Confidence Score**: 9/10 (HIGH)

**Confidence Factors**:
✅ Clear requirements from spec
✅ Line numbers verified to match actual files
✅ All clarifying questions answered
✅ Existing separator pattern identified (16 occurrences across files)
✅ Changes are additive only (low risk)
✅ No code execution required (documentation only)
✅ Easy to validate visually
✅ Easy to rollback if needed

**Assessment**: This is a straightforward documentation update with clear requirements, verified insertion points, and established patterns to follow.

**Estimated one-pass success probability**: 95%

**Reasoning**: The task is simple (insert text at specific locations), the insertion points are verified, the pattern is consistent with existing usage, and the changes are additive. The only reason it's not 100% is the possibility of minor tone adjustments needed when reading in full context.
