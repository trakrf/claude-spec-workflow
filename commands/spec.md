# Convert Conversation to Specification

You are tasked with analyzing the current conversation and extracting a formal specification from the discussion.

## Input
Optional: Target feature name (e.g., `/spec auth-system`). If not provided, infer from conversation.

## Process

1. **Analyze Current Conversation**
    - Read through the entire conversation history
    - Identify the core problem or feature being discussed
    - Extract key requirements mentioned
    - Note any constraints or concerns raised
    - Capture code examples or patterns discussed

2. **Identify Specification Elements**
   From the conversation, extract:
    - **Outcome**: What problem are we solving?
    - **Context**: What led to this discussion?
    - **Requirements**: What specific needs emerged?
    - **Examples**: What code/patterns were referenced?
    - **Constraints**: What limitations were mentioned?
    - **Validation**: How will we know it works?

3. **Generate Draft Specification**
   Create `spec/active/{feature}/spec.md`:

   ```markdown
   # Feature: {Inferred Name}
   
   ## Origin
   This specification emerged from debugging/exploring {context}.
   
   ## Outcome
   {Clear statement of what will change}
   
   ## User Story
   As a {user type}
   I want {capability discussed}
   So that {benefit identified}
   
   ## Context
   **Discovery**: {What we learned in conversation}
   **Current**: {Current state discussed}
   **Desired**: {Target state identified}
   
   ## Technical Requirements
   {Extract from conversation:}
   - {Requirement 1 mentioned}
   - {Requirement 2 implied}
   - {Any performance/security concerns raised}
   
   ## Code Examples
   {Include any code snippets from conversation}
   ```

   ## Validation Criteria
    - [ ] {Success metric discussed}
    - [ ] {Test case mentioned}
    - [ ] {Edge case identified}

   ## Conversation References
    - Key insight: "{quote from conversation}"
    - Decision: "{agreement reached}"
    - Concern: "{issue raised}"
   ```

4. **Present for Review**
   Show the draft and ask:
   ```
   I've extracted this specification from our conversation.
   Please review and let me know what needs adjustment:
   
   {show draft spec}
   
   Edit directly or tell me what to change.
   ```

5. **Interactive Refinement**
    - Accept edits from user
    - Update spec based on feedback
    - Repeat until user confirms

6. **Finalize**
   When approved:
   ```bash
   mkdir -p spec/active/{feature}
   # Save the final spec.md
   ```

## Output Format
```
📝 Draft specification created from conversation

Key points captured:
- {main requirement}
- {secondary requirement}
- {constraint noted}

Saved to: spec/active/{feature}/spec.md

Review the spec above and let me know what needs adjustment.
When ready, run: /plan spec/active/{feature}/spec.md
```

## Quality Checks
- Does the spec capture the essence of the conversation?
- Are implicit requirements made explicit?
- Is the outcome clear and measurable?
- Are edge cases from discussion included?
- Is context preserved for future reference?

## Anti-patterns to Avoid
- ❌ Don't lose nuance from the conversation
- ❌ Don't over-formalize exploratory ideas
- ❌ Don't skip concerns raised during discussion
- ❌ Don't assume - ask for clarification
- ❌ Don't make it longer than necessary