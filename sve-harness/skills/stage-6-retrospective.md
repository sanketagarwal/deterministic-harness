# Stage 6: Self-Improvement & Retrospective

## Purpose

Review the entire pipeline run. Did any verification miss a misalignment that was later discovered? Did any "SAFE" pair turn out to have hidden issues? Did any AVOID recommendation kill a pair that was actually tradeable? Trace every issue back to the stage that should have caught it, and commit a mechanical fix to that stage's skill file. This is how the pipeline gets more reliable.

## Artifacts

- **Input:** `research/sve-harness/stage-5-recommendation-output.md`
- **Output:** `research/sve-harness/stage-6-retrospective-output.md`

## Command

**Command:** `manual`

## Instructions

1. Review all SAFE_TO_TRADE pairs: did any turn out to have issues not caught by verification? If so, trace to the specific stage and misalignment type.
2. Review all AVOID pairs: were any killed incorrectly? If the misalignment was minor and the trade was actually safe, that's a false positive — fix the threshold or criteria.
3. For each issue found:
   - Identify which earlier stage should have caught it
   - Write a specific fix: new checklist item, new failure mode entry, or adjusted gate condition
   - Commit the fix with `harness-fix(stage-N): description`
4. Update reliability estimate in memory.md with reasoning.
5. Review your output against the Quality Gate Checklist below.
6. Mark each checklist item as complete (`- [x]`) or leave unchecked with a note.

## Quality Gate Checklist

- [ ] Every issue found traced to upstream stage with proposed fix
- [ ] All fixes committed with `harness-fix(stage-N):` format
- [ ] Reliability estimate updated in memory.md with reasoning
- [ ] `git log --oneline | grep "harness-fix"` shows commits for all fixes

## Known Failure Modes

<!-- Populated over time from retrospectives and self-improvement analysis. -->

## Self-Improvement Hook

This IS the self-improvement stage. If issues are found here that should have been caught by this stage's own process, add them as Known Failure Modes above and commit with: `harness-fix(stage-6): description`
