# Stage 3: Analysis

## Purpose

Test whether the hypothesized signal exists in the collected data. Every feature must have an economic rationale, and the signal must demonstrate stability across time. Produce an explicit proceed/kill recommendation.

## Artifacts

- **Input:** `research/research/stage-2-data-collection-output.md`
- **Output:** `research/research/stage-3-analysis-output.md`

## Instructions

1. For each feature or predictor, write one sentence explaining the economic mechanism it captures. If you cannot, remove the feature.
2. Split the data into at least 3 non-overlapping time periods. Test signal strength in each period independently. Report the range of effect sizes across periods.
3. Run the primary statistical test defined in the hypothesis kill criteria. Report the test statistic, p-value or equivalent, and effect size.
4. Check whether the signal magnitude exceeds the cost threshold from Stage 1 (spread + slippage + impact). If it does not, recommend KILL.
5. If signal passes, estimate decay rate: how quickly does the signal lose predictive power after formation?
6. Produce a proceed/kill recommendation with explicit confidence level and the key evidence supporting it.
7. Review your output against the Quality Gate Checklist below.
8. Mark each checklist item as complete (`- [x]`) or leave unchecked (`- [ ]`) with a note explaining why.

## Quality Gate Checklist

- [x] Every feature has a stated economic rationale (not just statistical correlation)
- [x] Temporal stability checked across at least 3 non-overlapping periods with effect sizes reported
- [x] Proceed/kill recommendation made with explicit confidence level and supporting evidence
- [x] Signal magnitude compared against execution cost threshold from Stage 1
- [x] Minimum data history requirement verified for each asset before inclusion in test universe

## Known Failure Modes

<!-- This section is populated over time from retrospectives and self-improvement analysis.
     Each entry describes a specific failure mode and the mechanical check that prevents it.

     Format:
     **FM-N: Short description**
     Trigger: What situation causes this failure
     Check: What to verify to prevent it
     Added: Date, from retrospective/self-improvement of run X
-->

**FM-1: Feature with no economic rationale passed screening**
Trigger: Feature shows high statistical significance but has no mechanism linking it to actor behavior
Check: Before running any test, write the economic rationale. If it takes more than 2 sentences to justify, flag for review
Added: 2026-03-06, from retrospective of run 2

**FM-2: Locked test spec for assets with no historical data**
Trigger: Test universe included recently listed assets with insufficient history for the lookback period
Check: Require minimum history length (2x lookback period) before including an asset in the test universe
Added: 2026-03-08, from failure registry entry on insufficient data history

## Self-Improvement Hook

When a downstream stage (especially Verification) finds that this stage's output was flawed:

1. **Add to Known Failure Modes** above with the FM-N format.
2. **Add a checklist item** to the Quality Gate Checklist that would have caught this specific issue.
3. **Log in memory.md** with the failure, root cause, fix applied, and this file as the file changed.
4. **Commit** with message format: `harness-fix(stage-3): description of what was added`
