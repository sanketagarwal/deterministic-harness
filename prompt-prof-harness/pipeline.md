# prompt-prof-harness Pipeline

**Domain:** AI prompt effectiveness analysis — parsing session data from Claude Code and Cursor, classifying prompt types, scoring quality across 4 dimensions, detecting patterns, and generating actionable reports
**Created:** 2026-03-16
**Stages:** 5

---

### Stage 1: Session Parsing & Data Ingestion

**Purpose:** Parse raw session data from Claude Code (~/.claude/) and Cursor (~/.cursor/) into structured prompt objects. Each prompt must have: text, timestamp, session ID, source (claude/cursor), and any associated tool usage or outcomes. Bad parsing silently corrupts every downstream stage.
**Gate type:** auto
**Input artifact:** `(pipeline input — date range and source selection)`
**Output artifact:** `research/prompt-prof/stage-1-parsing-output.md`

#### Quality Gate Checklist
- [ ] Both Claude Code and Cursor parsers ran without errors
- [ ] Total prompt count is non-zero (if zero, verify data exists at expected paths)
- [ ] Each parsed prompt has: text, timestamp, sessionId, source fields populated
- [ ] Malformed JSONL lines logged with count — not silently skipped
- [ ] TypeScript compiles: `npx tsc --noEmit`

#### Known Failure Modes
<!-- Populated over time from retrospectives -->

---

### Stage 2: Prompt Classification

**Purpose:** Classify each parsed prompt into types: Code Generation, Questions, File Operations, Commands/Actions, Clarifications, Other. Classification accuracy directly impacts pattern analysis — a misclassified "clarification" as "code generation" hides retry patterns. Uses keyword matching and NLP (natural library).
**Gate type:** auto
**Input artifact:** `research/prompt-prof/stage-1-parsing-output.md`
**Output artifact:** `research/prompt-prof/stage-2-classification-output.md`

#### Quality Gate Checklist
- [ ] Every prompt has exactly one classification type assigned
- [ ] Distribution includes at least 3 different types (if all prompts are "Other", classifier is broken)
- [ ] Clarification detection checked: prompts starting with "No,", "Actually,", "Not that" are flagged
- [ ] Short prompts (<5 words) without action verbs classified as Commands or Other, not Code Generation

#### Known Failure Modes
<!-- Populated over time from retrospectives -->

---

### Stage 3: Quality Scoring

**Purpose:** Score each prompt 0-100 across 4 dimensions: Clarity (25%), Context (25%), Efficiency (25%), Outcome (25%). This is the core value — the score must be defensible. A prompt scored 90 should genuinely be excellent; a prompt scored 30 should genuinely be poor. The scoring rubric in scoring/ defines specific point values for file references, action verbs, retry detection, etc.
**Gate type:** human
**Input artifact:** `research/prompt-prof/stage-2-classification-output.md`
**Output artifact:** `research/prompt-prof/stage-3-scoring-output.md`

#### Quality Gate Checklist
- [ ] Every prompt has a total score and per-dimension breakdown (clarity, context, efficiency, outcome)
- [ ] Score distribution is not flat — if >90% of prompts score 50-60, scoring lacks discriminating power
- [ ] Retry detection working: prompts >60% similar to previous prompt in session get efficiency penalty
- [ ] At least one prompt scored above 80 and one below 40 exist (if not, verify edge cases are handled)
- [ ] Direct CLI commands (e.g., "/help", "y", "n") scored appropriately — not penalized as vague

#### Known Failure Modes
<!-- Populated over time from retrospectives -->

---

### Stage 4: Pattern Analysis & Insights

**Purpose:** Aggregate scores into actionable insights: best/worst prompts, type distributions, score trends over time, cost per session, common improvement opportunities. The insight must be specific enough to change behavior — "your prompts are average" is useless, "42% of your prompts lack file references, adding them would improve clarity scores by ~15 points" is actionable.
**Gate type:** auto
**Input artifact:** `research/prompt-prof/stage-3-scoring-output.md`
**Output artifact:** `research/prompt-prof/stage-4-patterns-output.md`

#### Quality Gate Checklist
- [ ] Top 10 and bottom 10 prompts identified with scores and reasons
- [ ] Type distribution computed with percentages
- [ ] At least 2 specific, actionable recommendations generated (not generic advice)
- [ ] Cost analysis included if Claude Code cost data is available
- [ ] Recommendations reference specific scoring dimensions the user can improve

#### Known Failure Modes
<!-- Populated over time from retrospectives -->

---

### Stage 5: Report Generation & Verification

**Purpose:** Render the final CLI report with formatted tables, score distributions, and recommendations. Verify the report is accurate: spot-check that displayed numbers match computed values, that rankings are correct, and that no data was lost between analysis and display. Also run the self-improvement retrospective.
**Gate type:** human
**Input artifact:** `research/prompt-prof/stage-4-patterns-output.md`
**Output artifact:** `research/prompt-prof/stage-5-report-output.md`

#### Quality Gate Checklist
- [ ] Report renders without errors in terminal
- [ ] Total prompt count in report matches count from Stage 1
- [ ] Top prompt score in report matches highest score from Stage 3
- [ ] All tests pass: `npm test` (with at least 1 test executed)
- [ ] Build succeeds: `npm run build`

#### Known Failure Modes
<!-- Populated over time from retrospectives -->

---

## Gate Rules

**Human Gate:** Requires explicit human approval before advancing. The agent produces output and checklist, then waits. A human reviews and creates an approval file at `research/prompt-prof/.gate-{stage}-approved`.

**Auto Gate:** Gate enforcer checks mechanically — output artifact exists, all checklist items checked. Advances automatically if both conditions are met.

---

## Verdicts

- **PURSUE** — Analysis pipeline is accurate and report is actionable.
- **INVESTIGATE** — Scoring or classification needs calibration before trusting results.
- **MONITOR** — Data quality issues found but results are directionally correct.
- **ARCHIVE** — Insufficient data or fundamental parsing errors — fix before re-running.

Any stage can kill the pipeline. A documented kill with clear reasoning is a successful outcome.
