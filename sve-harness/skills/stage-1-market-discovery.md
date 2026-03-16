# Stage 1: Market Discovery

## Purpose

Search for prediction markets across Kalshi and Polymarket that cover the same topic. Cast a wide net — use both keyword search (`searchMarkets`) and semantic search (`semanticSearchMarkets`) to find candidate markets. Record everything found; filtering happens in Stage 2.

## Artifacts

- **Input:** `(pipeline input — search query or market topic, e.g., "Bitcoin $100k")`
- **Output:** `research/sve-harness/stage-1-market-discovery-output.md`

## Command

**Command:** `manual`

## Instructions

1. Take the input query/topic and run `searchMarkets` with the query against both venues.
2. Run `semanticSearchMarkets` with the same query — this catches markets that use different wording for the same concept (e.g., "BTC" vs "Bitcoin", "reach" vs "above").
3. Deduplicate results by market ID.
4. For each market, record: market ID, venue (KALSHI/POLYMARKET), question text, active status, resolution date if available.
5. If one venue returns 0 results, try broader search terms before marking as empty.
6. Review your output against the Quality Gate Checklist below.
7. Mark each checklist item as complete (`- [x]`) or leave unchecked with a note.

## Quality Gate Checklist

- [ ] Both venues (Kalshi AND Polymarket) returned results
- [ ] At least 3 candidate markets found per venue
- [ ] Search used both keyword and semantic search methods
- [ ] Each market has: ID, question text, venue, and active status recorded

## Known Failure Modes

<!-- Populated over time from retrospectives and self-improvement analysis.
     Format:
     **FM-N: Short description**
     Trigger: What situation causes this failure
     Check: What to verify to prevent it
     Added: Date, from retrospective/self-improvement of run X
-->

## Self-Improvement Hook

When a downstream stage finds that this stage's output was flawed:

1. **Add to Known Failure Modes** above with the FM-N format.
2. **Add a checklist item** that would have caught this specific issue.
3. **Log in memory.md** with the failure, root cause, fix applied, and this file as the file changed.
4. **Commit** with format: `harness-fix(stage-1): description of what was added`
