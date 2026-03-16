# Memory: Software QA Pipeline

## Failure Log

<!-- Format:
| Date | Stage | What happened | Root cause | Fix applied | Commit |
-->

| Date | Stage | What happened | Root cause | Fix applied | Commit |
|------|-------|---------------|------------|-------------|--------|
| 2026-02-15 | 3 | Agent marked feature complete without running E2E tests. Unit tests passed but integration with the API gateway was completely broken. Bug reached verification stage and cost 3 hours to diagnose. | Agent treated "unit tests pass" as sufficient for the testing gate. No checklist item required E2E test execution. | Added explicit E2E test execution to Stage 3 checklist. Added FM-2 to stage-3-testing.md. | `harness-fix(stage-3): require E2E test pass before gate` |
| 2026-02-28 | 4 | Agent skipped edge case testing when under context pressure. With a large implementation, the agent rushed through verification and only tested the happy path. Three null-pointer edge cases shipped to release. | Context window was nearly full. Agent prioritized completing the checklist over thoroughness. No mechanical check forced edge case enumeration. | Added "edge case count matches specification" checklist item to Stage 4. Added FM-1 to stage-4-verification.md requiring edge case list comparison against spec. | `harness-fix(stage-4): require edge case enumeration against spec` |
| 2026-03-05 | 2 | Agent left TODO comments in committed code. Two `// TODO: handle error` placeholders were in the final implementation, masking missing error handling. | Agent used TODOs as reminders during development but never circled back. No grep check was enforced. | Added "no TODOs in committed code" checklist item to Stage 2. Added grep-based check instruction. | `harness-fix(stage-2): add TODO grep check before gate` |

## Reliability Tracking

<!-- Format:
| Date | Metric | Value | Notes |
-->

| Date | Metric | Value | Notes |
|------|--------|-------|-------|
| 2026-02-10 | Baseline pass rate | 60% | 3 of 5 stages passed on first attempt across initial runs |
| 2026-02-20 | Pass rate after first fix | 72% | Stage 3 E2E fix prevented 2 regressions in subsequent runs |
| 2026-03-08 | Current pass rate | 88% | All three fixes applied. One remaining failure mode: agent occasionally underestimates scope in Stage 1 |

## Patterns Observed
- The agent is most likely to cut corners in later stages when context window usage is high
- Mechanical checks (grep for TODOs, test runner exit codes) catch failures that judgment-based checks miss
- Failure modes added to checklists have not recurred after the fix is applied
