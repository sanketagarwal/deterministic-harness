# Self-Improvement Analysis

**Pipeline:** {{PIPELINE_NAME}}
**Run:** {{RUN_NUMBER}}
**Date:** {{DATE}}
**Analyst:** {{ANALYST}}

---

## Issues Found During Verification

For each issue, trace it back to the stage that should have caught it.

### Issue 1: {{SHORT_DESCRIPTION}}

**Found in:** Stage {{N}}
**Should have been caught in:** Stage {{M}}
**Why the quality gate didn't catch it:** {{Explain specifically — was the checklist missing an item? Was the item too vague? Was there no failure mode entry?}}

**Proposed fix:**
- **File:** `{{path/to/file}}`
- **Change:** {{Specific change — add checklist item, add failure mode, modify gate condition}}
- **Severity:** high | medium | low

---

### Issue 2: {{SHORT_DESCRIPTION}}

**Found in:** Stage {{N}}
**Should have been caught in:** Stage {{M}}
**Why the quality gate didn't catch it:** {{explanation}}

**Proposed fix:**
- **File:** `{{path/to/file}}`
- **Change:** {{specific change}}
- **Severity:** high | medium | low

---

## Summary of Changes

| # | File | Change Description | Severity | Committed? |
|---|------|--------------------|----------|------------|
| 1 | | | | [ ] |
| 2 | | | | [ ] |

**Rule:** Every row must be committed with format `harness-fix(stage-N): description`. If the "Committed?" box is unchecked, the improvement has not been applied.

---

## Reliability Impact

**Before this run:** {{estimated reliability, e.g., 75%}}
**After applying fixes:** {{estimated reliability, e.g., 80%}}
**Reasoning:** {{Why do you expect this improvement? Which failure modes are now mechanically prevented?}}

Update the Pipeline Reliability table in `memory.md` after committing all fixes.
