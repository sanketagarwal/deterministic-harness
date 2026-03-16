# Stage 5: Release

## Purpose
Final human-gated decision point. Confirm that all documentation is updated, a changelog entry exists, and every previous gate has passed. This stage does not introduce new work — it verifies completeness and records the release for future reference.

## Artifacts
- **Input:** `research/software-qa/stage-4-verification-output.md`
- **Output:** `research/software-qa/stage-5-release-output.md`

## Instructions
1. Read the verification report from the input artifact.
2. Verify all previous gates passed by running:
   ```
   ./gate-enforcer.sh 1 software-qa
   ./gate-enforcer.sh 2 software-qa
   ./gate-enforcer.sh 3 software-qa
   ./gate-enforcer.sh 4 software-qa
   ```
3. Write or update the CHANGELOG entry for this release:
   - Version number
   - Date
   - Summary of changes
   - Breaking changes (if any)
   - Migration notes (if any)
4. Update user-facing documentation to reflect the new feature.
5. Write the release summary to the output artifact, including:
   - Gate pass/fail status for all 5 stages
   - Changelog entry
   - Documentation files updated
   - Known limitations or follow-up items
6. Present the release summary to the human reviewer for final approval.

## Quality Gate Checklist
- [x] All previous gates (1-4) pass when re-run
- [x] Changelog entry written with version, date, and summary
- [x] User-facing documentation updated to reflect new feature
- [x] No open issues or unresolved findings from verification
- [x] Release summary artifact is written
- [x] Human reviewer has approved the release

## Known Failure Modes
<!-- Format: FM-N: short description / Trigger / Check / Added date -->
**FM-1: Stale gate results accepted**
Trigger: Agent checks gate results from a previous run instead of re-running gates, missing recent regressions
Check: Gate enforcer must be executed fresh (check timestamps), not referenced from cached output
Added: 2026-03-08

**FM-2: Documentation updated for happy path only**
Trigger: Agent updates docs to describe the new feature but omits error handling, edge cases, and limitations
Check: Documentation must include an "Error Handling" or "Limitations" section
Added: 2026-03-12

## Self-Improvement Hook
When downstream finds flaws in this stage's output:
1. Add to Known Failure Modes above with FM-N format
2. Add a checklist item to the Quality Gate Checklist
3. Log the incident in memory.md with date, stage, and root cause
4. Commit with `harness-fix(stage-5): description`
