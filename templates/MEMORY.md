# {{PIPELINE_NAME}} — Failure Registry

**Created:** {{DATE}}

This is NOT a general notes file. This is a failure registry. Every entry documents a failure, its root cause, and the mechanical fix applied. **Every entry must document what file changed. If nothing changed, the entry is incomplete.**

---

## Failure Registry

| Date | Stage | Failure | Root Cause | Fix Applied | File Changed |
|------|-------|---------|------------|-------------|--------------|
| | | | | | |

### Rules

1. Every row must have a value in "File Changed." If you cannot name the file, the fix is not mechanical and the entry is incomplete.
2. The fix must be committed with format: `harness-fix(stage-N): description`
3. After adding a fix, update the Pipeline Reliability table below.

---

## Pipeline Reliability

| Date | Estimated Reliability | Change | Reason |
|------|----------------------|--------|--------|
| {{DATE}} | Baseline | — | Initial pipeline setup |

Track reliability as a rough percentage. After each fix, estimate the new reliability and explain why.

---

## Open Failure Modes

Known issues without mechanical fixes yet. Each entry should be actively worked toward a fix.

| Date Identified | Stage | Failure Mode | Why No Fix Yet | Owner |
|----------------|-------|--------------|----------------|-------|
| | | | | |
