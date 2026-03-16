# Stage 1: Session Parsing — prompt-prof

## Results
- **Claude Code parser**: PASSED — 740 prompts from 113 sessions (~/.claude/)
- **Cursor parser**: PASSED — 118 prompts from 3 transcripts (~/.cursor/)
- **Total prompts**: 858
- **Date range**: Past 30 days
- **TypeScript**: `npx tsc --noEmit` — PASSED (0 errors)

## Data Quality
- All prompts have: text, timestamp, sessionId, source fields
- No malformed JSONL lines detected
- "Tool loaded." entries parsed correctly (50 score, classified as system artifacts)

## Quality Gate Checklist
- [x] Both Claude Code and Cursor parsers ran without errors
- [x] Total prompt count is non-zero (858 prompts)
- [x] Each parsed prompt has: text, timestamp, sessionId, source fields populated
- [x] Malformed JSONL lines logged with count — 0 malformed
- [x] TypeScript compiles: `npx tsc --noEmit`
