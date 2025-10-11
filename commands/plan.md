# Generate Implementation Plan

You are tasked with creating a comprehensive implementation plan from a feature specification. This plan will guide the AI agent through implementation with enough context for autonomous execution.

## Input
The user will provide the path to a specification file (e.g., `spec/active/auth/spec.md`).

## Process

1. **Read and Understand**
    - Read the specification file completely
    - Extract: desired outcome, constraints, examples, validation criteria
    - Identify any ambiguous requirements and note them
    - **CRITICAL**: Ask clarifying questions before proceeding

2. **Research Codebase**
    - Search for similar patterns/features already implemented
    - Identify files that will need modification
    - Find relevant test patterns to follow
    - Note architectural decisions that impact implementation

3. **Ask Clarifying Questions**
   Before creating the plan, ask about any gaps or ambiguities:
   ```
   Before I create the implementation plan, I need to clarify:
   
   1. {Specific question about requirement}
   2. {Question about integration point}
   3. {Question about edge case handling}
   
   Also:
   - Should this follow the pattern in {similar-feature}?
   - What's the priority: {tradeoff A} or {tradeoff B}?
   - Any specific performance constraints?
   ```

   Wait for responses and incorporate them into the plan.

4. **External Research** (if needed)
    - Search for library documentation
    - Find best practices for the specific technology
    - Identify common pitfalls and their solutions

4. **Create Implementation Plan**
   Save to `spec/active/{feature}/plan.md`:

   ```markdown
   # Implementation Plan: {Feature Name}
   Generated: {timestamp}
   Specification: spec.md

   ## Understanding
   {AI's interpretation of the requirements}

   ## Architecture Impact
   - Files to create: {list with purposes}
   - Files to modify: {list with specific changes}
   - Dependencies to add: {if any}

   ## Task Breakdown
   ### Task 1: {Name}
   **File**: {path/to/file.ts}
   **Action**: CREATE | MODIFY
   **Pattern**: Reference {path/to/similar.ts} lines {X-Y}
   
   **Implementation**:
   ```typescript
   // Pseudocode showing approach
   ```

   **Validation**:
   ```bash
   pnpm lint {file}
   pnpm typecheck
   pnpm test {test-file}
   ```

   ### Task 2: {...}

   ## Risk Assessment
    - **Risk**: {Description}
      **Mitigation**: {Strategy}

   ## Integration Points
    - Store updates: {which stores, what changes}
    - Route changes: {if applicable}
    - Config updates: {constants, env vars}

   ## Validation Sequence
   After each task:
   ```bash
   pnpm lint --fix
   pnpm typecheck
   pnpm test {affected-tests}
   ```

   Final validation:
   ```bash
   pnpm test:run
   pnpm build
   ```
   ```

5. **Git Setup**
   ```bash
   # Check current branch
   git branch --show-current
   
   # If on main/master:
   git checkout -b feature/{feature-name}
   
   # Stage the planning artifacts
   git add spec/active/{feature}/spec.md spec/active/{feature}/plan.md
   git commit -m "plan: {feature-name} implementation"
   ```

## Output Format
Report to user:
```
✅ Implementation plan created for {feature}
📁 Location: spec/active/{feature}/plan.md
🌿 Branch: feature/{feature-name}
📋 Tasks: {N} identified
⚡ Ready to build: /build spec/active/{feature}/
```

## Error Handling
- If spec file missing: Report error with path tried
- If ambiguous requirements: List them and ask for clarification
- If architectural concerns: Highlight them prominently in risks