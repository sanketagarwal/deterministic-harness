# Stage 2: Cross-Platform Matching

## Purpose

For each market found in Stage 1, find the most similar market on the opposing venue. Use `findOverlapMarkets` for API-level matching and `calculateEmbeddingSimilarity` / `batchEmbeddingSimilarity` for fast pre-filtering. This stage narrows hundreds of markets to a handful of plausible cross-venue pairs. High similarity does NOT mean equivalent — that's Stage 3's job.

## Artifacts

- **Input:** `research/sve-harness/stage-1-market-discovery-output.md`
- **Output:** `research/sve-harness/stage-2-cross-platform-matching-output.md`

## Command

**Command:** `manual`

## Instructions

1. For each Polymarket market from Stage 1, call `findOverlapMarkets` to find Kalshi matches (and vice versa).
2. For pairs with scores in the 50-70% range, run `calculateEmbeddingSimilarity` to get a more precise score — these borderline pairs are where dangerous misalignments hide.
3. Record each pair with: both market IDs, both questions side-by-side, similarity score, and match method (API overlap vs. embedding).
4. Filter out pairs below 65% similarity — but list them explicitly as "filtered" with their score (do NOT silently drop them).
5. Sort remaining pairs by similarity score descending.
6. Review your output against the Quality Gate Checklist below.
7. Mark each checklist item as complete (`- [x]`) or leave unchecked with a note.

## Quality Gate Checklist

- [ ] Every market from Stage 1 was checked for cross-venue matches
- [ ] Embedding similarity score computed for each pair
- [ ] Pairs below 65% similarity threshold explicitly listed as filtered out (not silently dropped)
- [ ] Top matches include both similarity score AND the questions side-by-side for human review

## Known Failure Modes

<!-- Populated over time from retrospectives and self-improvement analysis. -->

**FM-1: High similarity score masking critical differences**
Trigger: Two markets with 80%+ similarity have different resolution dates, thresholds, or scope
Check: Similarity score alone is never sufficient — every pair above threshold MUST go through Stage 3 LLM verification regardless of how high the score is
Added: 2026-03-16, from design review of the SVE verification flow

## Self-Improvement Hook

When a downstream stage finds that this stage's output was flawed:

1. **Add to Known Failure Modes** above with the FM-N format.
2. **Add a checklist item** that would have caught this specific issue.
3. **Log in memory.md** with the failure, root cause, fix applied, and this file as the file changed.
4. **Commit** with format: `harness-fix(stage-2): description of what was added`
