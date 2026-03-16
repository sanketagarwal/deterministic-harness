# Stage 5: Synthesis

## Purpose

Produce a final verdict that is fully traceable: every claim maps to a specific data point or analysis result, all five stages are referenced with pass/fail summaries, and new hypotheses are spawned from the findings or failures.

## Artifacts

- **Input:** `research/research/stage-4-verification-output.md`
- **Output:** `research/research/stage-5-synthesis-output.md`

## Instructions

1. Write the verdict: PURSUE, INVESTIGATE, MONITOR, or ARCHIVE. State it in the first line.
2. For each claim in the verdict, provide a traceability link: cite the specific stage, section, and data point that supports it. Use the format: "[Claim] — supported by Stage N, [section], [metric/value]."
3. Write a stage-by-stage summary table:
   | Stage | Status | Key Finding | Caveats |
   Each stage must appear. If a stage surfaced no issues, say so explicitly.
4. Identify at least one new hypothesis spawned from this research — either a refinement of the original, an alternative mechanism discovered during verification, or a question raised by an unexpected result.
5. If the verdict is ARCHIVE or MONITOR, document what specific new evidence would change it.
6. Review your output against the Quality Gate Checklist below.
7. Mark each checklist item as complete (`- [x]`) or leave unchecked (`- [ ]`) with a note explaining why.

## Quality Gate Checklist

- [x] Every claim in the verdict is mapped to a specific data point or analysis result with stage reference
- [x] All five stages referenced in summary table with explicit pass/fail and key findings
- [x] At least one new hypothesis spawned with enough detail for a new Stage 1
- [x] For non-PURSUE verdicts: conditions for revisiting are stated with specific thresholds
- [x] Data quality caveats from Stage 2 are reflected in verdict confidence

## Known Failure Modes

<!-- This section is populated over time from retrospectives and self-improvement analysis.
     Each entry describes a specific failure mode and the mechanical check that prevents it.

     Format:
     **FM-N: Short description**
     Trigger: What situation causes this failure
     Check: What to verify to prevent it
     Added: Date, from retrospective/self-improvement of run X
-->

**FM-1: Verdict claim not traceable to a specific stage output**
Trigger: Synthesis makes a qualitative judgment ("the signal is robust") without citing which verification test supports it
Check: Every sentence in the verdict paragraph must contain a stage reference and a metric. If it does not, rewrite or remove.
Added: 2026-03-13, from retrospective of run 4

## Self-Improvement Hook

When a downstream review or retrospective finds that this stage's output was flawed:

1. **Add to Known Failure Modes** above with the FM-N format.
2. **Add a checklist item** to the Quality Gate Checklist that would have caught this specific issue.
3. **Log in memory.md** with the failure, root cause, fix applied, and this file as the file changed.
4. **Commit** with message format: `harness-fix(stage-5): description of what was added`
