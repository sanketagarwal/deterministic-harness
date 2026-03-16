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

```bash
git clone https://github.com/recallnet/deterministic-harness.git
cd deterministic-harness
chmod +x scaffold.sh
./scaffold.sh
```

The script asks for your pipeline name, domain, number of stages, and stage names. It produces:

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

## The self-improvement loop

This is the key differentiator. Here's how it works:

1. **Verification finds an issue.** The agent (or human) discovers something that should have been caught earlier.
2. **Root cause analysis.** For each issue: which earlier stage should have caught this? Why didn't the quality gate stop it?
3. **Mechanical fix.** A specific change to a specific file. Not "be more careful next time" — an actual checklist item, failure mode entry, or gate condition that makes the mistake structurally impossible.
4. **Commit the fix.** Every fix is committed with `harness-fix(stage-N): description`. If nothing was committed, the fix didn't happen.
5. **Update reliability tracking.** The failure registry in `memory.md` tracks pipeline reliability over time, with before/after estimates for each improvement.

The retrospective enforces this: every entry must result in a file change. If nothing changed, the retrospective is incomplete. Run `git log` to verify all fixes appear as commits.

Over time, the harness accumulates domain-specific knowledge as mechanical constraints. The quality gates get tighter. The failure modes get more specific. The pipeline gets more reliable — not because the agent got smarter, but because the system won't let it repeat past mistakes.

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
