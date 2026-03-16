# {{PIPELINE_NAME}} Pipeline

**Domain:** {{DOMAIN}}
**Created:** {{DATE}}
**Stages:** {{NUM_STAGES}}

---

## Pipeline Stages

{{STAGES}}

---

## Gate Rules

**Human Gate:** Requires explicit human approval before the pipeline advances. The agent produces its output and checklist, then waits. A human reviews and creates an approval file at `research/{{PROJECT}}/.gate-{stage}-approved` to unlock the next stage. The agent cannot create this file.

**Auto Gate:** The gate enforcer checks mechanically — output artifact exists, all checklist items checked. If both conditions are met, the pipeline advances automatically. No human in the loop.

**Default assignment:** First and last stages use human gates. Middle stages use auto gates. Override per stage as needed.

---

## Verdicts

Every pipeline run ends with one of these verdicts:

- **PURSUE** — Signal is strong, proceed to execution/deployment.
- **INVESTIGATE** — Signal exists but needs more work before committing resources.
- **MONITOR** — Not actionable now, but worth tracking. Define what would change the verdict.
- **ARCHIVE** — No signal found, or signal is not worth pursuing. Document why.

Any stage can kill the pipeline. A documented kill with clear reasoning is a successful outcome — it prevents wasted effort downstream.

---

## Stage Template

For each stage, define:

```
### Stage N: {{STAGE_NAME}}

**Purpose:** {{one-line description}}
**Gate type:** human | auto
**Input artifact:** {{file path}}
**Output artifact:** {{file path}}

#### Quality Gate Checklist
- [ ] {{item 1}}
- [ ] {{item 2}}
- [ ] {{item 3}}

#### Known Failure Modes
<!-- Populated over time from retrospectives and self-improvement analysis -->
```
