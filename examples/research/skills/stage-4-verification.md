# Stage 4: Verification

## Purpose

Adversarially attack the findings from Stage 3. The goal is to break the result, not confirm it. Test alternative explanations with quantified impact, establish base rates, and run robustness attacks. Also perform self-improvement analysis on all upstream stages.

## Artifacts

- **Input:** `research/research/stage-3-analysis-output.md`
- **Output:** `research/research/stage-4-verification-output.md`

## Instructions

1. List every alternative explanation for the observed signal. For each one, design a test that would distinguish it from the hypothesized mechanism. Run the test and report the quantified impact.
2. Establish the base rate: how often does a signal of this magnitude and type appear by chance? Use permutation tests, random signal benchmarks, or historical false discovery rates.
3. Run at least 3 robustness attacks:
   - **Parameter perturbation:** Vary key thresholds (lookback, holding period, entry/exit levels) by +/- 20%. Report sensitivity.
   - **Data exclusion:** Remove the top-contributing 10% of observations. Does the signal survive?
   - **Regime split:** Test separately in high-vol vs. low-vol regimes (or bull vs. bear, or pre/post structural break).
4. If any robustness attack reduces the signal below the cost threshold, document which attack and recommend KILL or INVESTIGATE.
5. Perform self-improvement analysis (see section below).
6. Review your output against the Quality Gate Checklist below.
7. Mark each checklist item as complete (`- [x]`) or leave unchecked (`- [ ]`) with a note explaining why.

## Quality Gate Checklist

- [x] Every alternative explanation tested with quantified impact (not just listed)
- [x] Base rate established using permutation test or equivalent
- [x] At least 3 robustness attacks run with results documented
- [x] Signal survival assessed against cost threshold after each attack
- [x] Self-improvement analysis completed: upstream stage flaws identified and logged

## Known Failure Modes

<!-- This section is populated over time from retrospectives and self-improvement analysis.
     Each entry describes a specific failure mode and the mechanical check that prevents it.

     Format:
     **FM-N: Short description**
     Trigger: What situation causes this failure
     Check: What to verify to prevent it
     Added: Date, from retrospective/self-improvement of run X
-->

**FM-1: Listed confound without testing it**
Trigger: Verification names an alternative explanation (e.g., "could be driven by momentum") but does not run a distinguishing test
Check: If you can construct a test for an alternative explanation, you MUST run it. Listing confounds without testing them is a disclaimer, not verification. Every confound must have a corresponding test with a quantified result.
Added: 2026-03-05, from failure registry entry on untested confounds

**FM-2: Robustness attack used unrealistic perturbation range**
Trigger: Parameter perturbation used +/- 5% which is too narrow to reveal fragility
Check: Minimum perturbation range is +/- 20% for all key parameters
Added: 2026-03-09, from retrospective of run 3

## Self-Improvement Analysis

After completing the verification, review all upstream stages for flaws revealed by the verification process:

1. **Stage 1 (Hypothesis):** Did the mechanism hold up? Was the actor correctly identified? Were the kill criteria appropriate?
2. **Stage 2 (Data Collection):** Did data quality issues affect the analysis? Were gaps adequately documented?
3. **Stage 3 (Analysis):** Were there features that passed screening but failed verification? Was temporal stability overstated?

For each flaw found:
- Add a Known Failure Mode entry to the upstream stage's skill file.
- Add a corresponding checklist item if one would have caught it.
- Log in memory.md with the upstream file as the file changed.
- Commit with format: `harness-fix(stage-N): description`

## Self-Improvement Hook

When a downstream stage (especially Synthesis) finds that this stage's output was flawed:

1. **Add to Known Failure Modes** above with the FM-N format.
2. **Add a checklist item** to the Quality Gate Checklist that would have caught this specific issue.
3. **Log in memory.md** with the failure, root cause, fix applied, and this file as the file changed.
4. **Commit** with message format: `harness-fix(stage-4): description of what was added`
