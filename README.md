# deterministic-harness

A Claude Code skill that scaffolds self-improving agent harnesses for any project.

## The problem

Most agent harnesses are static — you design them once and ship them. That works when the problem space is stable (build this feature, pass these tests). But in domains where failure modes keep evolving — research, analysis, content automation, security auditing — a static harness degrades over time. Last month's checklist doesn't catch this month's edge case.

## The solution

A harness that mechanically upgrades itself after every failure. The core loop:

```
FAILURE → ROOT CAUSE → MECHANICAL FIX → NEVER REPEAT
```

Every failure gets encoded into a skill file, quality gate, or tool so the same mistake becomes structurally impossible to repeat. The agent doesn't need to remember the lesson — the system won't let it make the same mistake.

## Install

```bash
# In Claude Code:
/plugin marketplace add sanketagarwal/deterministic-harness
/plugin install deterministic-harness
```

## Usage

```bash
# In any project:
/harness my-pipeline
```

Claude reads your codebase, understands what the project **actually does**, and proposes **domain-specific** pipeline stages. Ex: A content automation tool gets Ingestion → Research → Drafting → Review → Publishing. 

The skill:
1. **Reads your project** — README, source code, dependencies, CI, git history
2. **Understands the domain** — maps the project's actual workflow from input to output
3. **Proposes stages** — domain-specific, with mechanical quality gates at each step
4. **Asks for confirmation** — you can add, remove, reorder, or modify stages
5. **Generates the harness** — pipeline.md, skill files, gate-enforcer, memory, improvement templates

## What gets generated

```
your-pipeline/
  pipeline.md              # Pipeline definition with stages and gates
  memory.md                # Failure registry
  gate-enforcer.sh         # Mechanical gate enforcement
  skills/
    stage-1-name.md        # One skill file per stage
    stage-2-name.md
    ...
  research/                # Working directory for artifacts
  .improvements/
    self-improve.md        # Self-improvement analysis template
    retrospective.md       # Post-run retrospective template
```

## How it works

**Pipeline definition** (`pipeline.md`) — Defines each stage with its purpose, input/output artifacts, gate type (human or auto), and quality gate checklist. Any stage can kill the pipeline; a documented kill is a successful outcome.

**Stage skills** (`skills/stage-N-name.md`) — Each stage has its own skill file loaded on-demand. Contains domain-specific instructions, quality gate checklist, known failure modes, and a self-improvement hook that fires when downstream stages find flaws.

**Quality gates** — Every stage has a checklist that must be fully checked before advancing. Items are mechanical and grep-able, not subjective prose. The gate enforcer won't let the pipeline advance with unchecked items.

**Gate enforcer** (`gate-enforcer.sh`) — A shell script that mechanically checks output artifacts exist, all checklist items are checked, and human approvals are in place. Prints BLOCKED or PASSED. No exceptions.

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

**1. The agent skipped a mandatory gate under pressure.** During a batch run, the agent skipped a human approval gate because the instruction to stop existed only as text in a skill file, and under load it got deprioritized. **Fix:** The gate enforcer now mechanically refuses to advance unless the Notion card status reads "Approved." Rules in instructions get forgotten; rules in tools work every time.

**2. The agent did shallow work that looked thorough.** An analysis listed a known confounding factor as a possible alternative explanation — but treated it as a caveat rather than something to test. An external reviewer forced the test, which invalidated the entire finding. **Fix:** The verification skill now reads: *"If you can construct a test for an alternative explanation, you MUST run it. Listing confounds without testing them is a disclaimer, not verification."*

**3. The agent found the problem but didn't act on it.** An analysis stage flagged a critical data gap and recommended "start collection immediately," then advanced to the next stage without starting collection. The problem was identified, documented, and ignored — all in the same run. **Fix:** The stage cannot advance until the flagged action item has been executed or explicitly deferred with justification.

## Examples

### Semantic Verification Engine (`sve-harness/`)

A 6-stage pipeline for cross-platform prediction market verification: Market Discovery → Cross-Platform Matching → Resolution Criteria Verification → Risk Assessment → Recommendation → Retrospective. Demonstrates domain-specific quality gates like "all six misalignment types checked" and seeded failure modes from design review.

### Prompt Effectiveness Analyzer (`prompt-prof-harness/`)

A 5-stage pipeline for AI prompt analysis: Session Parsing → Prompt Classification → Quality Scoring → Pattern Analysis → Report Generation. Includes a real pipeline run with 858 prompts — Stage 3 blocked on flat scoring distribution (96% of prompts scored 50-69), triggering the self-improvement loop.

### Software QA (`examples/software-qa/`)

A 5-stage pipeline: Specification → Implementation → Testing → Verification → Release. Demonstrates human gates on first/last stages, auto gates in the middle.

### Research (`examples/research/`)

A 5-stage pipeline: Hypothesis → Data Collection → Analysis → Verification → Synthesis. Demonstrates research-specific quality gates like falsifiability checks and confound testing.

## Dashboard (Notion UI)

Track your pipeline, failures, reliability, and improvements in Notion databases.

### Setup

```bash
cd dashboard
npm install
cp .env.example .env
# Edit .env with your Notion integration token and parent page ID
npm run setup    # Creates 5 Notion databases
npm start        # Launches dashboard at http://localhost:3000
```

### Getting your Notion credentials

1. Go to [notion.so/my-integrations](https://www.notion.so/my-integrations) and create an integration. Copy the token.
2. Create a page in Notion where you want the databases. Share it with your integration.
3. Copy the page ID from the URL (the 32-character hex string after the page name).

### What you can manage

- **Pipeline Stages** — view stage flow, gate types, checklist progress, status
- **Failure Registry** — log failures with root cause, fix, and file changed
- **Reliability Tracking** — chart reliability over time as fixes accumulate
- **Open Failure Modes** — track known issues that don't have mechanical fixes yet
- **Improvements Log** — record self-improvement fixes with source/target stage and severity

All data lives in Notion, so your team can view and edit it there too.

## License

MIT
