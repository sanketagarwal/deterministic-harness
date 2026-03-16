# Stage 1: Session Parsing

## Purpose
Parse raw session data from Claude Code (~/.claude/) and Cursor (~/.cursor/) into a normalized intermediate representation. This stage extracts individual prompts, responses, timestamps, token counts, and metadata from each tool's native format, producing a unified dataset that downstream stages can consume without knowing the source tool.

## Artifacts
- **Input:** `~/.claude/`, `~/.cursor/` (raw session files)
- **Output:** `research/prompt-prof/stage-1-session-parsing-output.md`

## Command
**Command:** `manual`

## Instructions
1. Locate and enumerate all session files under `~/.claude/` and `~/.cursor/`, logging the file count and total byte size for each source.
2. For each session file, extract every user prompt along with its associated metadata: timestamp, token count, response length, tool calls made, and session ID.
3. Normalize extracted data into a common schema with fields: `source`, `session_id`, `timestamp`, `prompt_text`, `response_summary`, `token_count`, `tool_calls`.
4. Log any malformed or unparseable lines to a warnings section with the source file path and line number so they can be triaged.
5. Write the consolidated, normalized prompt list to the output artifact, including a summary header with total prompt count per source.

## Quality Gate Checklist
- [x] Both Claude Code and Cursor parsers executed and produced output
- [x] Total prompt count is non-zero
- [x] All schema fields (source, session_id, timestamp, prompt_text, response_summary, token_count, tool_calls) are populated for every entry
- [x] Malformed or unparseable lines are logged with file path and line number
- [x] `tsc` compiles without errors

## Known Failure Modes

**FM-1: System artifacts parsed as user prompts**
Trigger: Non-user-authored messages like "Tool loaded.", system status messages, or auto-generated content appear in parsed output
Check: Parser must tag or filter messages that are system-generated (e.g., "Tool loaded.", skill invocation confirmations). These must not reach the scoring stage as user prompts.
Added: 2026-03-16, from pipeline run 1 — Stage 3 blocked because system artifacts inflated the "Fair" scoring bucket

## Self-Improvement Hook
After completing Stage 1, review the quality gate checklist results and the warnings log. If any items failed or new edge cases were discovered, append a `## Retrospective` section to `research/prompt-prof/stage-1-session-parsing-output.md` documenting:
- What failed and why
- The fix or workaround applied
- Whether this failure mode should be added to Known Failure Modes for future runs
