---
name: run-pipeline
description: Execute the agent pipeline defined in .harness/pipeline.md. Runs stages sequentially, enforces quality gates mechanically, and asks the user for approval at human gates directly in the conversation.
argument-hint: [stage-number to resume from (optional)]
---

# Run Pipeline

You are executing an agent pipeline defined in `.harness/pipeline.md`. Your job is to work through each stage, enforce quality gates mechanically, and present results to the user at human checkpoints.

## Pre-flight

1. **Check `.harness/pipeline.md` exists.** If it doesn't, tell the user: "No pipeline found. Run `/harness` first to scaffold one."
2. **Check `.harness/gate-enforcer.sh` exists and is executable.** If not executable, run `chmod +x .harness/gate-enforcer.sh`.
3. **Read `.harness/pipeline.md`** to understand all stages — their names, gate types, input/output artifacts, and checklist items.
4. **Read `.harness/memory.md`** to understand past failures and current reliability. These are lessons from previous runs — do not repeat known failures.
5. **Ask the user where to track pipeline data:**

   > "Where should I track pipeline progress, failures, and improvements?
   > 1. **Local JSON** — stored in `.harness-data/`, exportable to CSV. No setup needed.
   > 2. **Notion** — synced to Notion databases for a richer UI. Requires a Notion integration token and a parent page ID.
   >
   > Which do you prefer?"

   - If the user chooses **Local JSON**: no further setup. Data is stored in `.harness-data/` inside the project.
   - If the user chooses **Notion**: ask for their `NOTION_TOKEN` and `NOTION_PARENT_PAGE_ID` if not already configured. Check if a `dashboard/.env` or `.harness/.env` file exists with these values. If not, ask the user to provide them and save to `.harness/.env`. Then run the Notion database setup if `notion-config.json` doesn't exist.
   - If the user says they don't care or want to skip tracking: proceed without tracking. Gate enforcement and the pipeline still work — tracking is optional.

6. **Determine starting stage.** If the user provided a stage number argument, resume from that stage. Otherwise start from stage 1.

## Stage execution

For each stage N, in order:

### Step 1: Load the stage skill

Read `.harness/skills/stage-N-{slug}.md`. This contains:
- Instructions for what to do
- Quality gate checklist
- Known failure modes from past runs

**Before doing any work, read the Known Failure Modes section.** These are specific, mechanical lessons from past failures. Each one tells you what to check. Do not skip them.

### Step 2: Execute the stage

Follow the instructions in the skill file. If the stage has a shell command, run it. If it says "manual", follow the step-by-step instructions.

As you work, write output to the artifact path specified in the skill file (e.g., `.harness/research/stage-1-output.md`).

### Step 3: Mark the checklist

Go through each quality gate checklist item in the skill file. For each item:
- If it passes, mark it `[x]` in the skill file
- If it fails, leave it `[ ]` and add a note explaining why

**Do not mark an item `[x]` unless it genuinely passes.** A checked item you didn't verify is worse than an unchecked one — it hides the problem.

### Step 4: Run gate-enforcer.sh

Run the gate enforcer:

```bash
.harness/gate-enforcer.sh <stage-number>
```

This mechanically checks:
1. Output artifact exists
2. All checklist items in the skill file are marked `[x]`
3. Whether this is a human or auto gate

**You MUST run this. No exceptions. Do not skip it.**

### Step 5: Handle the gate result

Read the gate-enforcer output and act accordingly:

**If output contains `PASSED` (auto gate cleared):**
- Log the stage completion to the tracking backend (local JSON or Notion) — stage name, status "passed", checklist score.
- Proceed to the next stage immediately.

**If output contains `HUMAN_GATE_REQUIRED` (artifacts + checklist OK, human must approve):**
- Present to the user:
  - What this stage did (1-2 sentences)
  - Key findings or output summary
  - The completed checklist
  - Any concerns or edge cases you noticed
- Then ask: **"Stage N ({name}) is complete. Approve to proceed to Stage {N+1}?"**
- **STOP and wait for the user's response.** Do not proceed until they explicitly approve.
- If the user gives feedback instead of approving, address their feedback, re-run gate-enforcer, and ask again.
- Once approved, log the stage completion to the tracking backend with status "passed".

**If output contains `BLOCKED` (gate failed):**
- Log the failure to the tracking backend — stage name, status "blocked", which items failed.
- Present the failure to the user:
  - What failed (which checklist items, which artifacts missing)
  - Why it failed (your assessment)
  - What you think the fix is
- Ask: **"Stage N gate failed. Want me to fix and retry, or kill the pipeline?"**
- **STOP and wait.** If the user says fix, make the fix, re-mark the checklist, and re-run gate-enforcer. If they say kill, go to Pipeline Kill.

## Pipeline kill

A kill is a valid outcome. When the user says kill, or when you determine the pipeline cannot produce useful output:

1. Write a kill summary to `.harness/research/pipeline-kill.md`:
   - Which stage killed it
   - Why (specific reason, not "it didn't work")
   - What would need to change to make it work
2. Log the kill in `.harness/memory.md` failure log table
3. Log to tracking backend — failure entry with stage, reason, and status "killed"
4. Tell the user: "Pipeline killed at Stage N. Reason: {reason}. Logged in memory.md."

## Pipeline completion

After the last stage's gate passes:

1. Update `.harness/memory.md` reliability tracking — estimate the new reliability percentage based on how the run went
2. Log the full run to the tracking backend — reliability entry with date, percentage, and reason
3. Present a summary to the user:
   - Each stage's key output (1 line each)
   - Any failure modes discovered and fixes applied
   - Final verdict (PURSUE / INVESTIGATE / MONITOR / ARCHIVE)

## Self-improvement (after failures)

When a gate fails, or when a later stage discovers a problem that an earlier stage should have caught:

1. **Trace to root stage.** Which earlier stage should have caught this? Why didn't its checklist stop it?
2. **Add a Known Failure Mode** to that stage's skill file using the FM-N format.
3. **Add a checklist item** that would have caught this specific issue.
4. **Log in `.harness/memory.md`** — failure, root cause, fix applied, file changed.
5. **Commit** with format: `harness-fix(stage-N): description`

If you cannot identify a specific mechanical change, document it in the Open Failure Modes table in memory.md. But try hard — vague lessons don't prevent future failures.

## Hard rules

These are not suggestions. They are constraints.

1. **Run gate-enforcer.sh after every stage.** No skipping, no self-reporting.
2. **You cannot approve your own human gate.** Present results, ask the user, wait.
3. **You cannot proceed past a failed gate** without user permission.
4. **If you can construct a test for a concern, you MUST run it** before presenting results.
5. **A documented kill with clear reasoning is a successful outcome.** Don't keep a failing pipeline alive to avoid admitting failure.
6. **Every self-improvement fix must change a file.** If nothing changed, the fix didn't happen.
