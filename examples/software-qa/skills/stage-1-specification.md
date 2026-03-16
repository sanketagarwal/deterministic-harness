# Stage 1: Specification

## Purpose
Define the feature requirements with clear, testable acceptance criteria. Identify edge cases upfront and bound the scope to prevent creep during implementation. This stage ensures everyone agrees on what "done" looks like before a single line of code is written.

## Artifacts
- **Input:** Feature request or ticket description (external)
- **Output:** `research/software-qa/stage-1-specification-output.md`

## Instructions
1. Read the feature request or ticket description thoroughly.
2. Write a specification document that includes:
   - A one-paragraph summary of the feature
   - A numbered list of functional requirements
   - A numbered list of non-functional requirements (performance, security, accessibility)
   - An explicit scope boundary ("this feature does NOT include...")
3. For each functional requirement, write at least one acceptance criterion in Given/When/Then format.
4. Enumerate edge cases: null inputs, boundary values, concurrent access, error states, empty collections.
5. List any assumptions that need human confirmation.
6. Save the specification to the output artifact path.

## Quality Gate Checklist
- [x] Every functional requirement has at least one testable acceptance criterion
- [x] Edge cases are explicitly enumerated (minimum 5)
- [x] Scope boundary is defined — at least 2 "out of scope" items listed
- [x] Non-functional requirements are specified with measurable thresholds
- [x] No ambiguous language ("should", "might", "could") in acceptance criteria

## Known Failure Modes
<!-- Format: FM-N: short description / Trigger / Check / Added date -->
**FM-1: Scope creep through vague requirements**
Trigger: Agent writes requirements using subjective language like "intuitive UI" or "fast response"
Check: Grep the output for subjective adjectives; every requirement must have a measurable criterion
Added: 2026-02-12

**FM-2: Missing error-state edge cases**
Trigger: Agent focuses on happy-path scenarios and omits what happens when things fail
Check: Output must contain at least 2 edge cases related to error/failure states
Added: 2026-03-01

## Self-Improvement Hook
When downstream finds flaws in this stage's output:
1. Add to Known Failure Modes above with FM-N format
2. Add a checklist item to the Quality Gate Checklist
3. Log the incident in memory.md with date, stage, and root cause
4. Commit with `harness-fix(stage-1): description`
