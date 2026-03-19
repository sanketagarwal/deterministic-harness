# dynamic-harness

A Claude Code skill that scaffolds self-improving agent harnesses for any project.

We built this for an internal agentic workflow we were working on, and felt that this could provide insights to building a better harness in general.

## The problem

Agents hallucinate. They skip steps under context pressure. They do shallow work that looks thorough. A static checklist doesn't fix this — under load, agents deprioritise instructions and self-report success without verification.

Most agent harnesses are also static — designed once, shipped, and never updated. That works when the problem space is stable. But in domains where failure modes keep evolving — research, analysis, content automation, trading — a static harness degrades over time. Last month's checklist doesn't catch this month's edge case.

## The solution

A harness that mechanically upgrades itself after every failure. The core loop:

```
FAILURE → ROOT CAUSE → MECHANICAL FIX → NEVER REPEAT
```

Every failure gets encoded into a skill file, quality gate, or tool so the same mistake becomes structurally impossible to repeat. The agent doesn't need to remember the lesson — the system won't let it make the same mistake.

## Install

Copy the `skills/` directory into your project's `.claude/skills/` directory, or add it globally to `~/.claude/skills/`.

## Usage

```bash
# In any project — scaffold the harness:
/harness my-pipeline

# Run the pipeline:
/run-pipeline

# Resume from a specific stage:
/run-pipeline 3
```

Claude reads your codebase, understands what the project **actually does**, and proposes **domain-specific** pipeline stages. Ex: A content automation tool gets Ingestion → Research → Drafting → Review → Publishing. 

### `/harness` — the scaffold

1. **Reads your project** — README, source code, dependencies, CI, git history
2. **Understands the domain** — maps the project's actual workflow from input to output
3. **Proposes stages** — domain-specific, with mechanical quality gates at each step
4. **Asks for confirmation** — you can add, remove, reorder, or modify stages
5. **Generates the harness** — `.harness/` directory with pipeline definition, skill files, gate enforcer, memory, and improvement templates

### `/run-pipeline` — the runner

1. **Asks where to track data** — local JSON (zero setup) or Notion (for team visibility)
2. **Reads the pipeline** — loads `.harness/pipeline.md` and past failure history
3. **Executes stages sequentially** — loads each stage skill, does the work, writes output artefacts
4. **Enforces gates mechanically** — runs `gate-enforcer.sh` after every stage (no skipping)
5. **Asks you at human gates** — presents results in the conversation, waits for your approval before proceeding
6. **Logs failures and improves** — every failure gets traced, fixed, and committed

Human gates look like this in practice:

> **Stage 3 (Quality Scoring) is complete.** Scoring range is 21-76 across 780 prompts. Two known failure modes were checked — both pass. Approve to proceed to Stage 4?

You reply in the conversation. The agent can't proceed without your response.

## What gets generated

```
.harness/
  pipeline.md              # Pipeline definition with stages and gates
  memory.md                # Failure registry — the pipeline's institutional memory
  gate-enforcer.sh         # Mechanical gate enforcement script
  skills/
    stage-1-name.md        # One skill file per stage
    stage-2-name.md
    ...
  research/                # Working directory for output artefacts. improvements/
    self-improve.md        # Self-improvement analysis template
    retrospective.md       # Post-run retrospective template
```

The harness lives inside your project as `.harness/`. Add `.harness/research/` to `.gitignore` (artefacts are ephemeral). Commit the rest — it's the pipeline's memory that improves over time.

## How it works

**Pipeline definition** (`pipeline.md`) — Defines each stage with its purpose, input/output artefacts, gate type (human or auto), and quality gate checklist. Any stage can kill the pipeline; a documented kill is a successful outcome.

**Stage skills** (`skills/stage-N-name.md`) — Each stage has its own skill file loaded on demand. Contains domain-specific instructions, quality gate checklist, known failure modes, and a self-improvement hook that fires when downstream stages find flaws.

**Quality gates** — Every stage has a checklist that must be fully checked before advancing. Items are mechanical and grep-able, not subjective prose. The gate enforcer won't let the pipeline advance with unchecked items.

**Gate enforcer** (`gate-enforcer.sh`) — A shell script that mechanically checks output artefacts exist, and all checklist items are checked. Prints BLOCKED or PASSED. No exceptions.

**Human gates** — At key stages (first, last, and high-stakes decisions), the runner presents results directly in the Claude Code conversation and asks you to approve. The agent literally cannot proceed without your response — this is mechanically enforced by the conversation flow, not by instructions the agent can skip.

**Self-improvement loop** — During verification, every issue is traced back to the stage that should have caught it. The fix is a specific change to a specific file — a new checklist item, a new failure mode entry, a new gate condition. The fix gets committed. The harness gets better.

## The self-improvement loop

This is the key differentiator:

1. **Verification finds an issue.** The agent (or human) discovers something that should have been caught earlier.
2. **Root cause analysis.** Which earlier stage should have caught this? Why didn't the quality gate stop it?
3. **Mechanical fix.** A specific change to a specific file. Not "be more careful next time" — an actual checklist item, failure mode entry, or gate condition that makes the mistake structurally impossible.
4. **Commit the fix.** Every fix is committed with `harness-fix(stage-N): description`. If nothing was committed, the fix didn't happen.
5. **Update reliability tracking.** The failure registry in `memory.md` tracks pipeline reliability over time.

Over time, the harness accumulates domain-specific knowledge as mechanical constraints. The quality gates get tighter. The failure modes get more specific. The pipeline gets more reliable — not because the agent got smarter, but because the system won't let it repeat past mistakes.

### Real examples from production

These are actual failures from production agent pipelines. Each required a different fix, and none could have been anticipated at design time.

**1. The agent skipped a mandatory gate under pressure.** During a batch run, the agent skipped a human approval gate because the instruction to stop existed only as text in a skill file, and under load it got deprioritized. **Fix:** Human gates are now conversational — the runner presents results and waits for user input. The agent physically cannot proceed because it's waiting for a message. Instructions get forgotten; waiting for input is structural.

**2. The agent did shallow work that looked thorough.** An analysis listed a known confounding factor as a possible alternative explanation — but treated it as a caveat rather than something to test. An external reviewer forced the test, which invalidated the entire finding. **Fix:** The verification skill now reads: *"If you can construct a test for an alternative explanation, you MUST run it. Listing confounds without testing them is a disclaimer, not verification."*

**3. The agent found the problem but didn't act on it.** An analysis stage flagged a critical data gap and recommended "start collection immediately," then advanced to the next stage without starting collection. The problem was identified, documented, and ignored — all in the same run. **Fix:** The stage cannot advance until the flagged action item has been executed or explicitly deferred with justification.

## Tracking (optional)

Pipeline data (stages, failures, reliability, improvements) is always tracked in `.harness/memory.md` and committed to git. Optionally, you can also sync to:

**Local JSON + CSV export** — stored in `.harness-data/`, no setup needed:
```bash
cd dashboard && npm install
npm run export-csv    # Exports all tracking data to CSV
```

**Notion** — for team visibility in a richer UI:
```bash
cd dashboard && npm install
cp .env.example .env  # Add your NOTION_TOKEN and NOTION_PARENT_PAGE_ID
npm run setup-notion  # Creates 5 Notion databases
```

The `/run-pipeline` skill asks which backend you want at the start of each run.

## License

MIT
