# Implementation Plan: Optimize SHIPPED.md Workflow
Generated: 2025-10-15
Specification: spec.md

## Understanding

The current `/ship` command creates two commits for SHIPPED.md updates: first with "PR: pending", then updating with the actual PR URL after creation. This creates noise in git history and is inefficient.

The goal is to reorder the workflow steps so that:
1. Branch is pushed first (before any SHIPPED.md changes)
2. PR is created and URL captured
3. SHIPPED.md is updated once with complete information (commit + PR URL)

**Key clarifications from user**:
- Keep full PR URL in SHIPPED.md (no parsing needed)
- Format as separate lines (not combined with `|`)
- If PR creation fails, halt with error (fail fast principle)
- Add CONTRIBUTING.md note about install.sh + restart workflow for command changes
- Test via dogfooding (ship this very feature with new workflow)

## Relevant Files

**Files to Modify**:
- `commands/ship.md` (lines ~165-250) - Reorder workflow steps 7-9, update SHIPPED.md template, update commit message format
- `CONTRIBUTING.md` (after line 63 in Testing section) - Add note about command update workflow

**Reference Patterns**:
- `commands/ship.md` lines 165-192 - Current SHIPPED.md template format
- `commands/ship.md` lines 194-250 - Current PR creation workflow with Method 1-4
- `CONTRIBUTING.md` lines 24-63 - Testing Your Changes section

## Architecture Impact

- **Subsystems affected**: Ship workflow command prompt only
- **New dependencies**: None
- **Breaking changes**: None (internal workflow optimization, users see cleaner result)

## Task Breakdown

### Task 1: Update Step 7 - Push Branch First
**File**: commands/ship.md
**Action**: MODIFY
**Lines**: ~194-195 (current Step 8)

**Implementation**:
Move "Push Branch" to become Step 7, before SHIPPED.md update.

Change:
```markdown
8. **Push Branch**
   Push to remote with git push -u origin.
```

To:
```markdown
7. **Push Branch**
   Push feature branch to remote with git push -u origin.

   Note: We push before updating SHIPPED.md so the branch exists when creating PR.
```

**Validation**: Lint (shellcheck), visual review of command prompt

---

### Task 2: Update Step 8 - Create PR and Capture URL
**File**: commands/ship.md
**Action**: MODIFY
**Lines**: ~197-250 (current Step 9)

**Implementation**:
Move "Create Pull Request" to become Step 8, keeping all Method 1-4 logic.

Change from:
```markdown
9. **Create Pull Request**
```

To:
```markdown
8. **Create Pull Request**

   Try authentication methods in order until one succeeds:
   [Keep all existing Method 1-4 logic]
```

**Critical change**: In the success blocks for Methods 1-3, REMOVE the logic that updates SHIPPED.md immediately. That will now happen in Step 9.

Remove from each method's success block:
- "Update SHIPPED.md with PR URL"
- "Commit again"
- "Push again"
- "If successful: Update SHIPPED.md, display success, exit"

Instead, methods should:
- Capture PR URL/number
- Display success message
- Continue to Step 9

**Validation**: Lint (shellcheck), visual review of command prompt

---

### Task 3: Update Step 9 - Single SHIPPED.md Commit
**File**: commands/ship.md
**Action**: MODIFY
**Lines**: ~165-192 (current Step 7)

**Implementation**:
Move "Update Shipped Log" to become Step 9, after PR creation.

Change from:
```markdown
7. **Update Shipped Log**
   Create/append to `spec/SHIPPED.md`:
   [template]

   Commit SHIPPED.md update with git add and git commit.
```

To:
```markdown
9. **Update Shipped Log**

   After PR is created and URL is captured, create/append to `spec/SHIPPED.md` with complete information in a single commit.

   [Updated template - see Task 4]

   Commit with message: `docs: ship {feature-display-name} (#{pr-number})`

   Example: `docs: ship Optimize SHIPPED.md Workflow (#14)`

   Push the single SHIPPED.md commit: `git push`
```

**Note**: PR number can be extracted from URL: `https://github.com/user/repo/pull/13` → `#13`

**Validation**: Lint (shellcheck), visual review of command prompt

---

### Task 4: Update SHIPPED.md Template Format
**File**: commands/ship.md
**Action**: MODIFY
**Lines**: ~167-188

**Implementation**:
Update the SHIPPED.md template to use separate lines with full PR URL.

Change from:
```markdown
## {Feature Name}
- **Date**: {YYYY-MM-DD}
- **Branch**: feature/{name}
- **Commit**: {git rev-parse HEAD}
- **Summary**: {one-line description}
...
- **PR**: {pending|url}
```

To:
```markdown
## {Feature Name}
- **Date**: {YYYY-MM-DD}
- **Branch**: feature/{name}
- **Commit**: {git rev-parse --short HEAD}
- **PR**: {full-pr-url}
- **Summary**: {one-line description}
...
(rest of template unchanged)
```

**Technical details**:
- Use `git rev-parse --short HEAD` for short hash (typically 7 chars)
- PR comes right after Commit (related data together)
- Use full PR URL as-is (no parsing needed)
- Remove "pending" option (we only write SHIPPED.md after PR exists)

**Validation**: Visual review, dogfooding test

---

### Task 5: Update Method 4 Manual Fallback
**File**: commands/ship.md
**Action**: MODIFY
**Lines**: ~223-227

**Implementation**:
Update Method 4 to fail fast instead of leaving "PR: pending".

Change from:
```markdown
**Method 4: Manual fallback (last resort)**
- Show clear error message listing all methods tried
- Provide instructions for gh auth login or setting GH_TOKEN
- Suggest manual PR creation URL
- Leave SHIPPED.md with "PR: pending"
```

To:
```markdown
**Method 4: Manual fallback (halt on failure)**
- Show clear error message listing all methods tried
- Provide instructions for gh auth login or setting GH_TOKEN
- Provide the manual PR creation URL
- HALT execution with error
- Do NOT update SHIPPED.md (no incomplete entries)
- User must create PR manually, then can manually update SHIPPED.md if desired
```

**Rationale**: Fail fast principle - if PR creation fails, don't create incomplete SHIPPED.md entries.

**Validation**: Visual review of command prompt

---

### Task 6: Add CONTRIBUTING.md Command Update Note
**File**: CONTRIBUTING.md
**Action**: MODIFY
**Lines**: After line 63 (in "Testing Your Changes" section)

**Implementation**:
Add a new subsection about testing command changes.

Insert after the existing "Test commands manually" section:
```markdown
4. **After merging command changes**

   If you modify files in `commands/` (slash command prompts):

   ```bash
   # Re-run install to update global commands
   ./install.sh

   # Restart Claude Code to pick up changes
   # (Command palette > "Reload Window" or restart application)
   ```

   **Why**: Slash commands (`/plan`, `/build`, `/ship`, etc.) are installed globally in Claude's commands directory. Changes only take effect after reinstalling and restarting Claude Code.
```

**Validation**: Markdown lint, visual review

---

### Task 7: Dogfooding Test
**File**: N/A (testing task)
**Action**: TEST

**Implementation**:
Ship this very feature using the new workflow to validate:

1. Run `/ship spec/shipped-md-optimization/`
2. Verify behavior:
   - Step 7: Branch pushed before SHIPPED.md changes
   - Step 8: PR created and URL captured
   - Step 9: Single commit to SHIPPED.md with complete info
3. Check git log: Single commit with format `docs: ship {feature} (#{N})`
4. Check SHIPPED.md format:
   - Short commit hash used
   - Full PR URL on separate line after commit
   - PR comes right after commit (related data together)
5. Verify no "PR: pending" state created

**Expected result**: Clean git history with one commit, properly formatted SHIPPED.md entry.

**Validation**: Manual inspection of git log and SHIPPED.md

---

## Risk Assessment

**Risk**: PR creation fails after push (branch pushed but no SHIPPED.md entry)
**Mitigation**: This is actually better than current state - no incomplete "PR: pending" entry. Fail fast with clear error message. User can manually create PR and update SHIPPED.md if needed.

**Risk**: Forgetting to extract PR number from URL for commit message
**Mitigation**: Simple regex or string manipulation - `echo "$url" | grep -oP '\d+$'` or `basename "$url"`

**Risk**: Short hash collisions
**Mitigation**: Git default (7-8 chars) provides sufficient uniqueness. GitHub uses 7 char hashes by default.

**Risk**: Users forget to re-run install.sh after merging command changes
**Mitigation**: Adding explicit documentation to CONTRIBUTING.md

## Integration Points

- Commands: Only `commands/ship.md` workflow
- Documentation: CONTRIBUTING.md testing section
- Git workflow: Single commit replaces double-commit pattern

## VALIDATION GATES (MANDATORY)

**CRITICAL**: These are not suggestions - they are GATES that block progress.

After EVERY code change, use commands from `spec/stack.md`:
- Gate 1: Syntax & Style (Lint command: shellcheck for .sh files)
- Gate 2: Format check (Format command: shfmt if available)
- Gate 3: Syntax validation (Validate command: bash -n)

**Note**: This feature modifies markdown files (commands/ship.md, CONTRIBUTING.md), not shell scripts. Validation is primarily visual review and dogfooding test.

**Enforcement Rules**:
- Visual review: Check markdown formatting, step sequencing
- Dogfooding: Ship this feature with new workflow (Task 7)
- If dogfooding fails → Fix immediately and retry

**Do not proceed to next task until current task passes validation.**

## Validation Sequence

After each task:
- Visual review of markdown changes
- Lint check if modifying scripts

Final validation (Task 7):
- Dogfooding test: Ship this feature with new workflow
- Verify git log shows single commit
- Verify SHIPPED.md format correct
- Verify PR created successfully

## Plan Quality Assessment

**Complexity Score**: 2/10 (LOW - Well-scoped workflow reordering)

**Confidence Score**: 9/10 (HIGH)

**Confidence Factors**:
✅ Clear requirements from spec with user clarifications
✅ Found exact sections to modify (commands/ship.md lines 165-250)
✅ Similar pattern exists in current workflow (just reordering)
✅ Existing CONTRIBUTING.md structure to follow
✅ Simple markdown edits, no complex code changes
✅ Dogfooding test provides immediate validation
✅ No new dependencies or external integrations
✅ Architectural principle clear: prompts not scripts

**Assessment**: High confidence implementation. This is a straightforward workflow reordering with clear requirements. The main work is editing markdown documentation that describes workflow steps. User clarifications removed ambiguity (keep full URL, fail fast, separate lines). Dogfooding test will immediately reveal any issues.

**Estimated one-pass success probability**: 90%

**Reasoning**: Simple scope (6 markdown edits), clear requirements, immediate validation via dogfooding. The 10% uncertainty accounts for potential formatting issues or missed edge cases in PR creation logic that will be caught during dogfooding.
