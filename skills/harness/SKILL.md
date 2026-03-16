---
name: harness
description: Scaffold a self-improving agent harness for the current project. Scans the codebase, proposes pipeline stages with quality gates, and generates files that mechanically prevent repeated failures.
argument-hint: [pipeline-name]
---

# Self-Improving Harness Scaffold

You are scaffolding a **self-improving agent harness** — a pipeline where every failure gets encoded into a mechanical fix so the same mistake becomes structurally impossible to repeat.

Core loop: `FAILURE → ROOT CAUSE → MECHANICAL FIX → NEVER REPEAT`

## Step 1: Scan the project

Analyze the current project to understand what's there. Check for:

- **Package manager**: package.json (npm/pnpm/yarn), Cargo.toml, pyproject.toml, go.mod, Gemfile, etc.
- **CI config**: `.github/workflows/*.yml` — extract job names and commands
- **Test framework**: test scripts, test directories, test config files
- **Linting**: eslint, prettier, ruff, golangci-lint, clippy, rubocop, etc.
- **Type checking**: TypeScript (tsc), mypy, pyright, etc.
- **Build system**: build scripts, Makefiles, docker builds
- **CLAUDE.md**: existing agent instructions (respect and integrate them)
- **Git history**: `git log --oneline -50` — look for fix/revert commits as seed failure modes

Present what you found as a brief summary to the user.

## Step 2: Propose pipeline stages

Based on what you found, propose pipeline stages. The number of stages should match the project's complexity — could be 3, could be 7. Each stage needs:

- **Name**: short, descriptive
- **Purpose**: 1-2 sentences on what this stage does
- **Gate type**: `human` (requires explicit approval) or `auto` (mechanical check only)
- **Command**: the shell command to run (if applicable, e.g., `pnpm lint && pnpm type-check`)
- **Checklist items**: 2-4 mechanical, grep-able checks (not subjective prose)

Rules for proposing stages:
- First and last stages should default to `human` gates
- Middle stages default to `auto` gates
- Every stage must produce an output artifact
- Quality gate items must be mechanical — "All tests pass" not "Code looks good"
- If you can construct a test for a flagged issue, that test MUST be a checklist item

Present the proposed stages to the user in a clear table format. Ask for confirmation before generating files. The user may want to add, remove, reorder, or modify stages.

## Step 3: Generate the harness

Once the user confirms, create the following structure:

```
{pipeline-name}/
  pipeline.md              # Pipeline definition with stages and gates
  memory.md                # Failure registry
  gate-enforcer.sh         # Mechanical gate enforcement
  skills/
    stage-1-{slug}.md      # One skill file per stage
    stage-2-{slug}.md
    ...
  research/                # Working directory for artifacts
  .improvements/
    self-improve.md        # Self-improvement analysis template
    retrospective.md       # Post-run retrospective template
```

Use the pipeline name from the user's argument, or ask if not provided.

### pipeline.md format

```markdown
# {pipeline-name} Pipeline

**Domain:** {detected or user-specified}
**Created:** {today's date}
**Stages:** {count}

---

### Stage N: {Name}

**Purpose:** {purpose}
**Gate type:** {human|auto}
**Input artifact:** `{path}`
**Output artifact:** `{path}`

#### Quality Gate Checklist
- [ ] {mechanical check 1}
- [ ] {mechanical check 2}
- [ ] {mechanical check 3}

#### Known Failure Modes
<!-- Populated over time from retrospectives -->

---

## Gate Rules

**Human Gate:** Requires explicit human approval before advancing. The agent produces output and checklist, then waits. A human reviews and creates an approval file at `research/{pipeline-name}/.gate-{stage}-approved`.

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

Each stage gets its own skill file at `skills/stage-N-{slug}.md`:

```markdown
# Stage N: {Name}

## Purpose

{2-3 lines on what this stage does, what decisions it makes, what it produces.}

## Artifacts

- **Input:** `{input path}`
- **Output:** `{output path}`

## Command

**Command:** `{shell command or "manual"}`

## Instructions

1. {Step 1 — specific to this stage}
2. {Step 2}
3. {Step 3}
4. Review your output against the Quality Gate Checklist below.
5. Mark each checklist item as complete (`- [x]`) or leave unchecked with a note.

## Quality Gate Checklist

- [ ] {mechanical check 1}
- [ ] {mechanical check 2}
- [ ] {mechanical check 3}

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
3. **Log in memory.md** with the failure, root cause, fix applied, and this file as the file changed.
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
1. Takes pipeline dir, stage number, and project name as args
2. Checks output artifact exists
3. Checks all checklist items are marked `[x]` (grep for `^- \[ \]` in the output)
4. For human gates, checks approval file exists at `research/{project}/.gate-{stage}-approved`
5. Prints `PASSED` or `BLOCKED` with reason
6. Exits 0 for pass, 1 for block

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

If the git log contains fix/revert commits, add them as seed entries in the relevant stage's Known Failure Modes section. These are real failures that already happened — encoding them prevents repeats.

## Step 5: Summary

After generating all files, print:
1. What was created (file list)
2. How to run the pipeline (work through stages in order, load skill files on-demand, run gate-enforcer before advancing)
3. How the self-improvement loop works (failure → root cause → mechanical fix → commit)
4. Remind: "The harness improves itself. Every failure becomes a mechanical fix. The pipeline gets more reliable over time — not because the agent gets smarter, but because the system won't let it repeat past mistakes."

## Key principles

- **Rules in tools, not instructions.** Enforcement lives in gate-enforcer.sh and checklists, not in prose the agent might ignore.
- **Skills loaded on-demand.** Each stage has its own skill file. Load only the relevant one per stage.
- **Retrospectives produce commits, not prose.** Every fix must result in a file change.
- **Kill is a valid outcome.** "This doesn't work, here's why" is a successful pipeline result.
- **If you can test it, you MUST test it.** Listing problems without acting on them is a disclaimer, not work.
