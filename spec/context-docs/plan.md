# Implementation Plan: WHAT vs HOW Documentation & Context Management
Generated: 2025-10-18
Specification: spec.md
Closes: https://github.com/trakrf/claude-spec-workflow/issues/23

## Understanding

This plan addresses documentation improvements to clarify:
1. **WHAT vs HOW distinction**: spec.md describes desired outcomes, plan.md describes implementation approach
2. **Command purposes**: Each workflow command's role in the development cycle
3. **Context management**: When to use /clear between workflow stages
4. **Optional /check**: /build already validates everything; /ship runs /check automatically

The goal is to reduce user confusion about workflow mechanics and eliminate unnecessary redundant validation runs.

## Relevant Files

**Files to Modify**:
- `README.md` (lines 239-248, insert after 309) - Root project documentation
  - Update command table with clearer WHAT/HOW-informed descriptions
  - Add new "Optimizing Command Flow" section explaining context management and /check behavior

- `spec/template.md` (line 1) - Template for new feature specs
  - Add HTML comment explaining spec.md purpose (WHAT to build)

- `spec/README.md` (lines 103-110) - Workflow documentation
  - Update command table to clarify /check is optional and /build validates continuously

**Reference Patterns** (existing style to follow):
- `README.md` lines 304-309 - "Workflow Philosophy" section (brief, opinionated, 4 principles)
- `README.md` lines 311-430 - "Complexity Assessment" section (detailed guide with examples)
- `README.md` lines 250-286 - "Feature Lifecycle" section (workflow diagram with legend)

## Architecture Impact
- **Subsystems affected**: Documentation only
- **New dependencies**: None
- **Breaking changes**: None - purely additive documentation

## Task Breakdown

### Task 1: Update Root README.md Command Table
**File**: README.md
**Action**: MODIFY (lines 239-248)
**Pattern**: Follow existing table format, enhance descriptions

**Implementation**:
Replace existing command table with enhanced version that clarifies WHAT vs HOW:

```markdown
| Command | What It Does | When to Use |
|---------|--------------|-------------|
| `/spec` | **Define WHAT** - Gather requirements and desired outcomes | After exploring bugs, reading tickets, or discussing ideas |
| `/plan` | **Define HOW** - Generate detailed implementation approach | When you have clear requirements in spec.md |
| `/build` | **Execute** - Implement the plan with continuous validation | After reviewing and approving the plan |
| `/check` | **Validate** - Comprehensive pre-ship audit (optional) | For detailed readiness report or pre-ship review |
| `/ship` | **Finalize** - Commit, push, create PR (runs /check automatically) | When ready to merge |
| `/cleanup` | **Reset** - Clean up shipped work for next feature | After merging PR (optional solo dev workflow) |
```

**Validation**:
- Table renders correctly in markdown
- Columns align properly
- Descriptions are clear and concise

### Task 2: Add HTML Comment to spec/template.md
**File**: spec/template.md
**Action**: MODIFY (insert at line 1)
**Pattern**: Use HTML comment syntax (invisible when rendered)

**Implementation**:
Add at the very top of the file, before the "# Feature: [Name]" title:

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

**Validation**:
- HTML comment is NOT visible when markdown is rendered (test in GitHub preview)
- Comment IS visible when editing the file
- Proper newline spacing before the title

### Task 3: Add "Optimizing Command Flow" Section to Root README.md
**File**: README.md
**Action**: MODIFY (insert after line 309)
**Pattern**: Follow "Workflow Philosophy" section style - practical, opinionated

**Implementation**:
Insert new section between "Workflow Philosophy" (line 309) and "Complexity Assessment & Scope Protection" (line 311):

```markdown
## Optimizing Command Flow

### Understanding the Contract Model

CSW commands read from disk artifacts (spec.md, plan.md, etc.) which enables:
- **Resumable workflows** - Pick up hours or days later
- **Clear contracts** - Each stage produces a complete artifact for the next
- **Team collaboration** - Multiple people can work on different stages

### When to Clear Context

Each workflow stage has different context requirements:

| Transition | Context Strategy | Why |
|------------|------------------|-----|
| /spec → /plan | **Keep context** | Natural flow from exploration to planning |
| /plan → /build | **Clear context** | plan.md is complete contract; tests completeness |
| /build → /check | **Clear context** | Independent review with fresh perspective |
| /check → /ship | **Clear context** | Mechanical operation from artifacts |

**Rapid flow example**:
```bash
# Exploration and specification
/spec my-feature

# Planning (keeps context from /spec conversation)
/plan

# Clear context, build from plan.md
/clear
/build

# Skip /check, go straight to ship (it re-validates anyway)
/ship
```

### When to Skip /check

**/build already validates everything** before allowing commits:
- Lint must be clean
- Types must be correct
- Tests must pass
- Build must succeed

**/ship runs /check automatically** before creating PR, so in rapid flow you can safely skip it.

**Run /check explicitly when:**
- You want a detailed readiness report before deciding to ship
- Time has passed since /build (hours/days)
- You made manual edits after /build completed
- Someone else is reviewing your work

**Bottom line**: Trust /build's validation. In rapid flow, skip /check and go straight to /ship - it will re-validate everything anyway.
```

**Validation**:
- Section renders correctly with proper formatting
- Table displays properly
- Code block renders correctly
- Length is proportional to existing sections (~50 lines)

### Task 4: Update spec/README.md Command Table
**File**: spec/README.md
**Action**: MODIFY (lines 103-110)
**Pattern**: Keep concise (this is read by command prompts)

**Implementation**:
Replace existing command table with version that clarifies /check is optional:

```markdown
| Command | Purpose | Notes |
|---------|---------|-------|
| `/plan` | Generate implementation plan | Auto-detects spec or accepts fragment |
| `/build` | Execute implementation | Validates continuously; full suite at end |
| `/check` | Validate PR readiness (optional) | /ship runs this automatically |
| `/ship` | Complete and ship | Creates PR; runs /check first |
```

**Validation**:
- Table renders correctly
- Notes column provides helpful clarification
- Concise enough for command context consumption

## Risk Assessment

**Risk**: Documentation changes might conflict with in-progress work
**Mitigation**: These are documentation-only changes; no code impact

**Risk**: Markdown formatting issues (tables, HTML comments)
**Mitigation**: Preview all changes in markdown renderer before committing; test HTML comment invisibility

**Risk**: New section might be too verbose for README
**Mitigation**: Keep to ~50 lines; follow existing section styles (Philosophy is brief, Complexity Assessment is detailed)

## Integration Points

No code integration required - documentation only.

## VALIDATION GATES (MANDATORY)

Since this is documentation work, validation is different from code:

**After EACH task**:
1. Preview markdown rendering (README.md, spec/template.md, spec/README.md)
2. Verify tables display correctly
3. Verify HTML comment in template.md is invisible when rendered
4. Check for broken links or formatting issues

**Final validation**:
1. Render all three files in GitHub markdown preview
2. Verify consistent formatting across all changes
3. Verify proportionality (new section isn't overwhelming)
4. Check that Issue #23 acceptance criteria are met

## Validation Sequence

No lint/typecheck/test/build commands needed for pure documentation.

Validation is visual/functional:
- Markdown renders correctly
- Tables align properly
- HTML comments invisible when rendered
- Links work (if any added)

## Plan Quality Assessment

**Complexity Score**: 2/10 (LOW)
**Confidence Score**: 9/10 (HIGH)

**Confidence Factors**:
✅ Clear requirements from detailed spec
✅ Similar patterns exist in README (sections 304-430)
✅ All clarifying questions answered
✅ Pure documentation - no code complexity
✅ Straightforward markdown editing
✅ No external dependencies or integration

**Assessment**: Very high confidence - straightforward documentation enhancements following established patterns.

**Estimated one-pass success probability**: 95%

**Reasoning**: This is pure markdown editing following clear requirements and existing style patterns. The only risk is minor formatting issues which are easily caught and fixed during preview validation.
