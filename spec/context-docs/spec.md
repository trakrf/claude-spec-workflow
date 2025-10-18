# Spec: WHAT vs HOW Documentation & Context Management

## Metadata
**Type**: documentation
**Complexity**: low
**Estimated Tasks**: 4-5
**Closes**: https://github.com/trakrf/claude-spec-workflow/issues/23

## Overview
Improve documentation clarity around:
1. **WHAT vs HOW**: The fundamental distinction between spec.md (outcomes) and plan.md (implementation)
2. **Command purposes**: What each workflow command accomplishes
3. **Context management**: When to /clear between stages
4. **Optional /check**: When to skip /check in rapid flow

## Background

### Issue #23: WHAT vs HOW Confusion
Users may not clearly understand the distinction between:
- **spec.md**: Concise description of WHAT you want (requirements, goals, constraints)
- **plan.md**: Detailed description of HOW to build it (implementation steps, technical approach)

This fundamental distinction isn't prominently documented.

### Context Management Confusion
Users may not understand:
- When to `/clear` between workflow stages
- Whether `/check` is mandatory or optional
- That `/build` already validates everything before committing
- That `/ship` runs `/check` automatically

These gaps lead to:
- Uncertainty about the workflow
- Unnecessary redundant validation runs (slower workflow)
- Confusion about when to edit spec vs plan

## Requirements

### 1. Enhance Command Table in Root README.md (Issue #23)

**Location**: Lines 239-248

Expand the command table to clarify WHAT vs HOW using the restaurant analogy:

| Command | What It Does | When to Use |
|---------|--------------|-------------|
| `/spec` | **Define WHAT** - Pull together explorations into clear outcomes (the dish on the menu) | After exploring bugs, reading tickets, or discussing ideas |
| `/plan` | **Define HOW** - Create the recipe to achieve the outcome | When you have a clear WHAT in spec.md |
| `/build` | **Execute** - Follow the recipe to write the code | After plan is approved |
| `/check` | **Validate** - Verify result meets success criteria (optional) | For detailed report or pre-ship audit |
| `/ship` | **Finalize** - Commit, push, create PR (runs /check automatically) | When ready to merge |
| `/cleanup` | **Reset** - Clean up shipped work for next cycle | After merging PR (optional) |

### 2. Add WHAT vs HOW Explanation to spec/template.md (Issue #23)

**Location**: Top of spec/template.md

Add explanatory comments:
```markdown
<!--
# spec.md - WHAT to Build

This file describes WHAT you want to achieve:
- User-facing goals and outcomes
- Business requirements and constraints
- Success criteria

Keep this concise and focused on outcomes, not implementation details.
The /plan command will generate plan.md with HOW to implement this spec.
-->
```

### 3. New Section in Root README.md: "Optimizing Command Flow"

**Location**: After "Workflow Philosophy" section (after line 309)

**Content:**

#### Subsection: "When to Clear Context"
Explain that CSW commands read from disk artifacts (spec.md, plan.md, etc.) which enables resumable workflows and clear contracts.

Show context management between stages:
- Keep context: /spec → /plan (natural flow from exploration)
- Clear context: /plan → /build (plan.md is complete contract)
- Clear context: /build → /check (independent review)
- Clear context: /check → /ship (mechanical operation)

#### Subsection: "When to Skip /check"
Explain that:
- /build validates everything before committing (lint, types, tests, build)
- /ship runs /check automatically before creating PR
- In rapid flow: /build → /ship is safe
- /check is optional but provides detailed report

List when to run /check explicitly:
- Want detailed readiness report
- Time passed since /build
- Manual edits after /build
- Someone else reviewing your work

Bottom line: Trust /build's validation, skip /check in rapid flow unless you want the report.

**Length**: ~40 lines (proportional to existing content)

### 4. Update spec/README.md Command Table (Optional Enhancement)

**Location**: Lines 103-110

Clarify that /check is optional and /build validates continuously:

| Command | Purpose | Notes |
|---------|---------|-------|
| `/plan` | Generate implementation plan | Auto-detects spec or accepts fragment |
| `/build` | Execute implementation | Validates continuously, full suite at end |
| `/check` | Validate PR readiness (optional) | /ship runs this automatically |
| `/ship` | Complete and ship | Creates PR, runs /check first |

### Constraints
- Keep additions concise and proportional to existing content
- Match existing README tone (practical, opinionated)
- Use same formatting style as existing sections
- Don't bloat command context - this is for humans optimizing workflow
- Explanatory comments should be HTML comments (not visible in rendered markdown)

## Success Metrics

### Issue #23 Acceptance Criteria
- ✅ spec/template.md includes WHAT vs HOW explanation
- ✅ README.md command table clarifies WHAT vs HOW distinction
- ✅ Users understand when to edit spec vs plan

### Additional Success Criteria
- ✅ "Optimizing Command Flow" section added to README.md
- ✅ Command tables enhanced in both README.md and spec/README.md
- ✅ Context management guidance is clear and actionable
- ✅ /check optional nature is documented
- ✅ All formatting matches existing README style
- ✅ Markdown renders correctly

## Examples

### Existing README Sections (Style Reference)
- "Workflow Philosophy" (lines 304-309) - brief, opinionated
- "Complexity Assessment & Scope Protection" (lines 311-430) - detailed guide
- "Feature Lifecycle" (lines 250-286) - shows workflow flow
- "Commands" table (lines 239-248) - current format to enhance

### Files to Modify
1. **README.md** - Root documentation (2 changes)
   - Command table (lines 239-248)
   - New "Optimizing Command Flow" section (after line 309)
2. **spec/template.md** - Template for new specs (1 change)
   - Add WHAT vs HOW explanation at top
3. **spec/README.md** - Workflow documentation (1 change)
   - Command table (lines 103-110)

## Validation
- All markdown files render correctly in GitHub
- No broken links or formatting issues
- HTML comments in template.md are not visible when rendered
- Tables display properly
- Sections are proportional to existing content
- Issue #23 acceptance criteria all met
