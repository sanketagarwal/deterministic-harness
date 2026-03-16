# Quantitative Research — Failure Registry

**Created:** 2026-03-01

This is NOT a general notes file. This is a failure registry. Every entry documents a failure, its root cause, and the mechanical fix applied. **Every entry must document what file changed. If nothing changed, the entry is incomplete.**

---

## Failure Registry

| Date | Stage | Failure | Root Cause | Fix Applied | File Changed |
|------|-------|---------|------------|-------------|--------------|
| 2026-03-05 | 4 | Listed confound (index rebalancing) without testing its impact | Verification checklist allowed naming confounds without quantifying them | Added checklist item: "Alternative explanations tested with quantified impact (not just listed)" | `skills/stage-4-verification.md` |
| 2026-03-08 | 3 | Locked test spec for assets with no historical data before 2019 | Analysis stage did not verify data availability before defining the test universe | Added FM-2 and checklist item: require minimum history length check before including asset in test universe | `skills/stage-3-analysis.md` |
| 2026-03-12 | 2 | Treated exchange-local timestamps as UTC, shifted signals by hours | Data collection did not enforce timezone normalization step | Added checklist item: "All timestamps normalized to UTC with timezone source documented" and FM-1 to stage 2 | `skills/stage-2-data-collection.md` |

### Rules

1. Every row must have a value in "File Changed." If you cannot name the file, the fix is not mechanical and the entry is incomplete.
2. The fix must be committed with format: `harness-fix(stage-N): description`
3. After adding a fix, update the Pipeline Reliability table below.

---

## Pipeline Reliability

| Date | Estimated Reliability | Change | Reason |
|------|----------------------|--------|--------|
| 2026-03-01 | Baseline | — | Initial pipeline setup |
| 2026-03-05 | ~60% | +15% from baseline | Verification now forces quantified confound testing instead of listing |
| 2026-03-08 | ~70% | +10% | Analysis stage catches insufficient data history before locking test spec |
| 2026-03-12 | ~80% | +10% | Timezone normalization enforced at data collection, prevents downstream shift errors |

Track reliability as a rough percentage. After each fix, estimate the new reliability and explain why.

---

## Open Failure Modes

Known issues without mechanical fixes yet. Each entry should be actively worked toward a fix.

| Date Identified | Stage | Failure Mode | Why No Fix Yet | Owner |
|----------------|-------|--------------|----------------|-------|
| 2026-03-10 | 5 | Synthesis verdict sometimes omits stage 2 data quality caveats | Need to define which caveats are material vs. cosmetic before adding a checklist item | Research lead |
