# Stage 5: Report Generation

## Purpose
Render the final CLI report from the analysis pipeline and verify end-to-end accuracy. This stage transforms the structured insights from pattern analysis into a readable, actionable terminal output and confirms that key figures are consistent across all upstream stages — prompt counts, score ranges, and recommendations all trace back to source data.

## Artifacts
- **Input:** `research/prompt-prof/stage-4-pattern-analysis-output.md`
- **Output:** `research/prompt-prof/stage-5-report-generation-output.md`

## Command
**Command:** `npm run build`

## Instructions
1. Run `npm run build` to compile the project and verify there are no TypeScript errors.
2. Execute the report generation module against the Stage 4 output to produce the CLI report.
3. Cross-check key figures for consistency across the pipeline:
   - Total prompt count in the report matches the count from Stage 1 output.
   - Top score and bottom score in the report match the values from Stage 3 output.
   - Recommendations in the report match those generated in Stage 4.
4. Verify the CLI report renders without errors, formatting issues, or truncated output — including ANSI color codes, table alignment, and section headers.
5. Run the test suite to confirm all tests pass after the build.

## Quality Gate Checklist
- [ ] CLI report renders without errors or formatting issues
- [ ] Total prompt count in report matches Stage 1 parsed count
- [ ] Top score in report matches Stage 3 highest composite score
- [ ] All tests pass (`npm test` or equivalent)
- [ ] `npm run build` succeeds with exit code 0

## Known Failure Modes
<!-- No known failure modes identified yet. Add entries as FM-N with trigger and check. -->

## Self-Improvement Hook
After completing Stage 5, review the quality gate checklist results and the rendered report. If any items failed or rendering edge cases were discovered, append a `## Retrospective` section to `research/prompt-prof/stage-5-report-generation-output.md` documenting:
- What failed and why
- The fix or workaround applied
- Whether this failure mode should be added to Known Failure Modes for future runs
