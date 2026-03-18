---
name: harness
description: Scaffold a self-improving agent harness for the current project. Scans the codebase to understand what it does, proposes domain-specific pipeline stages with quality gates, and generates files that mechanically prevent repeated failures.
argument-hint: [pipeline-name]
---

# Self-Improving Harness Scaffold

You are scaffolding a **self-improving agent harness** — a pipeline where every failure gets encoded into a mechanical fix so the same mistake becomes structurally impossible to repeat.

Core loop: `FAILURE → ROOT CAUSE → MECHANICAL FIX → NEVER REPEAT`

This is specifically for **agent pipelines** — workflows where an AI agent does multi-step work that can hallucinate, skip steps, or do shallow work that looks thorough. The harness mechanically prevents these failures from recurring.

## Step 1: Understand the project domain

This is the most important step. You are NOT building a generic CI/CD pipeline. You are building a pipeline that reflects **what this project actually does** — its domain, its workflows, what can go wrong at a business/domain level.

### 1a: Read and understand

Read these files to understand the project:

- **README.md** — what the project does, who it's for, what problem it solves
- **CLAUDE.md** — existing agent instructions, workflows, conventions
- **Main entry points** — `src/index.ts`, `main.py`, `cmd/main.go`, etc. — understand the core workflow
- **Key source directories** — scan the top-level structure to understand the architecture
- **Package/dependency files** — what libraries does it use? These hint at what it does (e.g., `@notionhq/client` = Notion integration, `puppeteer` = web scraping, `express` = web server)
- **Config files** — `.env.example`, docker-compose, deployment configs
- **CI config** — `.github/workflows/*.yml` — what does the project's CI do?
- **Git history** — `git log --oneline -50` — recent work, fix/revert commits as seed failure modes

### 1b: Identify the domain workflow

Based on what you read, answer these questions (do NOT show these to the user, use them to inform your stage design):

1. **What does this project do?** (e.g., "scrapes prediction markets and finds arbitrage opportunities", "generates content from engineering updates", "verifies email addresses in bulk")
2. **What is the core workflow?** Map the steps the project performs from input to output. For example:
   - Content tool: Ingest sources → Research → Draft → Review → Publish
   - Trading bot: Signal detection → Data validation → Strategy analysis → Risk assessment → Execution
   - Verification engine: Input parsing → Cross-reference matching → Semantic analysis → Confidence scoring → Report generation
   - CLI analyzer: Data ingestion → Pattern extraction → Scoring → Insight generation → Output formatting
3. **What can go wrong at each step?** Not code bugs — domain failures. Wrong data, missed signals, bad analysis, false positives, compliance violations, quality issues. Agents will hallucinate here — what would a hallucination look like at each step?
4. **What decisions does a human need to review?** These become human gates — points where the agent presents its work and the user approves in the conversation before proceeding.

### 1c: Identify tooling (secondary)

Also check for tooling — but this is secondary to domain understanding:

- Package manager, test framework, linting, type checking, build system
- These may become checklist items WITHIN domain stages, not separate stages

### 1d: Present findings

Present a brief summary to the user:
- "This project is a [description]. Its core workflow is [workflow]. I'll propose stages based on this domain."
- List key files you read and what you learned

## Step 2: Propose domain-specific pipeline stages

Design stages that mirror the project's **actual workflow**, not a generic software pipeline.

### What makes a good stage

- Each stage represents a **meaningful phase** of the project's workflow
- Stages should map to where **different types of failures** can occur
- A stage's quality gate should catch failures **specific to what that stage does**
- Code quality checks (lint, types, tests, build) are checklist items WITHIN relevant stages — not standalone stages unless the project is specifically about code quality

### Bad vs. good stage design

**BAD (generic CI/CD — same for every project):**
1. Specification → 2. Lint & Types → 3. Testing → 4. Build → 5. Verification

**GOOD (domain-specific — reflects what the project does):**

For a content automation tool:
1. Source Ingestion → 2. Research & Context → 3. Drafting → 4. Quality Review → 5. Publishing

For a prediction market scanner:
1. Signal Detection → 2. Data Collection & Validation → 3. Strategy Analysis → 4. Risk & Robustness Check → 5. Execution Decision

For a semantic verification engine:
1. Market Parsing → 2. Cross-Platform Matching → 3. Resolution Criteria Analysis → 4. Confidence Scoring → 5. Report & Alert

For a CLI analysis tool:
1. Data Ingestion → 2. Pattern Extraction → 3. Scoring & Analysis → 4. Insight Synthesis → 5. Output & Recommendations

### Stage requirements

Each stage needs:
- **Name**: short, descriptive, domain-specific
- **Purpose**: 2-3 sentences on what this stage does in the project's domain
- **Gate type**: `human` (requires user approval in conversation) or `auto` (mechanical check only)
- **Command**: shell command to run if applicable, or "manual" for agent-driven stages
- **Checklist items**: 2-4 mechanical, grep-able checks specific to THIS stage's domain concerns
- **Instructions**: Step-by-step instructions for what to do in this stage, specific to the project

### Rules for checklist items

Checklist items are the most important part of the harness. Bad items create false blocks or false passes. Every item must follow these rules:

- **Test the tool's behavior, not the user's data.** Bad: "At least one prompt scores above 80" (depends on what data the user has). Good: "Scoring system produces a range > 40 points across the dataset" (tests whether the tool differentiates).
- **Be verifiable from the stage's output alone.** The agent must be able to check it mechanically — by running a command, grepping output, or computing a value. If it requires subjective judgment, it's not a checklist item.
- **Don't require external dependencies to exist.** Bad: "All tests pass (with at least 1 test executed)" (the project may have no tests). Good: "If tests exist, they pass" or "Build succeeds."
- **State what to check, not what to hope for.** Bad: "Results look reasonable." Good: "Output file contains at least 3 rows in the summary table."
- **Each item should catch a different failure.** Don't write 3 items that all check "output file exists" in different words.

### Rules for stages

- The number of stages should match the project's workflow complexity — could be 3, could be 8
- First and last stages should default to `human` gates
- Middle stages default to `auto` gates but use `human` for high-stakes decisions
- Code quality checks (lint, type-check, test, build) should be integrated as checklist items in the relevant stage — e.g., "Build succeeds" is a checklist item in the final stage, not its own stage
- Quality gate items must be mechanical and domain-specific — "All alternative explanations tested with quantified impact" not "Analysis looks good"
- If you can construct a test for a flagged issue, that test MUST be a checklist item

### Present and confirm

Present the proposed stages to the user in a clear table format with: stage name, purpose (1 line), gate type, key checklist items.

Ask for confirmation before generating files. The user may want to add, remove, reorder, or modify stages. Be explicit: "These stages are based on [project]'s workflow of [description]. Want to adjust anything?"

## Step 3: Generate the harness

Once the user confirms, create the following structure **inside the current project directory**:

```
.harness/
  pipeline.md              # Pipeline definition with stages and gates
  memory.md                # Failure registry
  gate-enforcer.sh         # Mechanical gate enforcement
  skills/
    stage-1-{slug}.md      # One skill file per stage
    stage-2-{slug}.md
    ...
  research/                # Working directory for output artifacts
  .improvements/
    self-improve.md        # Self-improvement analysis template
    retrospective.md       # Post-run retrospective template
```

The harness is generated **inside the project** as `.harness/`. It is not a sibling directory. Add `.harness/research/` to `.gitignore` (artifacts are ephemeral). The rest of `.harness/` should be committed — it is the pipeline's institutional memory that improves over time.

Use the pipeline name from the user's argument, or ask if not provided.

### pipeline.md format

```markdown
# {pipeline-name} Pipeline

**Domain:** {detected domain — be specific, e.g., "prediction market arbitrage scanning" not "software"}
**Created:** {today's date}
**Stages:** {count}
**Run:** `/run-pipeline` to execute, `/run-pipeline N` to resume from stage N

---

### Stage N: {Name}

**Purpose:** {2-3 sentences, domain-specific}
**Gate type:** {human|auto}
**Input artifact:** `{path}`
**Output artifact:** `{path}`

#### Quality Gate Checklist
- [ ] {domain-specific mechanical check 1}
- [ ] {domain-specific mechanical check 2}
- [ ] {domain-specific mechanical check 3}

#### Known Failure Modes
<!-- Populated over time from retrospectives -->

---

## Gate Rules

**Human Gate:** The agent completes the stage, runs gate-enforcer.sh, then presents results to the user in the conversation. The user reviews and approves (or gives feedback) before the pipeline advances. The agent cannot approve its own human gate.

**Auto Gate:** Gate enforcer checks mechanically — output artifact exists, all checklist items checked. Advances automatically if both conditions are met.

---

## Verdicts

- **PURSUE** — Signal is strong, proceed.
- **INVESTIGATE** — Needs more work before committing resources.
- **MONITOR** — Not actionable now, worth tracking.
- **ARCHIVE** — No signal found. Document why.

Any stage can kill the pipeline. A documented kill with clear reasoning is a successful outcome.
```

### Stage skill file format

Each stage gets its own skill file at `.harness/skills/stage-N-{slug}.md`. The instructions and checklist must be **specific to the project's domain**, not generic:

```markdown
# Stage N: {Name}

## Purpose

{2-3 lines on what this stage does IN THIS PROJECT'S DOMAIN. What decisions it makes, what it produces, what can go wrong. What would a hallucination look like at this stage?}

## Artifacts

- **Input:** `{input path}`
- **Output:** `{output path}`

## Command

**Command:** `{shell command or "manual"}`

## Instructions

1. {Step 1 — specific to this stage AND this project's domain}
2. {Step 2 — reference actual project files, APIs, data sources where relevant}
3. {Step 3}
4. Review your output against the Quality Gate Checklist below.
5. Mark each checklist item as complete (`- [x]`) or leave unchecked with a note.

## Quality Gate Checklist

- [ ] {domain-specific mechanical check 1}
- [ ] {domain-specific mechanical check 2}
- [ ] {domain-specific mechanical check 3}

## Known Failure Modes

<!-- Populated over time from retrospectives and self-improvement analysis.
     Format:
     **FM-N: Short description**
     Trigger: What situation causes this failure
     Check: What to verify to prevent it
     Added: Date, from retrospective/self-improvement of run X
-->

## Self-Improvement Hook

When a downstream stage finds that this stage's output was flawed:

1. **Add to Known Failure Modes** above with the FM-N format.
2. **Add a checklist item** that would have caught this specific issue.
3. **Log in `.harness/memory.md`** with the failure, root cause, fix applied, and this file as the file changed.
4. **Commit** with format: `harness-fix(stage-N): description of what was added`

If you cannot identify a specific, mechanical change, document why in the Open Failure Modes table in memory.md.
```

### memory.md format

```markdown
# {pipeline-name} — Failure Registry

## Failure Log

| Date | Stage | Failure | Root Cause | Fix Applied | File Changed |
|------|-------|---------|------------|-------------|--------------|
| | | | | | |

## Pipeline Reliability

| Date | Estimated Reliability | Change | Reason |
|------|----------------------|--------|--------|
| {today} | 70% | baseline | Initial scaffold |

## Open Failure Modes

| Date | Stage | Description | Proposed Fix | Status |
|------|-------|-------------|-------------|--------|
| | | | | |

---

**Rules:**
- Every failure log entry MUST have a non-empty "File Changed" column
- If nothing changed, the fix didn't happen — the entry is incomplete
- Reliability estimates are subjective but must be justified
```

### gate-enforcer.sh

Generate a POSIX-compatible shell script that:
1. Takes stage number as the argument
2. Checks output artifact exists (reads path from the skill file)
3. Checks all checklist items are marked as complete — match `[x]` or `[X]` case-insensitively, count unchecked as `[ ]`. Use patterns that handle whitespace variations.
4. Reads pipeline.md to determine gate type. If human, prints `HUMAN_GATE_REQUIRED` and exits 0 (the runner handles asking the user). If auto, prints `PASSED` and exits 0.
5. Exits 1 only when artifacts are missing or checklist items are unchecked — prints `BLOCKED` with the specific reason.

The gate enforcer does **mechanical checks only**. Human gate approval happens in the conversation via the `/run-pipeline` skill, not in this script.

### self-improve.md format

```markdown
# Self-Improvement Analysis — {pipeline-name}

For each issue found during verification or review:

### Issue N

**Found in:** Stage {X} output
**Should have been caught by:** Stage {Y}
**Why it wasn't caught:** {explanation}
**Proposed fix:**
- **File:** {specific file path}
- **Change:** {specific change — new checklist item, failure mode entry, or gate condition}
- **Severity:** {critical / moderate / minor}

## Summary

| Issue | Source Stage | Target Stage | Fix | Committed? |
|-------|-------------|-------------|-----|------------|
| | | | | [ ] |

**Rule:** Every row must result in a commit. If the "Committed?" box is unchecked, the retrospective is incomplete.
```

### retrospective.md format

```markdown
# Retrospective — {pipeline-name}

Complete after each pipeline run.

## What worked
-

## What failed
-

## Improvements made

| Issue | File Changed | Commit Hash |
|-------|-------------|-------------|
| | | |

**Verification:** Run `git log --oneline | grep "harness-fix"` — every improvement above must appear as a commit. If not, the retrospective is incomplete.
```

## Step 4: Seed failure modes from git history

If the git log contains fix/revert commits, add them as seed entries in the relevant stage's Known Failure Modes section. Map each fix to the domain stage it belongs to — not just "code fix" but "what domain-level failure did this fix address?"

## Step 5: Summary

After generating all files, print:
1. What was created (file list)
2. The domain workflow the pipeline is based on
3. How the self-improvement loop works (failure → root cause → mechanical fix → commit)
4. Remind: "The harness improves itself. Every failure becomes a mechanical fix. The pipeline gets more reliable over time — not because the agent gets smarter, but because the system won't let it repeat past mistakes."

Then ask: **"Harness ready. Want me to run the pipeline now? (`/run-pipeline`)"**

This is important — the user should know immediately that the next step is `/run-pipeline`. Don't just print instructions and stop.

## Key principles

- **Domain first, tooling second.** The pipeline mirrors the project's actual workflow, not a generic CI/CD pipeline. Code quality checks are items within domain stages, not their own stages.
- **Rules in tools, not instructions.** Enforcement lives in `gate-enforcer.sh` and quality gate checklists, not in prose the agent might ignore.
- **Human gates are conversational.** The agent presents results in the conversation and waits for user approval. No external tools needed.
- **Skills loaded on-demand.** Each stage has its own skill file. The pipeline loads only the relevant one per stage, not all at once.
- **Retrospectives produce commits, not prose.** Every fix must result in a file change.
- **Kill is a valid outcome.** "This doesn't work, here's why" is a successful pipeline result.
- **If you can test it, you MUST test it.** Listing problems without acting on them is a disclaimer, not work.
