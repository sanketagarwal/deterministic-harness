#!/bin/sh
# generate-claude-md.sh — Generate a CLAUDE.md for a deterministic harness pipeline
# Usage: ./generate-claude-md.sh <pipeline-dir>
#
# Reads pipeline.md, skills/, gate-enforcer.sh, and memory.md from the given
# directory, then writes a CLAUDE.md that tells an agent how to follow the pipeline.

set -e

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <pipeline-dir>"
    echo "Example: $0 examples/software-qa"
    exit 1
fi

PIPELINE_DIR="$(cd "$1" && pwd)"
PIPELINE_FILE="$PIPELINE_DIR/pipeline.md"
MEMORY_FILE="$PIPELINE_DIR/memory.md"
SKILLS_DIR="$PIPELINE_DIR/skills"
OUTPUT_FILE="$PIPELINE_DIR/CLAUDE.md"

# --- Validate inputs ---

if [ ! -f "$PIPELINE_FILE" ]; then
    echo "Error: pipeline.md not found in $PIPELINE_DIR"
    exit 1
fi

if [ ! -d "$SKILLS_DIR" ]; then
    echo "Error: skills/ directory not found in $PIPELINE_DIR"
    exit 1
fi

# --- Extract pipeline name ---

PIPELINE_NAME=""
# Try "# Pipeline: Name" format
PIPELINE_NAME="$(sed -n 's/^# Pipeline: *//p' "$PIPELINE_FILE" | head -1)"
# Try "# Name Pipeline" format
if [ -z "$PIPELINE_NAME" ]; then
    PIPELINE_NAME="$(sed -n 's/^# *\(.*\) Pipeline$/\1/p' "$PIPELINE_FILE" | head -1)"
fi
# Try first H1
if [ -z "$PIPELINE_NAME" ]; then
    PIPELINE_NAME="$(sed -n 's/^# *//p' "$PIPELINE_FILE" | head -1)"
fi
if [ -z "$PIPELINE_NAME" ]; then
    PIPELINE_NAME="$(basename "$PIPELINE_DIR")"
fi

# --- Extract project name (lowercase, hyphenated) ---

# Look for **Project:** field first
PROJECT_NAME="$(sed -n 's/.*\*\*Project:\*\* *//p' "$PIPELINE_FILE" | head -1)"
if [ -z "$PROJECT_NAME" ]; then
    PROJECT_NAME="$(echo "$PIPELINE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
fi

# --- Parse stages from pipeline.md ---
# Collect: stage number, name, gate type

STAGE_NUMBERS=""
STAGE_NAMES=""
STAGE_GATES=""
STAGE_COUNT=0

# Parse "### Stage N: Name" sections
while IFS= read -r line; do
    num="$(echo "$line" | sed -n 's/^### Stage \([0-9]*\): *\(.*\)/\1/p')"
    name="$(echo "$line" | sed -n 's/^### Stage \([0-9]*\): *\(.*\)/\2/p')"
    if [ -n "$num" ] && [ -n "$name" ]; then
        STAGE_COUNT=$((STAGE_COUNT + 1))
        eval "STAGE_NUM_${STAGE_COUNT}=\"$num\""
        eval "STAGE_NAME_${STAGE_COUNT}=\"$name\""
        # Default gate type
        eval "STAGE_GATE_${STAGE_COUNT}=\"auto\""
    fi
done < "$PIPELINE_FILE"

# Now extract gate types by re-reading sections
stage_idx=0
current_stage=""
while IFS= read -r line; do
    # Detect stage header
    num="$(echo "$line" | sed -n 's/^### Stage \([0-9]*\):.*/\1/p')"
    if [ -n "$num" ]; then
        current_stage="$num"
    fi
    # Detect gate type within current stage section
    if [ -n "$current_stage" ]; then
        gate="$(echo "$line" | sed -n 's/.*[Gg]ate type.*: *\(.*\)/\1/p' | tr -d '*' | tr -d ' ' | tr '[:upper:]' '[:lower:]')"
        if [ -z "$gate" ]; then
            gate="$(echo "$line" | sed -n 's/.*\*\*Gate type:\*\* *\(.*\)/\1/p' | tr -d ' ' | tr '[:upper:]' '[:lower:]')"
        fi
        if [ -n "$gate" ]; then
            # Find which index this stage is
            idx=1
            while [ "$idx" -le "$STAGE_COUNT" ]; do
                eval "sn=\$STAGE_NUM_${idx}"
                if [ "$sn" = "$current_stage" ]; then
                    eval "STAGE_GATE_${idx}=\"$gate\""
                    break
                fi
                idx=$((idx + 1))
            done
            current_stage=""
        fi
    fi
done < "$PIPELINE_FILE"

# --- Extract commands from skill files ---

idx=1
while [ "$idx" -le "$STAGE_COUNT" ]; do
    eval "snum=\$STAGE_NUM_${idx}"
    eval "STAGE_CMD_${idx}=\"\""

    # Find matching skill file
    for f in "$SKILLS_DIR"/stage-"${snum}"-*.md; do
        if [ -f "$f" ]; then
            cmd="$(sed -n 's/.*\*\*Command:\*\* *`\(.*\)`/\1/p' "$f" | head -1)"
            if [ -n "$cmd" ]; then
                eval "STAGE_CMD_${idx}=\"$cmd\""
            fi
            # Also store skill filename
            eval "STAGE_SKILL_${idx}=\"$(basename "$f")\""
            break
        fi
    done

    # Fallback skill name if file not found
    eval "sk=\$STAGE_SKILL_${idx}"
    if [ -z "$sk" ]; then
        eval "sname=\$STAGE_NAME_${idx}"
        skill_slug="$(echo "$sname" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
        eval "STAGE_SKILL_${idx}=\"stage-${snum}-${skill_slug}.md\""
    fi

    idx=$((idx + 1))
done

# --- Parse memory.md for failure entries ---

FAILURE_ENTRIES=""
if [ -f "$MEMORY_FILE" ]; then
    in_failure_log=0
    in_table=0
    while IFS= read -r line; do
        # Detect Failure Log section
        case "$line" in
            *"Failure Log"*|*"failure log"*|*"Known Failure"*|*"Failure Mode"*)
                in_failure_log=1
                in_table=0
                continue
                ;;
        esac
        # Detect next section header (stop collecting)
        if [ "$in_failure_log" -eq 1 ]; then
            case "$line" in
                "## "*)
                    in_failure_log=0
                    continue
                    ;;
            esac
        fi
        # Collect table rows (skip header and separator)
        if [ "$in_failure_log" -eq 1 ]; then
            case "$line" in
                "| Date"*|"|---"*|"<!--"*|"-->"*|"")
                    continue
                    ;;
                "| "*)
                    # Extract stage and what happened
                    stage_col="$(echo "$line" | cut -d'|' -f3 | tr -d ' ')"
                    what_col="$(echo "$line" | cut -d'|' -f4 | sed 's/^ *//;s/ *$//')"
                    if [ -n "$stage_col" ] && [ -n "$what_col" ]; then
                        short_what="$(echo "$what_col" | cut -c1-120)"
                        FAILURE_ENTRIES="${FAILURE_ENTRIES}
- **Stage ${stage_col}:** ${short_what}"
                    fi
                    ;;
            esac
        fi
    done < "$MEMORY_FILE"
fi

# --- Parse patterns from memory.md ---

PATTERNS=""
if [ -f "$MEMORY_FILE" ]; then
    in_patterns=0
    while IFS= read -r line; do
        case "$line" in
            "## Patterns"*|"## patterns"*)
                in_patterns=1
                continue
                ;;
        esac
        if [ "$in_patterns" -eq 1 ]; then
            case "$line" in
                "## "*)
                    in_patterns=0
                    continue
                    ;;
                "- "*)
                    PATTERNS="${PATTERNS}
${line}"
                    ;;
            esac
        fi
    done < "$MEMORY_FILE"
fi

# --- Generate CLAUDE.md ---

{
    cat <<HEADER
# Pipeline: ${PIPELINE_NAME}

This project uses a [deterministic harness](https://github.com/sanketagarwal/deterministic-harness) for quality control. Follow the pipeline below.

## Pipeline

| Stage | Name | Gate | Command |
|-------|------|------|---------|
HEADER

    # Write table rows
    idx=1
    while [ "$idx" -le "$STAGE_COUNT" ]; do
        eval "snum=\$STAGE_NUM_${idx}"
        eval "sname=\$STAGE_NAME_${idx}"
        eval "sgate=\$STAGE_GATE_${idx}"
        eval "scmd=\$STAGE_CMD_${idx}"

        if [ -n "$scmd" ]; then
            cmd_display="\`${scmd}\`"
        else
            cmd_display="—"
        fi

        printf '| %s | %s | %s | %s |\n' "$snum" "$sname" "$sgate" "$cmd_display"
        idx=$((idx + 1))
    done

    cat <<'RULES'

## Rules

1. Work through stages in order. Do not skip stages.
RULES

    # Stage-specific skill file instructions
    idx=1
    while [ "$idx" -le "$STAGE_COUNT" ]; do
        eval "snum=\$STAGE_NUM_${idx}"
        eval "sname=\$STAGE_NAME_${idx}"
        eval "sskill=\$STAGE_SKILL_${idx}"
        printf '   - Before starting Stage %s, read `skills/%s` for instructions and quality gate checklist.\n' "$snum" "$sskill"
        idx=$((idx + 1))
    done

    cat <<ENFORCER
2. After completing a stage, run: \`./gate-enforcer.sh N ${PROJECT_NAME}\` (replace N with the stage number).
3. If gate-enforcer says BLOCKED, fix the issue before advancing.
4. For human gates, stop and wait. Do not create approval files yourself.
5. Check memory.md for known failure modes before each run.
6. If a stage should kill the pipeline, that is a valid outcome. Document the verdict.
7. After verification, read \`.improvements/self-improve.md\`, fill it in, and commit fixes with \`harness-fix(stage-N): description\`.
8. For every issue found in verification, identify which earlier stage should have caught it, and add a checklist item or failure mode to that stage's skill file.
ENFORCER

    echo ""
    echo "## Stage Instructions"
    echo ""
    echo "Read the skill file for your current stage before starting work. Each skill file contains:"
    echo "- Purpose and context"
    echo "- Step-by-step instructions"
    echo "- Quality gate checklist (all items must be checked before the gate will pass)"
    echo "- Known failure modes specific to that stage"
    echo ""
    echo "## Known Failure Modes"

    if [ -n "$FAILURE_ENTRIES" ]; then
        echo "$FAILURE_ENTRIES"
    else
        echo ""
        echo "No failure modes recorded yet. They will accumulate in memory.md as the pipeline runs."
    fi

    if [ -n "$PATTERNS" ]; then
        echo ""
        echo "### Patterns"
        echo "$PATTERNS"
    fi

    cat <<'VERDICTS'

## Verdicts

Every pipeline run ends with one of these verdicts:

- **PURSUE** — Signal is strong, proceed to execution/deployment.
- **INVESTIGATE** — Signal exists but needs more work before committing resources.
- **MONITOR** — Not actionable now, but worth tracking. Define what would change the verdict.
- **ARCHIVE** — No signal found, or signal is not worth pursuing. Document why.

Any stage can kill the pipeline. A documented kill with clear reasoning is a successful outcome.
VERDICTS

} > "$OUTPUT_FILE"

echo "Generated: $OUTPUT_FILE"
echo ""
echo "Pipeline: $PIPELINE_NAME ($STAGE_COUNT stages)"
echo "Project:  $PROJECT_NAME"
echo ""

idx=1
while [ "$idx" -le "$STAGE_COUNT" ]; do
    eval "snum=\$STAGE_NUM_${idx}"
    eval "sname=\$STAGE_NAME_${idx}"
    eval "sgate=\$STAGE_GATE_${idx}"
    eval "sskill=\$STAGE_SKILL_${idx}"
    printf '  Stage %s: %-20s [%s] -> skills/%s\n' "$snum" "$sname" "$sgate" "$sskill"
    idx=$((idx + 1))
done

if [ -n "$FAILURE_ENTRIES" ]; then
    echo ""
    echo "Included failure modes from memory.md"
fi
