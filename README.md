# deterministic-harness

Scaffold a self-improving agent harness for any domain.

## The problem

Most agent harnesses are static — you design them once and ship them. That works when the problem space is stable (build this feature, pass these tests). But in domains where failure modes keep evolving — research, analysis, security auditing, due diligence — a static harness degrades over time. Last month's checklist doesn't catch this month's edge case.

## The solution

A harness that mechanically upgrades itself after every failure. The core loop:

```
FAILURE → ROOT CAUSE → MECHANICAL FIX → NEVER REPEAT
```

Every failure gets encoded into a skill file, quality gate, or tool so the same mistake becomes structurally impossible to repeat. The agent doesn't need to remember the lesson — the system won't let it make the same mistake.

## Quickstart

### Option 1: Claude Code skill (recommended)

Install as a Claude Code plugin and use `/harness` in any project:

```bash
# In Claude Code:
/plugin marketplace add sanketagarwal/deterministic-harness
/plugin install deterministic-harness

# Then in any project:
/harness my-pipeline
```

Claude reads your codebase, understands what the project **actually does**, and proposes **domain-specific** pipeline stages — not generic CI/CD steps. For example, a content automation tool gets stages like Ingestion → Research → Drafting → Review → Publishing, not Lint → Test → Build.

### Option 2: CLI scripts (tooling-only scan)

```bash
git clone https://github.com/sanketagarwal/deterministic-harness.git
cd deterministic-harness
chmod +x scaffold.sh scan-project.sh run-pipeline.sh generate-claude-md.sh
./scaffold.sh
```

Or auto-detect from an existing project:

```bash
./scan-project.sh /path/to/your/project    # Scans CI, tests, linting, git history
./scaffold.sh --from-scan /tmp/harness-scan.conf   # Uses scan output as defaults
./run-pipeline.sh your-pipeline my-feature  # Execute the pipeline with gates
./generate-claude-md.sh your-pipeline       # Generate CLAUDE.md for agent integration
```

The script asks for your pipeline name, domain, number of stages, and stage names (with scan-detected defaults if available). It produces:

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

**Stage skills** (`skills/stage-N-name.md`) — Each stage has its own skill file loaded on-demand. Contains instructions, quality gate checklist, known failure modes, and a self-improvement hook that fires when downstream stages find flaws.

**Quality gates** — Every stage has a checklist that must be fully checked before advancing. Items are mechanical and grep-able, not subjective prose. The gate enforcer won't let the pipeline advance with unchecked items.

**Gate enforcer** (`gate-enforcer.sh`) — A shell script that mechanically checks output artifacts exist, all checklist items are checked, and human approvals are in place. Prints BLOCKED or PASSED. No exceptions.

**Self-improvement loop** — During verification, every issue is traced back to the stage that should have caught it. The fix is a specific change to a specific file — a new checklist item, a new failure mode entry, a new gate condition. The fix gets committed. The harness gets better.

## Project scanner

`scan-project.sh` auto-detects your project setup and suggests pipeline stages:

```bash
./scan-project.sh /path/to/your/project
```

It scans for: package manager, CI config (GitHub Actions jobs), test framework, linting, build commands, CLAUDE.md, and git history (fix/revert commits become seed failure modes). Presents suggestions interactively — accept, skip, or edit each stage.

## Pipeline runner

`run-pipeline.sh` executes the pipeline with real commands and interactive gates:

```bash
./run-pipeline.sh my-pipeline feature-xyz
```

For each stage: runs the command (e.g., `pnpm lint && pnpm type-check`), parses output for test results/errors/coverage, runs gate-enforcer, and prompts for human approval at human gates. Logs failures and offers to write them to memory.md.

## Agent integration

`generate-claude-md.sh` produces a CLAUDE.md that tells an agent how to follow the pipeline:

```bash
./generate-claude-md.sh my-pipeline
```

Generates rules for: working through stages in order, loading skill files on-demand, running gate-enforcer before advancing, stopping at human gates, and committing self-improvement fixes.

## The self-improvement loop

This is the key differentiator. Here's how it works:

1. **Verification finds an issue.** The agent (or human) discovers something that should have been caught earlier.
2. **Root cause analysis.** For each issue: which earlier stage should have caught this? Why didn't the quality gate stop it?
3. **Mechanical fix.** A specific change to a specific file. Not "be more careful next time" — an actual checklist item, failure mode entry, or gate condition that makes the mistake structurally impossible.
4. **Commit the fix.** Every fix is committed with `harness-fix(stage-N): description`. If nothing was committed, the fix didn't happen.
5. **Update reliability tracking.** The failure registry in `memory.md` tracks pipeline reliability over time, with before/after estimates for each improvement.

The retrospective enforces this: every entry must result in a file change. If nothing changed, the retrospective is incomplete. Run `git log` to verify all fixes appear as commits.

Over time, the harness accumulates domain-specific knowledge as mechanical constraints. The quality gates get tighter. The failure modes get more specific. The pipeline gets more reliable — not because the agent got smarter, but because the system won't let it repeat past mistakes.

### Real examples from production

These are actual failures from production agent pipelines. Each required a different fix, and none could have been anticipated at design time.

**1. The agent skipped a mandatory gate under pressure.** During a batch run, the agent skipped a human approval gate because the instruction to stop existed only as text in a skill file, and under load it got deprioritized. **Fix:** The gate enforcer now mechanically refuses to advance unless the Notion card status reads "Approved." Rules in instructions get forgotten; rules in tools work every time.

**2. The agent did shallow work that looked thorough.** An analysis listed a known confounding factor as a possible alternative explanation — but treated it as a caveat rather than something to test. An external reviewer forced the test, which invalidated the entire finding. **Fix:** The verification skill now reads: *"If you can construct a test for an alternative explanation, you MUST run it. Listing confounds without testing them is a disclaimer, not verification."*

**3. The agent found the problem but didn't act on it.** An analysis stage flagged a critical data gap and recommended "start collection immediately," then advanced to the next stage without starting collection. The problem was identified, documented, and ignored — all in the same run. **Fix:** The stage cannot advance until the flagged action item has been executed or explicitly deferred with justification.

## Examples

### Software QA (`examples/software-qa/`)

A 5-stage pipeline: Specification → Implementation → Testing → Verification → Release. Demonstrates human gates on first/last stages, auto gates in the middle, and realistic failure modes like "agent marked feature complete without running E2E tests."

```bash
# Use as a starting point
cp -r examples/software-qa my-qa-pipeline
```

### Research (`examples/research/`)

A 5-stage pipeline: Hypothesis → Data Collection → Analysis → Verification → Synthesis. Demonstrates research-specific quality gates like falsifiability checks, confound testing, and traceability requirements.

```bash
# Use as a starting point
cp -r examples/research my-research-pipeline
```

## Dashboard (Notion UI)

Track your pipeline, failures, reliability, and improvements in a web dashboard backed by Notion databases.

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

## Design principles

1. **Rules in tools, not instructions.** Enforcement lives in `gate-enforcer.sh` and quality gate checklists, not in prose the agent might ignore under context pressure.
2. **Skills loaded on-demand.** Each stage has its own skill file. The pipeline loads only the relevant one per stage, not all at once.
3. **Retrospectives produce commits, not prose.** Every template that captures a failure has a field for "file changed." If nothing changed, the fix didn't happen.
4. **The harness improves itself.** The verification stage always includes self-improvement analysis. Failure modes flow back into earlier stage skill files as new checklist items.
5. **Kill is a valid outcome.** "This doesn't work, here's why" is a successful pipeline result, not a failure.

## Based on

This scaffold implements a pattern from production use at [Recall Labs](https://recall.wiki), where a self-improving harness took pipeline reliability from 70% to 90% through mechanical fixes alone — without changing the underlying model. The pattern was developed while building [OpenClaw](https://openclaw.ai), a competitive intelligence platform, and is used in the [Arby workspace](https://github.com/recallnet/arb) for research pipelines. Read more about the approach in [Self-Improving Agent Harnesses](https://recall.wiki/blog/self-improving-harness).

## License

MIT
