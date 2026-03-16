# Stage 5: Recommendation & Report

## Purpose

Produce the final recommendation for each market pair. Ensure nothing was silently dropped — every pair from Stage 2 must have a final status. SAFE_TO_TRADE pairs get a green light with specific conditions. AVOID pairs get documented with exactly which misalignment killed them. This stage also runs a code quality check to make sure the engine itself is healthy.

## Artifacts

- **Input:** `research/sve-harness/stage-4-risk-assessment-output.md`
- **Output:** `research/sve-harness/stage-5-recommendation-output.md`

## Command

**Command:** `npx tsc --noEmit`

## Instructions

1. Compile the final report with a recommendation for each pair:
   - **SAFE_TO_TRADE**: market IDs on both venues, confidence score, and specific conditions that would invalidate the trade
   - **PROCEED_WITH_CAUTION**: same as above plus the risk conditions from Stage 4
   - **AVOID**: both market IDs, the specific misalignment(s) that killed it, and the potential loss prevented
   - **MANUAL_REVIEW**: why automated verification was insufficient
2. Verify pair count: count at Stage 2 MUST equal count at Stage 5. If any pairs disappeared, trace where they were lost.
3. Run `npx tsc --noEmit` to verify the engine codebase compiles.
4. Review your output against the Quality Gate Checklist below.
5. Mark each checklist item as complete (`- [x]`) or leave unchecked with a note.

## Quality Gate Checklist

- [ ] Every pair from Stage 2 has a final status (SAFE_TO_TRADE, PROCEED_WITH_CAUTION, AVOID, MANUAL_REVIEW)
- [ ] No pairs disappeared between stages — count at Stage 2 equals count at Stage 5
- [ ] SAFE_TO_TRADE recommendations include: market IDs, venues, confidence, and specific conditions that would invalidate the trade
- [ ] TypeScript build succeeds: `npx tsc --noEmit`

## Known Failure Modes

<!-- Populated over time from retrospectives and self-improvement analysis. -->

## Self-Improvement Hook

When a downstream stage finds that this stage's output was flawed:

1. **Add to Known Failure Modes** above with the FM-N format.
2. **Add a checklist item** that would have caught this specific issue.
3. **Log in memory.md** with the failure, root cause, fix applied, and this file as the file changed.
4. **Commit** with format: `harness-fix(stage-5): description of what was added`
