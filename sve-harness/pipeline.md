# sve-harness Pipeline

**Domain:** Cross-platform prediction market verification — detecting resolution criteria misalignments between Kalshi and Polymarket to prevent bad arbitrage trades
**Created:** 2026-03-16
**Stages:** 6

---

### Stage 1: Market Discovery

**Purpose:** Search for markets across Kalshi and Polymarket that appear to cover the same topic. This is the intake stage — cast a wide net using both keyword and semantic search. The goal is to find candidate pairs, not to verify them yet.
**Gate type:** auto
**Input artifact:** `(pipeline input — search query or market topic)`
**Output artifact:** `research/sve-harness/stage-1-market-discovery-output.md`

#### Quality Gate Checklist
- [ ] Both venues (Kalshi AND Polymarket) returned results
- [ ] At least 3 candidate markets found per venue
- [ ] Search used both keyword and semantic search methods
- [ ] Each market has: ID, question text, venue, and active status recorded

#### Known Failure Modes
<!-- Populated over time from retrospectives -->

---

### Stage 2: Cross-Platform Matching

**Purpose:** For each market on one venue, find the most similar market on the other venue using the overlap API and embedding similarity. Rank pairs by match score. Filter out pairs below the similarity threshold (65%). This stage narrows the candidate set to plausible pairs.
**Gate type:** auto
**Input artifact:** `research/sve-harness/stage-1-market-discovery-output.md`
**Output artifact:** `research/sve-harness/stage-2-cross-platform-matching-output.md`

#### Quality Gate Checklist
- [ ] Every market from Stage 1 was checked for cross-venue matches
- [ ] Embedding similarity score computed for each pair
- [ ] Pairs below 65% similarity threshold explicitly listed as filtered out (not silently dropped)
- [ ] Top matches include both similarity score AND the questions side-by-side for human review

#### Known Failure Modes
<!-- Populated over time from retrospectives -->

---

### Stage 3: Resolution Criteria Verification

**Purpose:** For each matched pair, use LLM verification (GPT-4o) to deeply compare resolution criteria: dates, thresholds, data sources, scope, edge cases. This is where the real safety check happens. A high embedding similarity does NOT mean markets are equivalent — "Bitcoin above $100k by Feb 1" and "Bitcoin reaches $100k by Dec 31" have 83% similarity but are NOT the same market.
**Gate type:** auto
**Input artifact:** `research/sve-harness/stage-2-cross-platform-matching-output.md`
**Output artifact:** `research/sve-harness/stage-3-resolution-verification-output.md`

#### Quality Gate Checklist
- [ ] Every matched pair above threshold was sent through LLM verification
- [ ] Each verification result includes: isMatch, confidence, risk level, recommendation, and specific misalignments
- [ ] All six misalignment types checked: RESOLUTION_DATE, RESOLUTION_SOURCE, THRESHOLD, SCOPE, DEFINITION, EDGE_CASE
- [ ] No pair marked SAFE_TO_TRADE without explicit reasoning for why each criteria dimension matches

#### Known Failure Modes
<!-- Populated over time from retrospectives -->

---

### Stage 4: Risk Assessment

**Purpose:** Aggregate verification results into a risk profile. For each pair: what is the probability that one resolves YES and the other NO? What is the maximum loss if the misalignment materializes? Factor in confidence level, misalignment severity, and market liquidity. A HIGH risk pair with AVOID recommendation must be killed here — do not advance it to trading consideration.
**Gate type:** human
**Input artifact:** `research/sve-harness/stage-3-resolution-verification-output.md`
**Output artifact:** `research/sve-harness/stage-4-risk-assessment-output.md`

#### Quality Gate Checklist
- [ ] Every pair has a risk profile with: risk level, max loss scenario, and probability estimate
- [ ] All HIGH and CRITICAL risk pairs explicitly marked AVOID with reasoning
- [ ] PROCEED_WITH_CAUTION pairs have specific conditions documented (what would make them unsafe)
- [ ] Cost analysis included: embedding cost, LLM verification cost, total cost vs. potential arbitrage profit

#### Known Failure Modes
<!-- Populated over time from retrospectives -->

---

### Stage 5: Recommendation & Report

**Purpose:** Produce the final recommendation for each pair. SAFE_TO_TRADE pairs get a green light with position sizing guidance. AVOID pairs get documented with why. This stage also checks for any pairs that were dropped, filtered, or overlooked in earlier stages — nothing should silently disappear from the pipeline.
**Gate type:** auto
**Input artifact:** `research/sve-harness/stage-4-risk-assessment-output.md`
**Output artifact:** `research/sve-harness/stage-5-recommendation-output.md`

#### Quality Gate Checklist
- [ ] Every pair from Stage 2 has a final status (SAFE_TO_TRADE, PROCEED_WITH_CAUTION, AVOID, MANUAL_REVIEW)
- [ ] No pairs disappeared between stages — count at Stage 2 equals count at Stage 5
- [ ] SAFE_TO_TRADE recommendations include: market IDs, venues, confidence, and specific conditions that would invalidate the trade
- [ ] TypeScript build succeeds: `npx tsc --noEmit`

#### Known Failure Modes
<!-- Populated over time from retrospectives -->

---

### Stage 6: Self-Improvement & Retrospective

**Purpose:** Review the entire pipeline run. Did any verification miss a misalignment that a human caught? Did any "safe" pair turn out to have hidden issues? Trace every issue back to the stage that should have caught it, and commit a mechanical fix. This stage is how the pipeline gets better.
**Gate type:** human
**Input artifact:** `research/sve-harness/stage-5-recommendation-output.md`
**Output artifact:** `research/sve-harness/stage-6-retrospective-output.md`

#### Quality Gate Checklist
- [ ] Every issue found traced to upstream stage with proposed fix
- [ ] All fixes committed with `harness-fix(stage-N):` format
- [ ] Reliability estimate updated in memory.md with reasoning
- [ ] `git log --oneline | grep "harness-fix"` shows commits for all fixes

#### Known Failure Modes
<!-- Populated over time from retrospectives -->

---

## Gate Rules

**Human Gate:** Requires explicit human approval before advancing. The agent produces output and checklist, then waits. A human reviews and creates an approval file at `research/sve-harness/.gate-{stage}-approved`.

**Auto Gate:** Gate enforcer checks mechanically — output artifact exists, all checklist items checked. Advances automatically if both conditions are met.

---

## Verdicts

- **PURSUE** — Safe to trade, markets are equivalent.
- **INVESTIGATE** — Similarity is high but verification found issues worth examining.
- **MONITOR** — Markets might converge or new data might clarify — watch but don't trade.
- **ARCHIVE** — Markets are not equivalent, or risk is too high. Document the specific misalignment.

Any stage can kill the pipeline. An AVOID recommendation with clear reasoning is a successful outcome — it prevented a bad trade.
