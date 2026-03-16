# Stage 4: Risk Assessment

## Purpose

Aggregate verification results into actionable risk profiles. For each pair: what is the probability that one market resolves YES and the other NO? What is the maximum loss? Factor in confidence level, misalignment severity, and the arbitrage spread. A HIGH risk pair with AVOID recommendation MUST be killed here — it does not advance to the recommendation stage. This is the human gate because risk tolerance is a human decision.

## Artifacts

- **Input:** `research/sve-harness/stage-3-resolution-verification-output.md`
- **Output:** `research/sve-harness/stage-4-risk-assessment-output.md`

## Command

**Command:** `manual`

## Instructions

1. For each verified pair from Stage 3, compute a risk profile:
   - **Divergence probability**: likelihood that the two markets resolve differently (based on misalignment severity)
   - **Max loss scenario**: what happens if you take the arb and the markets diverge?
   - **Spread vs. risk**: is the arbitrage profit worth the risk? A 2% spread on a HIGH risk pair is not worth it.
2. Kill any pair with: riskLevel HIGH or CRITICAL, OR recommendation AVOID, OR any RESOLUTION_DATE or DEFINITION misalignment with severity HIGH.
3. For PROCEED_WITH_CAUTION pairs, document the specific conditions that would make the trade unsafe (e.g., "safe only if Bitcoin crosses $100k before Feb 1, otherwise Kalshi resolves NO while Polymarket remains open").
4. Include cost analysis: how much did embedding + LLM verification cost for this batch? Is it justified by the potential profit?
5. Review your output against the Quality Gate Checklist below.
6. Mark each checklist item as complete (`- [x]`) or leave unchecked with a note.

## Quality Gate Checklist

- [ ] Every pair has a risk profile with: risk level, max loss scenario, and probability estimate
- [ ] All HIGH and CRITICAL risk pairs explicitly marked AVOID with reasoning
- [ ] PROCEED_WITH_CAUTION pairs have specific conditions documented (what would make them unsafe)
- [ ] Cost analysis included: embedding cost, LLM verification cost, total cost vs. potential arbitrage profit

## Known Failure Modes

**FM-1: Treating PROCEED_WITH_CAUTION as SAFE**
Trigger: A pair with MEDIUM risk and some misalignments gets treated as safe because "it's probably fine"
Check: PROCEED_WITH_CAUTION pairs MUST have explicit condition documentation. If conditions aren't documented, the pair defaults to AVOID.
Added: 2026-03-16, from design review

## Self-Improvement Hook

When a downstream stage finds that this stage's output was flawed:

1. **Add to Known Failure Modes** above with the FM-N format.
2. **Add a checklist item** that would have caught this specific issue.
3. **Log in memory.md** with the failure, root cause, fix applied, and this file as the file changed.
4. **Commit** with format: `harness-fix(stage-4): description of what was added`
