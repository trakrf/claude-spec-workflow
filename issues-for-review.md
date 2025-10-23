# CSW Issues for GitHub - Review Draft

Generated: 2025-10-17

This document organizes issues discovered during dogfooding CSW on the trakrf/platform project.

---

## 🐛 High Priority Bugs

### Issue 1: Line Breaks Missing in Command Output

**Title:** Fix missing line breaks in /plan, /check, and /ship command outputs

**Description:**
Multiple commands have "OUTPUT FORMATTING RULES" sections that explicitly specify line breaks between list items, but these rules are being inconsistently followed.

**Example:**
The commands show:
```
✅ CORRECT:
   a) First option
   b) Second option
   c) Third option

❌ WRONG:
   a) First optionb) Second optionc) Third option
```

But output is sometimes concatenating items without line breaks.

**Locations to check:**
- `.claude/commands/plan.md`
- `.claude/commands/check.md`
- `.claude/commands/ship.md`

**Observed instances:**
- Clarifying questions in /plan showing concatenated options
- /ship success notice: `Ship Date: 2025-10-15Spec Location: spec/active/...`

**Acceptance Criteria:**
- [ ] All list items in command outputs have proper line breaks
- [ ] Clarifying questions display one option per line
- [ ] Ship success notices have proper line breaks between fields
- [ ] Consider making formatting rules more prominent/earlier in prompts

**Labels:** bug, ux, commands

---

### Issue 2: /cleanup has race condition with GitHub merge timing

**Title:** /cleanup fails to detect merged branches due to stale git refs

**Description:**
When running `/cleanup` immediately after merging a PR via GitHub UI, the command doesn't detect the merge because local git refs are stale.

**The Problem Timeline:**
1. T+0s: User merges PR via GitHub UI
2. T+2s: GitHub processes merge, deletes remote branch
3. T+3s: User runs `/cleanup` locally
4. ❌ Local git doesn't know about merge yet

**Current cleanup flow:**
```bash
1. Checkout main          # Uses stale local tracking
2. git pull              # Updates main branch only
3. Check merged branches  # Still uses stale refs!
```

The issue: `git pull` only updates the current branch (main). It doesn't refresh knowledge about:
- Which remote branches were deleted
- Which branches were merged
- Latest commits on other branches

**Proposed Fix:**
Add `git fetch --prune origin` at the start of cleanup script:

```bash
1. git fetch --prune origin    # ← NEW: Sync ALL remote refs
2. Checkout main
3. git pull                    # Update main content
4. Check merged branches       # Now has fresh data!
```

**Acceptance Criteria:**
- [ ] /cleanup runs `git fetch --prune origin` before checking merged branches
- [ ] Command correctly detects recently merged branches
- [ ] Command correctly identifies deleted remote branches
- [ ] Test: merge PR, immediately run /cleanup, verify detection

**Labels:** bug, git, commands

---

## 🔧 Workflow Improvements

### Issue 3: /build should commit incrementally as tasks complete

**Title:** /build should create granular git commits for each completed task

**Description:**
Currently `/build` completes all implementation work but only commits at the end (or sometimes not at all). This creates issues:
- Large monolithic commits that are hard to review
- Lost work if build fails partway through
- No granular history showing implementation progression
- Difficult to identify which change caused issues

**Example observed:**
```
Last commit: 0eef7e8 plan: bootstrap implementation

After /build ran:
  1. ✅ Moved files from spec/active/csw-bootstrap/ → spec/bootstrap/
  2. ✅ Created spec/bootstrap/log.md showing 7/7 tasks complete
  3. ✅ Updated spec/README.md and spec/stack.md
  4. ❌ Did NOT commit these changes
```

**Proposed Solution:**
- /build should commit after completing each task in the plan
- Commit message format: `build(<feature>): <task-description>`
- Each commit is atomic and represents one logical change
- Work is always committed and recoverable

**Acceptance Criteria:**
- [ ] /build commits after each completed task
- [ ] Each commit has descriptive message tied to plan task
- [ ] Build log tracks which commits were created
- [ ] If build fails mid-way, completed work is committed
- [ ] Ready to ship when /build completes (all work committed)

**Benefits:**
- Granular history for debugging
- Better PR review experience
- Recovery from failures
- Immediate shippability

**Labels:** enhancement, workflow, git, commands

---

### Issue 4: Add /status command for workflow orientation

**Title:** Add /status command to show current position in CSW lifecycle

**Description:**
When returning to a project after time away, or after a crash/clear, it's difficult to understand:
- Where am I in the CSW lifecycle?
- What should I do next?
- What was the last command that ran?
- What's the state of active specs?

**Proposed Solution:**
Create a `/status` command (or enhance `/check` to be phase-aware) that shows:

```
CSW Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Current Branch: feature/add-auth
Base Branch: main

Active Specs:
  📝 spec/active/add-auth/
     Last: /plan (2025-10-17 14:32)
     Next: /build

Recent Activity:
  ✅ /spec   (2025-10-17 14:15) → spec.md created
  ✅ /plan   (2025-10-17 14:32) → plan.md created
  ⏭️  /build  (not started)

Suggested Next Step: Run /build to implement the plan
```

**Alternative approach:**
Enhance `/check` to be phase-aware and runnable at any time (not just pre-ship)

**Implementation ideas:**
- Log last command run to `<feature>/log.md` with timestamp
- Track: `ran /spec @ 12:56 PM generated spec.md`, `ran /plan @ 13:05 generated plan.md`
- Parse log.md to determine current state
- Helpful for both user context and CC recovery

**Acceptance Criteria:**
- [ ] Command shows current branch and base branch
- [ ] Lists active specs with last command run
- [ ] Suggests next logical step in workflow
- [ ] Works from any point in the lifecycle
- [ ] Helpful after /clear or session restart

**Labels:** enhancement, ux, workflow, commands

---

## 📚 Documentation & UX

### Issue 5: Clarify spec.md (WHAT) vs plan.md (HOW) distinction

**Title:** Better document the purpose difference between spec.md and plan.md

**Description:**
Users may not clearly understand the distinction between:
- **spec.md**: Concise description of WHAT you want (requirements, goals, constraints)
- **plan.md**: Detailed description of HOW to build it (implementation steps, technical approach)

This distinction is fundamental to the CSW workflow but isn't prominently documented or explained.

**Proposed Solutions:**
1. Add clear explanation to spec.md template
2. Update /spec command output to explain this
3. Add to documentation/README
4. Consider adding explanatory comments at top of generated files

**Example explanation:**
```markdown
# spec.md - WHAT to Build
This file describes WHAT you want to achieve:
- User-facing goals
- Business requirements
- Constraints and non-functional requirements
- Success criteria

Keep this concise and focused on outcomes, not implementation.

---

# plan.md - HOW to Build It
Generated by /plan, this file describes HOW to implement the spec:
- Technical approach and architecture decisions
- Step-by-step implementation plan
- File changes and code modifications
- Dependencies and integration points
```

**Acceptance Criteria:**
- [ ] spec.md template includes WHAT vs HOW explanation
- [ ] /spec command output clarifies this distinction
- [ ] README documents the purpose of each file
- [ ] Users understand when to edit spec vs plan

**Labels:** documentation, ux

---

### Issue 6: /plan clarifying questions are hard to navigate

**Title:** Show /plan clarifying questions one at a time for easier navigation

**Description:**
When /plan asks multiple clarifying questions (e.g., 5 questions), users have to scroll extensively:
- Scroll up to read question 1
- Scroll down to see all options
- Scroll back up to question 2
- Scroll back down to answer area
- Repeat for questions 3, 4, 5...

**Observed issue:**
Double-spaced clarifying question choices also make scrolling worse.

**Proposed Solution:**
Ask clarifying questions one at a time using sequential conversation:
1. Ask question 1, wait for answer
2. Ask question 2, wait for answer
3. Continue until all questions answered
4. Generate plan with all context

**Benefits:**
- Less scrolling and confusion
- Clearer focus on current question
- Better mobile/terminal experience
- Each question gets full attention

**Alternative:**
Group related questions and ask in smaller batches (2-3 at a time)

**Acceptance Criteria:**
- [ ] /plan asks clarifying questions sequentially
- [ ] User can focus on one question at a time
- [ ] No excessive scrolling needed
- [ ] Previous answers are remembered for plan generation

**Labels:** ux, commands, enhancement

---

## 🏗️ Architecture & Design

### Issue 7: Decide on and standardize spec/active path strategy

**Title:** Decide on spec/active path strategy and standardize across all commands

**Description:**
There are inconsistent references to `spec/active` scattered throughout the command prompts. Some commands look for `spec/active`, others use `./spec`, creating confusion about where specs should live.

**The Problem:**
- Inconsistent behavior across commands
- Some commands look for `spec/active`, others don't
- `spec/active` keeps appearing organically in usage
- Confusion about where to create/find specs
- Trying to remove it feels like fighting the natural flow

**This is a decision + implementation issue:**
We need to choose one approach and standardize all commands around it.

**Option A: Remove spec/active entirely**
- Use `find ./spec -name spec.md` everywhere
- Flatten structure or use feature-based paths directly under spec/
- Pro: Simpler structure
- Con: No clear distinction between active and shipped work

**Option B: Embrace spec/active as canonical WIP location**
- Standardize on `find ./spec/active -name spec.md`
- Make it the official location for work-in-progress specs
- Clear directory structure:

```
spec/
  active/              # Work in progress
    feature-a/
      spec.md
      plan.md
      log.md
    feature-b/
      spec.md
  shipped/             # Completed features (or use SHIPPED.md)
    feature-x/
```

**Benefits of Option B:**
- Clear mental model: active = working, shipped = done
- Natural organization that's already emerging
- Easy to see what's in progress vs completed
- Commands can default to active/ for current work

**Questions to resolve:**
- Which approach better serves the workflow?
- How does this interact with SHIPPED.md?
- Should shipped specs be archived in spec/shipped/ or just logged in SHIPPED.md?
- Does this conflict with existing patterns?

**Acceptance Criteria:**
- [ ] Decide on Option A or Option B (or alternative)
- [ ] Document decision and rationale
- [ ] Audit all command files for path references
- [ ] Update all commands to use standardized paths
- [ ] Update documentation and examples
- [ ] Test all commands with new path structure

**Labels:** architecture, decision, commands

---

### Issue 8: Bootstrap should auto-discover project type

**Title:** /spec bootstrap should automatically detect project stack and customize stack.md

**Description:**
When running bootstrap on a new project, it should intelligently discover the project type rather than requiring manual setup.

**Current behavior:**
- Creates generic stack.md
- User must manually update for their stack
- Easy to forget or misconfigure

**Proposed enhancement:**
Look for project indicators and customize stack.md automatically:

```
Detect:
- package.json        → Node.js/JavaScript project
- requirements.txt    → Python project
- Cargo.toml          → Rust project
- go.mod             → Go project
- pom.xml            → Java/Maven project
- build.gradle       → Java/Gradle project
- Gemfile            → Ruby project
- composer.json      → PHP project
```

**Smart customization:**
1. Detect project type(s)
2. Load appropriate stack template
3. Validate detected stack
4. Offer to customize or replace
5. Generate customized stack.md

**Acceptance Criteria:**
- [ ] Bootstrap detects project type from common files
- [ ] Generates stack.md customized for detected stack
- [ ] Handles multi-language projects (e.g., Node + Python)
- [ ] Allows user override if detection is wrong
- [ ] Falls back to generic template if unknown

**Labels:** enhancement, bootstrap, automation

---

## 🔬 Advanced / Future Work

### Issue 9: Comprehensive command prompt structure audit

**Title:** Audit and optimize command prompt structure for better AI interpretation

**Description:**
The command files (plan.md, check.md, build.md, ship.md, cleanup.md, spec.md) serve as reusable AI prompts executed frequently, but they may not consistently use structural elements to create clear conceptual boundaries and signal importance.

**Opportunity:**
A systematic audit could optimize these files for better AI interpretation and more reliable execution.

**Areas to examine:**

1. **Structural consistency**
   - Use of `---` separators to isolate critical instructions
   - Hierarchical structure across all commands
   - Creating clear mental "boxes" for key directives

2. **Emphasis and signaling**
   - Identifying sections where AI commonly makes mistakes
   - Emphasizing critical instructions
   - Clear success/failure criteria

3. **Pattern establishment**
   - What structural patterns work well?
   - What patterns lead to confusion?
   - How can we standardize?

4. **Testing and validation**
   - Measure reliability before/after changes
   - Track which sections cause confusion
   - Evidence-based improvements

**Force multiplier potential:**
Better-structured prompts = more reliable command execution across ALL workflows.

**Recommended approach:**
Treat as a separate spec-driven project with:
1. Evidence gathering (track confusion points)
2. Pattern analysis (identify what works vs doesn't)
3. Systematic testing (measure improvements)
4. Documentation of patterns for future commands

**Acceptance Criteria:**
- [ ] Complete audit of all command files
- [ ] Document current structure patterns
- [ ] Identify problem areas and confusion points
- [ ] Propose standardized structure template
- [ ] Test improvements and measure reliability
- [ ] Create pattern guide for future commands

**Labels:** infrastructure, optimization, research, commands

---

### Issue 10: Handle re-running /cleanup after extended time

**Title:** Support re-running /cleanup to rebase on latest main after time passes

**Description:**
What happens in this scenario:
1. User runs /cleanup after shipping features
2. User doesn't do more CSW work
3. Other developers merge changes to main
4. User returns later to start new work

**Question:**
Can user re-run /cleanup to rebase their cleanup branch on latest main?

**Current behavior:**
Unknown - needs testing and documentation

**Desired behavior:**
- /cleanup should be safe to re-run
- Should pull latest main
- Should rebase cleanup branch if it exists
- Should handle diverged histories gracefully

**Edge cases to handle:**
- Cleanup branch already exists
- Cleanup branch has diverged from main
- Conflicts during rebase
- User has uncommitted changes

**Acceptance Criteria:**
- [ ] Test re-running /cleanup after time passes
- [ ] Document expected behavior
- [ ] Handle existing cleanup branch gracefully
- [ ] Support rebasing on latest main
- [ ] Provide clear error messages for conflicts

**Labels:** enhancement, git, workflow, commands

---

## Summary

**Total Issues: 10**

**By Priority:**
- 🐛 High Priority Bugs: 2
- 🔧 Workflow Improvements: 3
- 📚 Documentation & UX: 2
- 🏗️ Architecture & Design: 2
- 🔬 Advanced / Future Work: 2

**Quick wins (low effort, high impact):**
- Issue 2: /cleanup git fetch fix
- Issue 5: Document spec vs plan distinction
- Issue 6: Sequential clarifying questions

**Longer term:**
- Issue 3: Incremental commits in /build
- Issue 4: /status command
- Issue 8: Auto-detect project type
- Issue 9: Command prompt audit

**Needs discussion:**
- Issue 7: spec/active path strategy (choose Option A or B)

---

## Next Steps

1. Review this document
2. Remove/modify any issues that aren't relevant
3. Prioritize which issues to file first
4. Use `gh issue create` to file selected issues
5. Consider creating milestones or project board for organization
