# Stage 2: Prompt Classification — prompt-prof

## Results
- **Total prompts classified**: 858
- **Types found**: 6 (Code Generation, Questions, File Operations, Commands/Actions, Clarifications, Other)

## Distribution

| Type | Count | % |
|------|-------|---|
| Code Generation | 59 | 6.9% |
| Questions | 246 | 28.7% |
| File Operations | 131 | 15.3% |
| Commands/Actions | 137 | 16.0% |
| Clarifications | 64 | 7.5% |
| Other | 221 | 25.8% |

## Findings
- Clarification rate is 7.5% (64/858) — indicates ~1 in 13 prompts is a retry/correction
- "Other" is the second-largest category at 25.8% — worth investigating if classifier could be more specific
- "Tool loaded." entries classified as Other (system artifacts, not user prompts)
- Short prompts like "yes", "y", "n" classified as Commands/Actions

## Quality Gate Checklist
- [x] Every prompt has exactly one classification type assigned
- [x] Distribution includes at least 3 different types (6 types found)
- [x] Clarification detection checked: 64 prompts flagged as clarifications
- [x] Short prompts (<5 words) without action verbs classified as Commands or Other, not Code Generation
