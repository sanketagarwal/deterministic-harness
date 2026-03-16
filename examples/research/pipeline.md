# Quantitative Research Pipeline

**Domain:** Quantitative Research / Signal Discovery
**Created:** 2026-03-01
**Stages:** 5

---

## Pipeline Stages

### Stage 1: Hypothesis

**Purpose:** Define a falsifiable claim with a mechanism that identifies an economic actor whose behavior creates the signal.
**Gate type:** human
**Input artifact:** `research/research/stage-0-idea-notes.md`
**Output artifact:** `research/research/stage-1-hypothesis-output.md`

#### Quality Gate Checklist
- [x] Mechanism identifies a specific economic actor
- [x] Kill criteria defined before any data is touched
- [x] Edge survives back-of-envelope cost analysis (spread, slippage, capacity)

#### Known Failure Modes
<!-- Populated over time from retrospectives and self-improvement analysis -->

---

### Stage 2: Data Collection

**Purpose:** Gather, clean, and validate the data required to test the hypothesis. Document every gap and limitation.
**Gate type:** auto
**Input artifact:** `research/research/stage-1-hypothesis-output.md`
**Output artifact:** `research/research/stage-2-data-collection-output.md`

#### Quality Gate Checklist
- [x] All timestamps normalized to UTC with timezone source documented
- [x] Data gaps documented with duration, cause, and impact assessment
- [x] Execution feasibility verified (fill rates, queue position, latency)

#### Known Failure Modes
<!-- Populated over time from retrospectives and self-improvement analysis -->

---

### Stage 3: Analysis

**Purpose:** Test whether the hypothesized signal exists in the data. Produce a proceed/kill recommendation with quantified confidence.
**Gate type:** auto
**Input artifact:** `research/research/stage-2-data-collection-output.md`
**Output artifact:** `research/research/stage-3-analysis-output.md`

#### Quality Gate Checklist
- [x] Every feature has a stated economic rationale (not just statistical correlation)
- [x] Temporal stability checked across at least 3 non-overlapping periods
- [x] Proceed/kill recommendation made with explicit confidence level

#### Known Failure Modes
<!-- Populated over time from retrospectives and self-improvement analysis -->

---

### Stage 4: Verification

**Purpose:** Adversarially attack the findings from Stage 3. Try to break them through alternative explanations, robustness checks, and base rate comparisons. Includes self-improvement analysis of prior stages.
**Gate type:** human
**Input artifact:** `research/research/stage-3-analysis-output.md`
**Output artifact:** `research/research/stage-4-verification-output.md`

#### Quality Gate Checklist
- [x] Alternative explanations tested with quantified impact (not just listed)
- [x] Base rate established for the claimed effect size
- [x] At least 3 robustness attacks run (parameter perturbation, data exclusion, regime split)
- [x] Self-improvement analysis completed: upstream stage flaws logged

#### Known Failure Modes
<!-- Populated over time from retrospectives and self-improvement analysis -->

---

### Stage 5: Synthesis

**Purpose:** Produce a traceable verdict that maps every claim to supporting data and references all prior stages. Spawn follow-up hypotheses.
**Gate type:** human
**Input artifact:** `research/research/stage-4-verification-output.md`
**Output artifact:** `research/research/stage-5-synthesis-output.md`

#### Quality Gate Checklist
- [x] Every claim in the verdict is mapped to a specific data point or analysis result
- [x] All five stages referenced with explicit pass/fail summary
- [x] At least one new hypothesis spawned from findings or failures

#### Known Failure Modes
<!-- Populated over time from retrospectives and self-improvement analysis -->

---

## Gate Rules

**Human Gate:** Requires explicit human approval before the pipeline advances. The agent produces its output and checklist, then waits. A human reviews and creates an approval file at `research/project/.gate-{stage}-approved` to unlock the next stage. The agent cannot create this file.

**Auto Gate:** The gate enforcer checks mechanically — output artifact exists, all checklist items checked. If both conditions are met, the pipeline advances automatically. No human in the loop.

**Default assignment:** First and last stages use human gates. Middle stages use auto gates. Override per stage as needed. Stage 4 (Verification) is elevated to human gate because adversarial review demands human judgment.

---

## Verdicts

Every pipeline run ends with one of these verdicts:

- **PURSUE** — Signal is strong, proceed to execution/deployment.
- **INVESTIGATE** — Signal exists but needs more work before committing resources.
- **MONITOR** — Not actionable now, but worth tracking. Define what would change the verdict.
- **ARCHIVE** — No signal found, or signal is not worth pursuing. Document why.

Any stage can kill the pipeline. A documented kill with clear reasoning is a successful outcome — it prevents wasted effort downstream.
