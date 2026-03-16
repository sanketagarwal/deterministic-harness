# Pipeline: Software QA

## Metadata
- **Project:** software-qa
- **Created:** 2026-03-10
- **Current Stage:** 5 (Release)
- **Status:** Complete

## Stages

### Stage 1: Specification
- **Gate type:** human
- **Skill file:** `skills/stage-1-specification.md`
- **Status:** PASSED
- **Description:** Define feature requirements with clear acceptance criteria, identify edge cases, and bound scope to prevent feature creep. A human reviewer must confirm the specification is testable and complete before implementation begins.

### Stage 2: Implementation
- **Gate type:** auto
- **Skill file:** `skills/stage-2-implementation.md`
- **Status:** PASSED
- **Description:** Build the feature according to the approved specification. Code must compile, pass linting, and contain no placeholder TODOs. The auto gate verifies mechanical quality before testing begins.

### Stage 3: Testing
- **Gate type:** auto
- **Skill file:** `skills/stage-3-testing.md`
- **Status:** PASSED
- **Description:** Write and execute unit tests, integration tests, and end-to-end tests. Coverage must exceed the project threshold. The auto gate enforces that all test suites pass before verification.

### Stage 4: Verification
- **Gate type:** human
- **Skill file:** `skills/stage-4-verification.md`
- **Status:** PASSED
- **Description:** Adversarial review — actively try to break the implementation. Verify edge cases, benchmark performance, and check for regressions. Includes self-improvement analysis to strengthen the pipeline based on findings. Requires human sign-off.

### Stage 5: Release
- **Gate type:** human
- **Skill file:** `skills/stage-5-release.md`
- **Status:** PASSED
- **Description:** Final human verdict. Confirm changelog is written, documentation is updated, and all previous gates have passed. The release decision is always a human call.

## Gate Enforcement
Run `./gate-enforcer.sh <stage> software-qa` before advancing to the next stage.
No stage may be skipped. Each gate must return exit code 0 before the next stage begins.

## Notes
- Stages 1, 4, and 5 require human approval files at `research/software-qa/.gate-N-approved`
- The agent cannot create approval files — only a human reviewer can
- Self-improvement findings from Stage 4 feed back into earlier stage checklists
