# Feature: Interactive Clarifying Questions

## Status
**Active** - Ready for planning

## Origin
Dogfooding observation: /plan asks 8-10 clarifying questions in batch format. User must scroll back repeatedly to see each question while typing answers. On last release (consolidate-bootstrap), answering questions 1-6 pushed question 7 off screen, then answer 7 pushed question 8 off screen. Result: 8+ scroll-back cycles per planning session.

## Outcome
- /plan asks clarifying questions **one at a time** instead of batch
- User sees current question without scrolling
- Natural conversation flow (question → answer → next)
- Progress indicator: "Question N/M"
- User can skip/default remaining questions
- Zero code changes - pure prompt engineering

## User Story
As a CSW user running /plan
I want to answer clarifying questions one at a time
So that I don't have to scroll back repeatedly to see what I'm answering

## Technical Requirements

### Update commands/plan.md Prompt

**Current behavior**:
```
Ask 8-10 mandatory clarifying questions before generating plan.
List all questions, then wait for user's answers.
```

**New behavior**:
```
Ask 8-10 mandatory clarifying questions ONE AT A TIME before generating plan.

**Question Flow**:
1. Show progress: "Question N/M: [question]"
2. Wait for user answer
3. Acknowledge briefly: "✓ Got it. [1-line summary]"
4. Move to next question
5. After all answered: "All questions answered! Generating plan..."

**User can**:
- Answer normally (proceed to next)
- Say "skip" or "default" (use inferred answer, proceed)
- Say "default for rest" (use defaults for remaining questions)
- Answer multiple at once (acknowledge all, jump ahead)

This eliminates scrolling friction while maintaining question quality.
```

## Validation Criteria

- [ ] Updated prompt in commands/plan.md
- [ ] /plan asks questions one at a time
- [ ] Progress indicator shows "Question N/M"
- [ ] Brief acknowledgment between questions ("✓ Got it...")
- [ ] User can skip individual questions
- [ ] User can default remaining questions
- [ ] Final "All questions answered!" before plan generation
- [ ] Same quality output (all questions still asked)
- [ ] Zero scrolling needed to see current question

## Success Metrics

- **UX improvement**: Zero scroll-backs (down from 8-10)
- **Conversation flow**: Natural Q&A pattern
- **Same quality**: All questions still asked and answered
- **Flexibility**: User can skip/default/batch as needed
- **Quick win**: Single file change, no code

## Implementation Notes

**Scope**: Documentation/prompt change only
- Edit: commands/plan.md
- Lines: ~50-60 (MANDATORY CLARIFYING QUESTIONS section)
- No bash scripts changed
- No new files created

**Testing**:
- Run /plan on a new spec
- Verify questions come one at a time
- Test skip/default functionality
- Verify plan quality unchanged

**Edge cases**:
- User answers multiple questions at once → acknowledge all, skip ahead
- User says "skip all" → use defaults for everything, proceed
- Empty answer → re-ask with clarification
