# Stage {{STAGE_NUM}}: {{STAGE_NAME}}

## Purpose

{{Describe in 2-3 lines what this stage does, what decisions it makes, and what it produces.}}

## Artifacts

- **Input:** `{{INPUT_PATH}}`
- **Output:** `{{OUTPUT_PATH}}`

## Instructions

1. {{Step 1}}
2. {{Step 2}}
3. {{Step 3}}
4. Review your output against the Quality Gate Checklist below.
5. Mark each checklist item as complete (`- [x]`) or leave unchecked (`- [ ]`) with a note explaining why.

## Quality Gate Checklist

- [ ] {{Checklist item 1}}
- [ ] {{Checklist item 2}}
- [ ] {{Checklist item 3}}

## Known Failure Modes

<!-- This section is populated over time from retrospectives and self-improvement analysis.
     Each entry describes a specific failure mode and the mechanical check that prevents it.

     Format:
     **FM-N: Short description**
     Trigger: What situation causes this failure
     Check: What to verify to prevent it
     Added: Date, from retrospective/self-improvement of run X

     Examples from different domains (for reference only, do not include in checklist grep):

     Research domain example:
     **FM-1: Listed confound without testing it**
     Trigger: Analysis stage identifies a confounding variable
     Check: Every confound mentioned must have a corresponding test with quantified impact
     Added: 2026-01-15, from retrospective of run 3

     Software engineering example:
     **FM-1: Marked tests passing without running E2E suite**
     Trigger: Unit tests pass but integration/E2E tests not executed
     Check: Test output log must contain E2E test runner output
     Added: 2026-02-01, from retrospective of run 5
-->

## Self-Improvement Hook

When a downstream stage (especially Verification) finds that this stage's output was flawed:

1. **Add to Known Failure Modes** above with the FM-N format.
2. **Add a checklist item** to the Quality Gate Checklist that would have caught this specific issue.
3. **Log in memory.md** with the failure, root cause, fix applied, and this file as the file changed.
4. **Commit** with message format: `harness-fix(stage-{{STAGE_NUM}}): description of what was added`

If you cannot identify a specific, mechanical change to make, document why in the Open Failure Modes table in memory.md.
