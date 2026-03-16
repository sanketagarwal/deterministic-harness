# Stage 2: Implementation

## Purpose
Build the feature according to the approved specification. The implementation must compile cleanly, pass all linting rules, and contain no placeholder code. This stage translates the specification into working software that is ready for systematic testing.

## Artifacts
- **Input:** `research/software-qa/stage-1-specification-output.md`
- **Output:** `research/software-qa/stage-2-implementation-output.md`

## Instructions
1. Read the approved specification from the input artifact.
2. Create an implementation plan: list the files to create or modify, in dependency order.
3. Implement each component, referencing the specification's acceptance criteria as you go.
4. After implementation is complete, run the compiler/build tool and fix all errors.
5. Run the project linter and fix all warnings and errors.
6. Grep the codebase for `TODO`, `FIXME`, `HACK`, and `XXX` — resolve or remove every instance.
7. Write the implementation summary to the output artifact, including:
   - List of files created or modified
   - Mapping of each specification requirement to the code that implements it
   - Any deviations from the specification (with justification)

## Quality Gate Checklist
- [x] Code compiles with zero errors
- [x] Linter passes with zero warnings
- [x] No TODO, FIXME, HACK, or XXX comments in committed code
- [x] Every specification requirement maps to at least one implemented component
- [x] Deviations from specification are documented with justification
- [x] Implementation summary artifact is written

## Known Failure Modes
<!-- Format: FM-N: short description / Trigger / Check / Added date -->
**FM-1: TODO placeholders left in committed code**
Trigger: Agent uses TODOs as development reminders but forgets to resolve them before gate check
Check: Run `grep -rn 'TODO\|FIXME\|HACK\|XXX' src/` and verify zero results
Added: 2026-03-05

**FM-2: Silent compilation warnings treated as acceptable**
Trigger: Agent focuses on errors but ignores warnings, which may hide real bugs
Check: Build output must show zero warnings, not just zero errors
Added: 2026-03-10

## Self-Improvement Hook
When downstream finds flaws in this stage's output:
1. Add to Known Failure Modes above with FM-N format
2. Add a checklist item to the Quality Gate Checklist
3. Log the incident in memory.md with date, stage, and root cause
4. Commit with `harness-fix(stage-2): description`
