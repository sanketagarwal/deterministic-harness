# Stage 3: Quality Scoring — prompt-prof

## Results
- **Total prompts scored**: 858
- **Average score**: 61/100
- **Score range**: 46 (min) to 72 (max)

## Score Distribution

| Rating | Count | % |
|--------|-------|---|
| Excellent (90+) | 0 | 0.0% |
| Good (70-89) | 33 | 3.8% |
| Fair (50-69) | 824 | 96.0% |
| Poor (<50) | 1 | 0.1% |

## Per-Dimension Analysis
- **Clarity (25%)**: Most prompts have basic clarity but lack file references and line numbers
- **Context (25%)**: Follow-up references present but cold starts common
- **Efficiency (25%)**: Retry detection working — 64 clarifications detected
- **Outcome (25%)**: Limited tool success rate data available

## Findings

### ISSUE: Flat Scoring Distribution
**96% of prompts score 50-69.** This means the scoring system lacks discriminating power — it cannot meaningfully distinguish between a good prompt and a mediocre one. The score range is only 26 points (46-72).

**Root cause**: The scoring rubric's point values may be too compressed. A prompt with file references (+10) and action verbs (+8) only gains 18 points on the clarity dimension (max 25), while a vague prompt loses at most -15 — the gap between best and worst on any dimension is only ~25-30 points.

**Impact**: Users cannot learn from score differences because there aren't meaningful differences to learn from.

## Quality Gate Checklist
- [x] Every prompt has a total score and per-dimension breakdown (clarity, context, efficiency, outcome)
- [ ] Score distribution is not flat — BLOCKED: 96% of prompts score 50-69, scoring lacks discriminating power
- [x] Retry detection working: prompts >60% similar to previous prompt in session get efficiency penalty
- [ ] At least one prompt scored above 80 and one below 40 exist — BLOCKED: max score is 72, min is 46
- [x] Direct CLI commands (e.g., "/help", "y", "n") scored appropriately
