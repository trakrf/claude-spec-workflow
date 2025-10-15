# Implementation Plan: Interactive Clarifying Questions
Generated: 2025-10-15
Specification: spec.md

## Understanding

The current `/plan` workflow asks 8-10 clarifying questions in batch format, which creates UX friction:
- User must scroll back repeatedly to see each question while typing answers
- On last release, answering questions 1-6 pushed question 7 off screen
- Result: 8+ scroll-back cycles per planning session

**Solution**: Change the prompt in commands/plan.md to ask questions **one at a time** instead of batch format. This is pure prompt engineering - zero code changes needed.

**New behavior**:
1. Show progress indicator: "Question N/M: [question]"
2. Wait for user answer
3. Acknowledge briefly: "✓ Got it. [1-line summary]"
4. Move to next question
5. After all answered: "All questions answered! Generating plan..."

**User flexibility**:
- Answer normally → proceed to next
- Say "skip" or "default" → use inferred answer, proceed
- Say "default for rest" → use defaults for remaining questions
- Answer multiple at once → acknowledge all, jump ahead

## Relevant Files

**Files to Modify**:
- `commands/plan.md` (lines 209-268) - Replace the "Ask Mandatory Clarifying Questions" section with one-at-a-time format

**No new files needed** - This is a documentation/prompt change only.

## Architecture Impact
- **Subsystems affected**: Command prompts only
- **New dependencies**: None
- **Breaking changes**: None (same questions, better UX)

## Task Breakdown

### Task 1: Update Clarifying Questions Section in commands/plan.md
**File**: commands/plan.md
**Action**: MODIFY
**Lines**: 209-268 (the "Ask Mandatory Clarifying Questions" section)

**Implementation**:
Replace the current batch format instructions with one-at-a-time format:

**Current approach (lines 209-268)**:
```markdown
5. **Ask Mandatory Clarifying Questions** (REQUIRED GATE)

   **Format Requirements**:
   - Use numbered/lettered lists for easy responses
   - Group related questions by category
   - Make it easy for user to respond with "1a, 2, 3b" style answers
```

**New approach**:
```markdown
5. **Ask Mandatory Clarifying Questions** (REQUIRED GATE)

   **CRITICAL**: You MUST ask clarifying questions before generating the plan.

   **ONE-AT-A-TIME FORMAT** (eliminates scrolling friction):

   Ask questions **sequentially**, not in batch:

   1. **Show progress**: "Question N/M: [question]"
   2. **Wait for answer**: Let user respond
   3. **Acknowledge briefly**: "✓ Got it. [1-line summary]"
   4. **Move to next**: Ask Question N+1/M
   5. **After all answered**: "All questions answered! Generating plan..."

   **User Flexibility**:
   - **Normal answer** → Acknowledge and proceed to next question
   - **"skip" or "default"** → Use inferred answer, proceed to next
   - **"default for rest"** → Use sensible defaults for all remaining questions
   - **Multiple answers** → "1a, 2b, 3c" → Acknowledge all, skip to first unanswered question

   **Question Categories** (still ask about these):
   - Ambiguous requirements or undefined behaviors
   - Integration points not explicitly stated
   - Technical tradeoffs (performance vs simplicity, etc.)
   - Existing patterns to follow or avoid
   - Edge cases not covered in spec
   - Testing strategy and coverage expectations
   - Error handling approach

   **Example ONE-AT-A-TIME flow**:
   ```
   Question 1/5: Should this follow the pattern in auth-service.ts:45-67?
      a) Yes, mirror that approach
      b) No, use different pattern

   [User: "a"]

   ✓ Got it. Following auth-service.ts pattern.

   Question 2/5: What's the priority tradeoff?
      a) Performance (faster but more complex)
      b) Simplicity (cleaner code but potentially slower)
      c) Balance both

   [User: "c"]

   ✓ Got it. Balancing performance and simplicity.

   Question 3/5: How should this integrate with existing API layer?

   [User: "Use the same REST conventions as user-api.ts"]

   ✓ Got it. Using REST conventions from user-api.ts.

   Question 4/5: What test coverage level is expected?
      a) Unit tests only
      b) Unit + Integration tests
      c) Unit + Integration + E2E tests

   [User: "default for rest"]

   ✓ Got it. Using sensible defaults for remaining questions.
   ✓ Test coverage: Unit + Integration (inferred from project standards)
   ✓ Error handling: Follow existing error-handler.ts pattern

   All questions answered! Generating plan...
   ```

   **WAIT FOR USER RESPONSES** (one at a time)

   Incorporate all answers into the plan before proceeding to codebase research.
```

**Validation**:
- Run `/plan` on a test spec
- Verify questions come one at a time (not batch)
- Verify progress indicator shows "Question N/M"
- Test "skip" functionality
- Test "default for rest" functionality
- Test answering multiple questions at once ("1a, 2b")
- Verify same question quality as before (nothing skipped)
- Verify zero scrolling needed

### Task 2: Test the Updated Prompt
**Action**: Manual testing via dogfooding

**Test Cases**:
1. **Normal flow**: Answer each question individually
   - Expected: See "Question 1/N", answer, see "✓ Got it...", see "Question 2/N"

2. **Skip individual question**: Say "skip" or "default"
   - Expected: See "✓ Got it. [inferred answer]", proceed to next

3. **Skip remaining questions**: Say "default for rest"
   - Expected: See acknowledgments for all remaining questions, proceed to plan generation

4. **Answer multiple at once**: Say "1a, 2b, 3c"
   - Expected: See acknowledgments for 1, 2, 3, skip to question 4

5. **Edge case - empty answer**: Just press enter
   - Expected: Re-ask with clarification

**Validation**:
- Zero scroll-backs needed (primary success metric)
- Natural conversation flow
- Same plan quality as batch format
- All questions still asked (or defaulted with user consent)

## Risk Assessment

**Risk**: Users might find one-at-a-time slower than batch
**Mitigation**:
- Allow "default for rest" option for users who want speed
- Allow answering multiple questions at once ("1a, 2b, 3c")
- Brief acknowledgments keep flow moving

**Risk**: AI might forget context from earlier answers
**Mitigation**:
- Prompt already says "Incorporate all answers into the plan before proceeding"
- ULTRATHINK section ensures synthesis of all context

**Risk**: Users might not understand new format
**Mitigation**:
- Progress indicator ("Question N/M") makes it clear
- Example flow in prompt shows expected interaction

## Integration Points

**No integration needed** - This is a self-contained prompt change in commands/plan.md.

**Existing workflow unchanged**:
- Still asks clarifying questions before plan generation
- Still waits for user responses
- Still incorporates answers into plan
- Still proceeds to codebase research after questions

## VALIDATION GATES (MANDATORY)

**For this feature**:
- Gate 1: Shellcheck (lint for bash scripts) - `shellcheck commands/*.md` (not applicable - markdown only)
- Gate 2: Manual testing via dogfooding
- Gate 3: Verify zero code changes (pure prompt engineering)

**After implementation**:
1. Run `/plan` on this spec itself (meta-testing!)
2. Verify one-at-a-time question flow
3. Test skip/default functionality
4. Confirm same plan quality

## Validation Sequence

1. **Edit commands/plan.md** - Update lines 209-268
2. **Dogfood test** - Run `/plan` on a new spec to verify behavior
3. **Edge case testing** - Test skip, default for rest, multiple answers
4. **Quality check** - Compare plan quality to previous batch format

## Plan Quality Assessment

**Complexity Score**: 1/10 (LOW)
- 1 file to modify (commands/plan.md)
- 1 subsystem (command prompts)
- 2 tasks (update prompt + test)
- 0 new dependencies
- Existing pattern (prompt updates are common)

**Confidence Score**: 9/10 (HIGH)

**Confidence Factors**:
✅ Clear requirements from spec (no ambiguity)
✅ Simple scope (single prompt change, ~60 lines)
✅ Zero code changes (pure documentation/prompt)
✅ Existing pattern (we update command prompts regularly)
✅ Easy to test via dogfooding
✅ Easy to revert if needed (single file)

**Assessment**: High confidence - this is a well-scoped UX improvement with minimal risk.

**Estimated one-pass success probability**: 95%

**Reasoning**:
- Simple prompt change, no code involved
- Clear specification with concrete example
- Dogfooding will immediately reveal any issues
- Can iterate quickly if needed (no build/test cycles)
- Worst case: revert to batch format (5 minute fix)
