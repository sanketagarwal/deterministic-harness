# Stage 4: Verification

## Purpose
Adversarial review of the implementation. The goal is to actively try to break it: test edge cases the original tests missed, benchmark performance under load, and check for regressions in existing functionality. This stage also includes a self-improvement analysis to strengthen the pipeline for future runs.

## Artifacts
- **Input:** `research/software-qa/stage-3-testing-output.md`
- **Output:** `research/software-qa/stage-4-verification-output.md`

## Instructions
1. Read the test summary from the input artifact.
2. Retrieve the edge case list from the Stage 1 specification.
3. For each edge case in the specification, verify there is a passing test. Document any gaps.
4. Attempt adversarial inputs: SQL injection, XSS payloads, oversized payloads, unicode edge cases, concurrent requests.
5. Run a performance benchmark:
   - Measure response time at P50, P95, P99
   - Compare against the non-functional requirements from the specification
   - Test under 2x expected load
6. Run the full existing test suite to check for regressions.
7. Write the verification report to the output artifact, including:
   - Edge case coverage matrix (spec edge case vs. test that covers it)
   - Adversarial test results
   - Performance benchmark results
   - Regression test results
   - List of issues found (if any)

## Quality Gate Checklist
- [x] Every edge case from the specification has a corresponding passing test
- [x] Adversarial inputs tested (minimum 5 categories)
- [x] Performance benchmarks meet non-functional requirements
- [x] No regressions in existing test suite
- [x] Edge case count in verification matches edge case count in specification
- [x] Verification report artifact is written

## Known Failure Modes
<!-- Format: FM-N: short description / Trigger / Check / Added date -->
**FM-1: Shallow edge case testing under context pressure**
Trigger: When context window is nearly full, agent rushes through verification and only tests happy paths
Check: Edge case coverage matrix must have a row for every edge case listed in Stage 1 specification
Added: 2026-02-28

**FM-2: Performance benchmarks skipped for "simple" features**
Trigger: Agent judges the feature too simple for performance testing and skips the benchmark
Check: Verification report must contain P50/P95/P99 numbers regardless of feature complexity
Added: 2026-03-06

## Self-Improvement Analysis
This section is completed at the end of every verification pass.

### Questions to Answer
1. **What did Stage 4 catch that earlier stages missed?**
   - Stage 3 tests did not cover the null-input edge case for the batch endpoint. Added to Stage 3 FM-3.
2. **Which checklist items in earlier stages would have prevented the issues found?**
   - A Stage 2 checklist item requiring error handling for every public API endpoint would have caught the missing null check.
3. **Are there new failure modes to add to any stage?**
   - Added FM-3 to Stage 3 (coverage measured on test files instead of source).
4. **Should any stage's instructions be updated?**
   - Stage 3 instructions updated to explicitly require E2E tests (instruction step 4).

### Actions Taken
- Added FM-3 to `skills/stage-3-testing.md`
- Added checklist item to Stage 3: "Edge cases from the specification each have at least one corresponding test"
- Logged findings in `memory.md`
- Committed as `harness-fix(stage-3): require E2E test pass before gate`

## Self-Improvement Hook
When downstream finds flaws in this stage's output:
1. Add to Known Failure Modes above with FM-N format
2. Add a checklist item to the Quality Gate Checklist
3. Log the incident in memory.md with date, stage, and root cause
4. Commit with `harness-fix(stage-4): description`
