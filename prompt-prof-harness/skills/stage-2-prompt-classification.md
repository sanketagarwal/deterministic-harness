# Stage 2: Prompt Classification

## Purpose
Classify each parsed prompt into a functional category so that downstream scoring and pattern analysis can operate on meaningful groupings. The classifier assigns one of six types to every prompt, enabling per-type quality benchmarks and distribution analysis across sessions.

## Artifacts
- **Input:** `research/prompt-prof/stage-1-session-parsing-output.md`
- **Output:** `research/prompt-prof/stage-2-prompt-classification-output.md`

## Command
**Command:** `manual`

## Instructions
1. Load the normalized prompt list from the Stage 1 output artifact.
2. For each prompt, classify it into exactly one of the following types:
   - **Code Generation** — requests to write, modify, or refactor code
   - **Questions** — asking for explanations, how-to guidance, or conceptual answers
   - **File Operations** — reading, writing, moving, or searching files
   - **Commands/Actions** — running shell commands, git operations, build tasks
   - **Clarifications** — follow-up prompts that refine or correct a previous request
   - **Other** — prompts that do not fit any of the above categories
3. For clarification detection, check whether the prompt references a prior response, uses corrective language ("no, I meant...", "actually...", "instead..."), or is a short follow-up within the same session context.
4. Handle short prompts (under 10 words) by examining session context — a bare "yes" or "do it" following a code suggestion should inherit the prior prompt's type, not default to Other.
5. Write the classified prompt list to the output artifact, appending a type distribution summary table at the end.

## Quality Gate Checklist
- [x] Every prompt from Stage 1 input has exactly one classification assigned
- [x] The type distribution includes at least 3 distinct types
- [x] Clarification detection correctly identifies follow-up/corrective prompts
- [x] Short prompts (under 10 words) are handled via session context, not blindly assigned to Other

## Known Failure Modes
<!-- No known failure modes identified yet. Add entries as FM-N with trigger and check. -->

## Self-Improvement Hook
After completing Stage 2, review the quality gate checklist results and the type distribution table. If any items failed or classification edge cases were discovered, append a `## Retrospective` section to `research/prompt-prof/stage-2-prompt-classification-output.md` documenting:
- What failed and why
- The fix or workaround applied
- Whether this failure mode should be added to Known Failure Modes for future runs
