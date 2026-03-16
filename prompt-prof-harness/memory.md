# prompt-prof-harness — Failure Registry

**Created:** 2026-03-16

This is NOT a general notes file. This is a failure registry. Every entry documents a failure, its root cause, and the mechanical fix applied. **Every entry must document what file changed. If nothing changed, the entry is incomplete.**

---

## Failure Registry

| Date | Stage | Failure | Root Cause | Fix Applied | File Changed |
|------|-------|---------|------------|-------------|--------------|
| 2026-03-16 | 3 (Quality Scoring) | 96% of prompts score 50-69 — scoring lacks discriminating power | Scoring rubric point values too compressed: best-to-worst gap per dimension is only ~25-30 points, resulting in effective range of 46-72 | Added FM-2 to stage 3 skill: scoring must produce std dev >10 or rubric needs recalibration | skills/stage-3-quality-scoring.md |
| 2026-03-16 | 1 (Session Parsing) | "Tool loaded." system artifacts parsed as user prompts | Parser doesn't filter system-generated messages vs user-authored prompts | Added FM-1 to stage 1 skill: system artifacts must be filtered or tagged before scoring | skills/stage-1-session-parsing.md |

### Rules

1. Every row must have a value in "File Changed." If you cannot name the file, the fix is not mechanical and the entry is incomplete.
2. The fix must be committed with format: `harness-fix(stage-N): description`
3. After adding a fix, update the Pipeline Reliability table below.

---

## Pipeline Reliability

| Date | Estimated Reliability | Change | Reason |
|------|----------------------|--------|--------|
| 2026-03-16 | 70% | baseline | Initial pipeline setup |

Track reliability as a rough percentage. After each fix, estimate the new reliability and explain why.

---

## Open Failure Modes

Known issues without mechanical fixes yet. Each entry should be actively worked toward a fix.

| Date Identified | Stage | Failure Mode | Why No Fix Yet | Owner |
|----------------|-------|--------------|----------------|-------|
| | | | | |
