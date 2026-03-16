# Stage 2: Data Collection

## Purpose

Gather, clean, and validate all data required to test the hypothesis from Stage 1. Every gap, adjustment, and limitation must be documented so that downstream stages can assess whether the data supports valid inference.

## Artifacts

- **Input:** `research/research/stage-1-hypothesis-output.md`
- **Output:** `research/research/stage-2-data-collection-output.md`

## Instructions

1. List every data source required by the hypothesis. For each source, record: provider, frequency, start date, known limitations.
2. Normalize all timestamps to UTC. Document the original timezone and conversion method for each source.
3. Identify and document all gaps: missing dates, halted trading sessions, corporate actions, data vendor outages. For each gap, state duration, likely cause, and whether it biases the test.
4. Verify execution feasibility: check that the instruments in the hypothesis were actually tradeable during the test period (sufficient volume, reasonable spreads, no delisting).
5. Produce a data manifest summarizing row counts, date ranges, and coverage statistics.
6. Review your output against the Quality Gate Checklist below.
7. Mark each checklist item as complete (`- [x]`) or leave unchecked (`- [ ]`) with a note explaining why.

## Quality Gate Checklist

- [x] All timestamps normalized to UTC with original timezone and conversion method documented
- [x] Data gaps documented with duration, cause, and impact assessment for each
- [x] Execution feasibility verified: fill rates, median spread, and daily volume for each instrument
- [x] Data manifest produced with row counts, date ranges, and coverage statistics
- [x] Survivorship bias check: confirmed dataset includes delisted/dead instruments where relevant

## Known Failure Modes

<!-- This section is populated over time from retrospectives and self-improvement analysis.
     Each entry describes a specific failure mode and the mechanical check that prevents it.

     Format:
     **FM-N: Short description**
     Trigger: What situation causes this failure
     Check: What to verify to prevent it
     Added: Date, from retrospective/self-improvement of run X
-->

**FM-1: Treated exchange-local timestamps as UTC**
Trigger: Data vendor provides timestamps without explicit timezone label
Check: For every data source, document the original timezone. Convert and verify against a known reference event (e.g., market open)
Added: 2026-03-12, from failure registry entry on timezone shift errors

**FM-2: Used point-in-time-violated data**
Trigger: Data vendor backfills or revises historical values silently
Check: Confirm data is point-in-time or document which fields are subject to revision and the typical revision window
Added: 2026-03-14, from retrospective of run 4

## Self-Improvement Hook

When a downstream stage (especially Verification) finds that this stage's output was flawed:

1. **Add to Known Failure Modes** above with the FM-N format.
2. **Add a checklist item** to the Quality Gate Checklist that would have caught this specific issue.
3. **Log in memory.md** with the failure, root cause, fix applied, and this file as the file changed.
4. **Commit** with message format: `harness-fix(stage-2): description of what was added`
