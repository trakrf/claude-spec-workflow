# Fix Output Formatting Across All Workflow Commands

## Problem

Multiple commands are rendering list items without proper line breaks, concatenating them together into a wall of text.

### Issue 1: /plan Clarifying Questions

When `/plan` displays clarifying questions with multiple choice options, the choices are rendered without line breaks between them, making them difficult to read.

### Current Output
```
Question 2/5: What's the validation approach?
  a) Execute validation commands - Run lint, typecheck, test, build to prove they workb) Check commands exist -
  Verify the commands are defined but don't run themc) Execute only non-destructive - Run lint/typecheck but skip
  test/build (faster)
```

All three choices are concatenated together without line breaks, making them run together into a wall of text that's hard to parse visually.

### Expected Output
```
Question 2/5: What's the validation approach?
  a) Execute validation commands - Run lint, typecheck, test, build to prove they work
  b) Check commands exist - Verify the commands are defined but don't run them
  c) Execute only non-destructive - Run lint/typecheck but skip test/build (faster)
```

Each choice must appear on its own line (with a line break after each one, but no blank lines between them).

---

### Issue 2: /check Summary Output

When `/check` displays the pre-release check summary, the checkmark items are concatenated together without line breaks.

### Current Output
```
  🔍 Pre-Release Check Complete

  ✅ Feature validation: 7/7 tasks complete✅ Code quality: Clean (no issues)✅ Git status: On feature branch, 1
  commit ahead✅ Ready to ship: YES
```

All checkmark items run together without line breaks, making the summary hard to read.

### Expected Output
```
  🔍 Pre-Release Check Complete

  ✅ Feature validation: 7/7 tasks complete
  ✅ Code quality: Clean (no issues)
  ✅ Git status: On feature branch, 1 commit ahead
  ✅ Ready to ship: YES
```

Each checkmark item must appear on its own line (with a line break after each one, but no blank lines between them).

---

## Root Cause

The command specifications contain correctly-formatted output examples in their source files (each list item on its own line). However, when the AI renders these examples to the user, it's concatenating consecutive lines together without preserving line breaks. This is a rendering behavior issue, not a source formatting issue.

## Solution

Add explicit formatting instructions to ALL command files that have multi-line output examples. This clarifies that the AI must preserve line breaks when rendering lists to the user.

### General Principle

Add a **CRITICAL FORMATTING** section to each command file that contains output examples with lists. This section should appear before the output format examples and provide clear instructions about preserving line breaks.

### Files to Modify

Based on comprehensive scan of all command files, the following need formatting instructions:

**1. commands/plan.md** (lines 238-275)
- Location: Before "Example ONE-AT-A-TIME flow" section (around line 238)
- Affected output: Multiple choice question options (a), b), c))

**2. commands/check.md** (lines 224-235)
- Location: Before "Output Format" section (around line 223)
- Affected output: Checkmark items (✅) in Pre-Release Check summary

**3. commands/build.md** (lines 251-266)
- Location: Before "Output Format" section (around line 251)
- Affected output: Task progress messages and build summary checkmarks

**4. commands/ship.md** (lines 279-323)
- Location: Before "Output Format" section (around line 279)
- Affected output: Multiple sections with checkmarks, bullet points, and structured lists

### Formatting Instruction Template

Add this section to each affected command file BEFORE any output format examples. Customize the examples based on the specific output patterns in that file.

#### Generic Template
```markdown
---
## OUTPUT FORMATTING RULES

**CRITICAL**: When rendering output to the user, you MUST preserve line breaks in all list items.

**DO NOT concatenate consecutive lines together.**

Each list item (whether prefixed with ✅, ❌, a), -, or any other marker) MUST appear on its own line.

✅ CORRECT:
   ✅ First item
   ✅ Second item
   ✅ Third item

❌ WRONG:
   ✅ First item✅ Second item✅ Third item

This applies to ALL output examples below. Preserve line breaks exactly as shown in the examples.
---
```

### File-Specific Changes

#### 1. commands/plan.md

**Location**: Insert before line 238 (before "**Example ONE-AT-A-TIME flow**")

**Custom formatting instruction**:
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

#### 2. commands/check.md

**Location**: Insert before line 224 (before "## Output Format")

**Custom formatting instruction**:
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

#### 3. commands/build.md

**Location**: Insert before line 252 (before "## Output Format")

**Custom formatting instruction**:
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

#### 4. commands/ship.md

**Location**: Insert before line 280 (before "## Output Format")

**Custom formatting instruction**:
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

## Validation

After applying the changes to all 4 command files:

1. **Visual inspection**: Review each updated command file to confirm formatting instructions are present and clear
2. **Test /plan**: Run `/plan` command and verify clarifying questions display each choice on its own line
3. **Test /check**: Run `/check` command and verify checkmark items each appear on their own line
4. **Test /build**: Run `/build` command and verify task progress messages appear on separate lines
5. **Test /ship**: Run `/ship` command and verify all lists (git status, validation gates, etc.) render properly
6. **Cross-command consistency**: Confirm all commands follow the same formatting rules

## Success Criteria

- [ ] Formatting instruction added to `commands/plan.md` before line 238
- [ ] Formatting instruction added to `commands/check.md` before line 224
- [ ] Formatting instruction added to `commands/build.md` before line 252
- [ ] Formatting instruction added to `commands/ship.md` before line 280
- [ ] All formatting instructions follow consistent structure and clarity
- [ ] When running any command, list items display on separate lines (no concatenation)
- [ ] Line breaks are preserved (but no extra blank lines added between items)
- [ ] The fix is comprehensive across all workflow commands

## Impact Assessment

**Commands affected**: 4 (plan, check, build, ship)
**User experience improvement**: Significant - all multi-line output will be readable
**Risk**: Low - adding documentation/instructions only, no code changes
**Testing effort**: Moderate - need to test all 4 commands

## Notes

- This is a documentation/specification fix - the actual rendering behavior depends on how the AI interprets the instructions
- The output examples in the source files are already correctly formatted; the issue is the AI's rendering behavior
- Each list item should be on its own line with a line break after it (but no blank lines between items)
- Commands not affected: `cleanup.md` and `spec.md` (no multi-line list outputs)
- This is a systematic fix that prevents the same issue from occurring in any command output
