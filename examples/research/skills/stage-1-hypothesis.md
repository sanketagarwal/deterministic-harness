# Stage 1: Hypothesis

## Purpose

Define a falsifiable claim about a market signal, grounded in a mechanism that identifies a specific economic actor whose behavior creates the opportunity. The hypothesis must survive a cost-of-execution sanity check before any data is collected.

## Artifacts

- **Input:** `research/research/stage-0-idea-notes.md`
- **Output:** `research/research/stage-1-hypothesis-output.md`

## Instructions

1. State the claim in one sentence using the format: "[Actor] does [behavior] because [incentive], creating [observable signal] in [instrument/market]."
2. Define kill criteria: what quantitative thresholds, if not met in Stage 3, would falsify this hypothesis. Write these before touching any data.
3. Estimate execution costs: spread, slippage, market impact at target size, and capacity ceiling. If expected edge does not survive 2x estimated costs, kill here.
4. Identify at least two confounding explanations for the signal and note how Stage 3 or Stage 4 will distinguish them.
5. Review your output against the Quality Gate Checklist below.
6. Mark each checklist item as complete (`- [x]`) or leave unchecked (`- [ ]`) with a note explaining why.

## Quality Gate Checklist

- [x] Mechanism identifies a specific economic actor (not "the market" or "sentiment")
- [x] Kill criteria defined with numeric thresholds before any data is examined
- [x] Edge survives back-of-envelope cost analysis (spread + slippage + impact < 0.5x expected edge)
- [x] At least two confounding explanations listed with planned tests
- [x] Hypothesis is stated as a single falsifiable sentence

## Known Failure Modes

<!-- This section is populated over time from retrospectives and self-improvement analysis.
     Each entry describes a specific failure mode and the mechanical check that prevents it.

     Format:
     **FM-N: Short description**
     Trigger: What situation causes this failure
     Check: What to verify to prevent it
     Added: Date, from retrospective/self-improvement of run X
-->

**FM-1: Mechanism names a category instead of an actor**
Trigger: Hypothesis says "institutional investors" without specifying which type (pension rebalancing, index funds, market makers)
Check: Actor must be specific enough that you could name 3 real-world entities that fit
Added: 2026-03-04, from retrospective of run 2

## Self-Improvement Hook

When a downstream stage (especially Verification) finds that this stage's output was flawed:

1. **Add to Known Failure Modes** above with the FM-N format.
2. **Add a checklist item** to the Quality Gate Checklist that would have caught this specific issue.
3. **Log in memory.md** with the failure, root cause, fix applied, and this file as the file changed.
4. **Commit** with message format: `harness-fix(stage-1): description of what was added`
