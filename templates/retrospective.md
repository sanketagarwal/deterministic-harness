# Pipeline Retrospective

**Pipeline:** {{PIPELINE_NAME}}
**Run:** {{RUN_NUMBER}}
**Date:** {{DATE}}
**Verdict:** PURSUE | INVESTIGATE | MONITOR | ARCHIVE

---

## Rules

1. **Every entry must result in a file change.** If nothing changed, the retrospective is incomplete.
2. Every fix must be committed with format: `harness-fix(stage-N): description`
3. After completing this retrospective, run `git log` to confirm all fixes appear as commits.

---

## Entries

### Entry 1

**What happened:** {{Describe the failure or suboptimal outcome}}
**Why the system allowed it:** {{Which gate, checklist, or failure mode should have prevented this? Why didn't it?}}
**File changed:** `{{path/to/file}}`
**What changed:** {{Specific change made — new checklist item, new failure mode, modified gate condition}}
**Committed:** [ ]

### Entry 2

**What happened:** {{description}}
**Why the system allowed it:** {{explanation}}
**File changed:** `{{path/to/file}}`
**What changed:** {{specific change}}
**Committed:** [ ]

### Entry 3

**What happened:** {{description}}
**Why the system allowed it:** {{explanation}}
**File changed:** `{{path/to/file}}`
**What changed:** {{specific change}}
**Committed:** [ ]

---

## Verification

Run the following to confirm all fixes are committed:

```bash
git log --oneline | grep "harness-fix"
```

Expected: one commit per entry above. If any entry has "Committed: [ ]", the retrospective is incomplete.

---

## Pipeline Health

**Reliability before this run:** {{percentage}}
**Reliability after fixes:** {{percentage}}
**Trend:** improving | stable | degrading

Update `memory.md` Pipeline Reliability table with these numbers.
