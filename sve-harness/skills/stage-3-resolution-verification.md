# Stage 3: Resolution Criteria Verification

## Purpose

The critical safety stage. For each matched pair from Stage 2, use LLM verification (`verifyMarketPair` or `smartVerifyPair`) to deeply compare resolution criteria. This catches the dangerous misalignments that similarity scores miss: different dates, different thresholds ("above" vs "reach"), different data sources, different scope. A pair that looks identical on the surface can resolve differently — this stage prevents that from becoming a loss.

## Artifacts

- **Input:** `research/sve-harness/stage-2-cross-platform-matching-output.md`
- **Output:** `research/sve-harness/stage-3-resolution-verification-output.md`

## Command

**Command:** `manual`

## Instructions

1. For each matched pair above the similarity threshold, call `verifyMarketPair` with full market details (question, resolution date, rules, description).
2. Include as much resolution criteria detail as possible — the more context the LLM has, the better it detects misalignments.
3. For each result, record: isMatch, matchConfidence, riskLevel, recommendation, and every misalignment found (type, severity, description, potential impact).
4. Check all six misalignment types explicitly: RESOLUTION_DATE, RESOLUTION_SOURCE, THRESHOLD, SCOPE, DEFINITION, EDGE_CASE. If the LLM didn't check one, flag it as "not assessed."
5. For any pair marked SAFE_TO_TRADE: verify that the reasoning explicitly addresses each dimension. If the reasoning is vague ("markets appear similar"), that is NOT sufficient — send it back for deeper verification or flag as MANUAL_REVIEW.
6. Review your output against the Quality Gate Checklist below.
7. Mark each checklist item as complete (`- [x]`) or leave unchecked with a note.

## Quality Gate Checklist

- [ ] Every matched pair above threshold was sent through LLM verification
- [ ] Each verification result includes: isMatch, confidence, risk level, recommendation, and specific misalignments
- [ ] All six misalignment types checked: RESOLUTION_DATE, RESOLUTION_SOURCE, THRESHOLD, SCOPE, DEFINITION, EDGE_CASE
- [ ] No pair marked SAFE_TO_TRADE without explicit reasoning for why each criteria dimension matches

## Known Failure Modes

**FM-1: LLM says "SAFE" with vague reasoning**
Trigger: Verification returns SAFE_TO_TRADE but reasoning is generic ("markets are about the same topic") without checking specific criteria
Check: SAFE_TO_TRADE must have explicit per-dimension reasoning. If reasoning mentions only the topic and not dates/thresholds/sources, reject it.
Added: 2026-03-16, from design review — LLMs tend to pattern-match on topic similarity and miss resolution detail differences

**FM-2: Missing resolution metadata leading to false confidence**
Trigger: Market data doesn't include resolution date or rules, LLM verifies based only on question text
Check: If resolution date or rules are missing for either market, the pair MUST be flagged as MANUAL_REVIEW regardless of what the LLM says
Added: 2026-03-16, from design review — verification without full metadata is unreliable

## Self-Improvement Hook

When a downstream stage finds that this stage's output was flawed:

1. **Add to Known Failure Modes** above with the FM-N format.
2. **Add a checklist item** that would have caught this specific issue.
3. **Log in memory.md** with the failure, root cause, fix applied, and this file as the file changed.
4. **Commit** with format: `harness-fix(stage-3): description of what was added`
