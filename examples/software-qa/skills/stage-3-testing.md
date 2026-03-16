# Stage 3: Testing

## Purpose
Write and execute comprehensive tests for the implementation. This stage ensures correctness through unit tests, integration tests, and end-to-end tests. Coverage must exceed the project threshold to prevent untested code paths from reaching verification.

## Artifacts
- **Input:** `research/software-qa/stage-2-implementation-output.md`
- **Output:** `research/software-qa/stage-3-testing-output.md`

## Instructions
1. Read the implementation summary from the input artifact.
2. For each implemented component, write unit tests covering:
   - Happy path (expected inputs produce expected outputs)
   - Boundary values (empty, zero, max, off-by-one)
   - Error cases (invalid input, missing data, permission denied)
3. Write integration tests that verify components work together correctly.
4. Write end-to-end tests that exercise the feature from the user's perspective.
5. Run all test suites and capture the output.
6. Measure code coverage and verify it exceeds the 80% threshold.
7. Write the test summary to the output artifact, including:
   - Test count by type (unit, integration, E2E)
   - Pass/fail counts
   - Coverage percentage
   - Any flaky tests identified and their root cause

## Quality Gate Checklist
- [x] All unit tests pass (zero failures)
- [x] All integration tests pass (zero failures)
- [x] All end-to-end tests pass (zero failures)
- [x] Code coverage exceeds 80% threshold
- [x] Edge cases from the specification each have at least one corresponding test
- [x] No flaky tests in the suite (or flaky tests are documented with root cause)
- [x] Test summary artifact is written with pass/fail counts and coverage

## Known Failure Modes
<!-- Format: FM-N: short description / Trigger / Check / Added date -->
**FM-1: Tests written but not executed**
Trigger: Agent writes test files but does not actually run the test runner, marking the gate as passed based on code review alone
Check: Test output must include actual runner output with timestamps, not just test file listings
Added: 2026-02-10

**FM-2: E2E tests skipped, only unit tests run**
Trigger: Agent runs unit tests (fast) but skips E2E tests (slow), declaring the stage complete
Check: Test summary must include a non-zero E2E test count with runner output
Added: 2026-02-15

**FM-3: Coverage measured on test files instead of source**
Trigger: Agent includes test files in coverage measurement, inflating the percentage
Check: Coverage report must specify source directories only, excluding test directories
Added: 2026-03-02

## Self-Improvement Hook
When downstream finds flaws in this stage's output:
1. Add to Known Failure Modes above with FM-N format
2. Add a checklist item to the Quality Gate Checklist
3. Log the incident in memory.md with date, stage, and root cause
4. Commit with `harness-fix(stage-3): description`
