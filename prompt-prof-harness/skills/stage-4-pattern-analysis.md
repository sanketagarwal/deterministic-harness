# Stage 4: Pattern Analysis

## Purpose
Aggregate per-prompt scores and classifications into actionable, user-facing insights. This stage moves from individual data points to behavioral patterns — identifying what the user does well, what costs them time or tokens, and what concrete changes would improve their prompt effectiveness across sessions.

## Artifacts
- **Input:** `research/prompt-prof/stage-3-quality-scoring-output.md`
- **Output:** `research/prompt-prof/stage-4-pattern-analysis-output.md`

## Command
**Command:** `manual`

## Instructions
1. Load the scored and classified prompt list from the Stage 3 output artifact.
2. Identify the top 10 highest-scoring and bottom 10 lowest-scoring prompts. For each, note the classification type and which dimension(s) drove the score up or down.
3. Compute per-type distribution statistics: count, mean score, median score, and score range for each of the six classification types.
4. Generate at least 2 actionable recommendations grounded in the data. Each recommendation must reference specific patterns (e.g., "Your File Operations prompts average 82 but Code Generation prompts average 54 — adding file paths and expected behavior to code requests could close that gap"). Avoid generic advice like "be more specific."
5. Perform cost analysis: estimate total tokens consumed, identify the most token-expensive sessions or prompt chains, and flag retry sequences where rephrased prompts consumed tokens without new value.

## Quality Gate Checklist
- [ ] Top 10 and bottom 10 prompts identified with per-dimension attribution
- [ ] Per-type distribution computed for all classification types present in the data
- [ ] At least 2 actionable recommendations generated, each referencing specific data from this analysis
- [ ] Cost analysis included with total token estimate and identification of most expensive prompt chains

## Known Failure Modes
### FM-1: Generic recommendations that don't change behavior
- **Trigger:** Recommendations use phrases like "be more specific," "provide more context," or "write clearer prompts" without referencing concrete data points, score comparisons, or specific prompt examples.
- **Check:** After generating recommendations, verify each one contains at least: (a) a specific metric or comparison from the analysis, (b) a concrete before/after example or a reference to a specific prompt from the dataset, and (c) an expected impact estimate. If any recommendation fails this check, rewrite it by grounding it in the top/bottom prompt comparison or per-type score gaps.

## Self-Improvement Hook
After completing Stage 4, review the quality gate checklist results and the recommendations. If any items failed or new pattern types were discovered, append a `## Retrospective` section to `research/prompt-prof/stage-4-pattern-analysis-output.md` documenting:
- What failed and why
- The fix or workaround applied
- Whether this failure mode should be added to Known Failure Modes for future runs
