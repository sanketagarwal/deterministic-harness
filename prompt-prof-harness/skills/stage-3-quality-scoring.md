# Stage 3: Quality Scoring

## Purpose
Score each prompt on a 0-100 scale across four equally weighted dimensions to quantify prompt effectiveness. The scoring produces per-prompt breakdowns that feed into pattern analysis and report generation, enabling users to see exactly which dimension drags down a weak prompt and which strengths define their best work.

## Artifacts
- **Input:** `research/prompt-prof/stage-2-prompt-classification-output.md`
- **Output:** `research/prompt-prof/stage-3-quality-scoring-output.md`

## Command
**Command:** `manual`

## Instructions
1. Load the classified prompt list from the Stage 2 output artifact.
2. Score each prompt across four dimensions, each weighted 25% of the total:
   - **Clarity (25%)** — Is the intent unambiguous? Are requirements specific? Does it avoid vague language?
   - **Context (25%)** — Does the prompt provide sufficient background, file paths, error messages, or constraints for the AI to act without guessing?
   - **Efficiency (25%)** — Does the prompt achieve its goal concisely? Are there unnecessary retries or redundant instructions? Detect retry chains (same intent rephrased within a session) and penalize accordingly.
   - **Outcome (25%)** — Did the AI response resolve the request? Were follow-up corrections needed? Was the result accepted or rejected?
3. For CLI commands and simple file operations, score Clarity and Context leniently — a well-formed command like "run npm test" is inherently clear and needs minimal context.
4. Detect retry patterns: if 2+ consecutive prompts in a session share the same intent, flag the sequence and apply an Efficiency penalty to the later prompts in the chain.
5. Write per-prompt score breakdowns and a score distribution summary (histogram buckets: 0-20, 21-40, 41-60, 61-80, 81-100) to the output artifact.

## Quality Gate Checklist
- [x] Every prompt has a per-dimension breakdown (Clarity, Context, Efficiency, Outcome) and a composite score
- [ ] Score distribution is not flat — BLOCKED: 96% score 50-69, std dev likely <10 points
- [x] Retry detection identifies and penalizes repeated-intent prompt chains
- [x] Edge cases handled: empty prompts scored 0, single-word commands scored on appropriate rubric
- [ ] CLI commands and simple actions are scored appropriately — BLOCKED: "Tool loaded." scores 50 but is a system artifact, not a user prompt

## Known Failure Modes
### FM-1: Flat scoring distribution — all prompts score 50-60
- **Trigger:** Standard deviation of composite scores is below 10, or more than 70% of prompts land in the 41-60 bucket.
- **Check:** After scoring, compute the standard deviation and bucket percentages. If the trigger condition is met, review the scoring rubric for insufficient differentiation — likely the Clarity or Context dimension is defaulting to a midpoint instead of using the full range. Recalibrate by anchoring: identify the objectively best and worst prompts in the set, score them first, then re-score the rest relative to those anchors.

### FM-2: Effective score range too narrow (max - min < 40)
- **Trigger:** The highest score is below 80 and/or the lowest score is above 40, creating an effective range under 40 points.
- **Check:** After scoring, compute max and min scores. If range < 40, the rubric's bonuses and penalties are too small. Increase file-reference bonus from +10 to +15, increase vague-command penalty from -15 to -25, and add compound bonuses for prompts that hit 3+ clarity factors.
- **Added:** 2026-03-16, from pipeline run 1 — max score was 72, min was 46, range of only 26 points.

## Self-Improvement Hook
After completing Stage 3, review the quality gate checklist results and the score distribution. If any items failed or scoring edge cases were discovered, append a `## Retrospective` section to `research/prompt-prof/stage-3-quality-scoring-output.md` documenting:
- What failed and why
- The fix or workaround applied
- Whether this failure mode should be added to Known Failure Modes for future runs
