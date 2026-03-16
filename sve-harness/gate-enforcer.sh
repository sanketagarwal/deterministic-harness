#!/bin/sh
# gate-enforcer.sh — Mechanical quality gate enforcement
# Usage: ./gate-enforcer.sh <stage-number> <project-name>
#
# Checks three things:
# 1. Output artifact exists for this stage
# 2. All checklist items in the stage skill file are checked
# 3. For human gates: approval file exists
#
# Exit 0 = PASSED, Exit 1 = BLOCKED

set -e

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <stage-number> <project-name>"
    echo "Example: $0 2 my-research-project"
    exit 1
fi

STAGE="$1"
PROJECT="$2"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Find the skill file for this stage
SKILL_FILE=""
for f in "$SCRIPT_DIR/skills/stage-${STAGE}-"*.md; do
    if [ -f "$f" ]; then
        SKILL_FILE="$f"
        break
    fi
done

if [ -z "$SKILL_FILE" ]; then
    echo "BLOCKED: No skill file found for stage ${STAGE}"
    echo "Expected: skills/stage-${STAGE}-*.md"
    exit 1
fi

SKILL_NAME="$(basename "$SKILL_FILE" .md | sed "s/^stage-${STAGE}-//")"
echo "=== Gate Enforcer: Stage ${STAGE} (${SKILL_NAME}) ==="
echo ""

# --- Check 1: Output artifact exists ---
# Extract output path from the skill file (line after "**Output:**")
OUTPUT_PATH="$(grep '\*\*Output:\*\*' "$SKILL_FILE" | head -1 | sed 's/.*`\(.*\)`.*/\1/')"

if [ -n "$OUTPUT_PATH" ]; then
    # Resolve relative to project directory
    RESOLVED_PATH="$SCRIPT_DIR/$OUTPUT_PATH"
    if [ -f "$RESOLVED_PATH" ]; then
        echo "CHECK 1 - Output artifact: FOUND ($OUTPUT_PATH)"
    else
        echo "CHECK 1 - Output artifact: MISSING ($OUTPUT_PATH)"
        echo "BLOCKED: Output artifact does not exist at $OUTPUT_PATH"
        exit 1
    fi
else
    echo "CHECK 1 - Output artifact: SKIPPED (no output path defined in skill file)"
fi

echo ""

# --- Check 2: All checklist items checked ---
# Count only lines starting with - [ ] or - [x] (anchored to start of line)
# This avoids matching examples in comments
TOTAL="$(grep -c '^- \[[ x]\]' "$SKILL_FILE" 2>/dev/null || true)"
CHECKED="$(grep -c '^- \[x\]' "$SKILL_FILE" 2>/dev/null || true)"
UNCHECKED="$(grep -c '^- \[ \]' "$SKILL_FILE" 2>/dev/null || true)"
TOTAL="${TOTAL:-0}"
CHECKED="${CHECKED:-0}"
UNCHECKED="${UNCHECKED:-0}"

echo "CHECK 2 - Quality gate checklist: ${CHECKED}/${TOTAL} items checked"

if [ "$UNCHECKED" -gt 0 ]; then
    echo ""
    echo "Unchecked items:"
    grep '^- \[ \]' "$SKILL_FILE" | while IFS= read -r line; do
        echo "  $line"
    done
    echo ""
    echo "BLOCKED: ${UNCHECKED} checklist item(s) remain unchecked"
    exit 1
fi

if [ "$TOTAL" -eq 0 ]; then
    echo "WARNING: No checklist items found in skill file"
fi

echo ""

# --- Check 3: Human gate approval ---
# Read pipeline.md to determine gate type for this stage
PIPELINE_FILE="$SCRIPT_DIR/pipeline.md"
GATE_TYPE="auto"

if [ -f "$PIPELINE_FILE" ]; then
    # Look for gate type in the stage section
    STAGE_SECTION="$(sed -n "/^### Stage ${STAGE}:/,/^### Stage/p" "$PIPELINE_FILE" | head -20)"
    if echo "$STAGE_SECTION" | grep -qi "gate type.*human"; then
        GATE_TYPE="human"
    elif echo "$STAGE_SECTION" | grep -qi "human"; then
        # Fallback: check if "human" appears in the stage header or gate line
        if echo "$STAGE_SECTION" | grep -qi "gate.*human\|human.*gate"; then
            GATE_TYPE="human"
        fi
    fi
fi

if [ "$GATE_TYPE" = "human" ]; then
    NOTION_APPROVED=false
    FILE_APPROVED=false

    # Check Notion gate first (if dashboard is configured)
    GATE_CHECK="$SCRIPT_DIR/../dashboard/notion/gate-check.js"
    if [ ! -f "$GATE_CHECK" ]; then
        # Try relative to harness root
        GATE_CHECK="$(cd "$SCRIPT_DIR" && cd .. 2>/dev/null && pwd)/dashboard/notion/gate-check.js"
    fi

    if [ -f "$GATE_CHECK" ]; then
        NOTION_RESULT="$(node "$GATE_CHECK" check "$PROJECT" "$STAGE" 2>/dev/null || true)"
        NOTION_STATUS="$(echo "$NOTION_RESULT" | head -1)"
        case "$NOTION_STATUS" in
            APPROVED)
                NOTION_APPROVED=true
                echo "CHECK 3a - Notion gate: APPROVED"
                ;;
            AUTO_GATE)
                echo "CHECK 3a - Notion gate: AUTO (no approval needed)"
                ;;
            NOT_APPROVED)
                echo "CHECK 3a - Notion gate: NOT APPROVED"
                echo "$(echo "$NOTION_RESULT" | tail -n +2)"
                ;;
            NOTION_NOT_CONFIGURED)
                echo "CHECK 3a - Notion gate: not configured (falling back to file-based approval)"
                ;;
            *)
                echo "CHECK 3a - Notion gate: unavailable (falling back to file-based approval)"
                ;;
        esac
    else
        echo "CHECK 3a - Notion gate: not installed (using file-based approval)"
    fi

    # Check file-based approval
    APPROVAL_FILE="$SCRIPT_DIR/research/${PROJECT}/.gate-${STAGE}-approved"
    if [ -f "$APPROVAL_FILE" ]; then
        FILE_APPROVED=true
        echo "CHECK 3b - File gate: APPROVED ($(cat "$APPROVAL_FILE"))"
    else
        echo "CHECK 3b - File gate: no approval file"
    fi

    # Either Notion OR file approval is sufficient
    if [ "$NOTION_APPROVED" = "true" ] || [ "$FILE_APPROVED" = "true" ]; then
        echo ""
        echo "CHECK 3 - Human gate approval: APPROVED"
    else
        echo ""
        echo "CHECK 3 - Human gate approval: NOT APPROVED"
        echo ""
        echo "BLOCKED: Stage ${STAGE} requires human approval."
        echo ""
        echo "Option 1 (Notion): Set stage status to 'passed' in the Notion dashboard"
        echo "Option 2 (File):   Create the file:"
        echo "  research/${PROJECT}/.gate-${STAGE}-approved"
        echo ""
        echo "Example:"
        echo "  echo 'Approved by <name> on <date>' > research/${PROJECT}/.gate-${STAGE}-approved"
        echo ""
        echo "The agent cannot approve its own gate. A human must review and approve."
        exit 1
    fi
else
    echo "CHECK 3 - Gate type: AUTO (no human approval required)"
fi

echo ""

# --- Result ---
NEXT_STAGE=$((STAGE + 1))
echo "==========================================="
echo "PASSED: Stage ${STAGE} (${SKILL_NAME}) gate cleared"
echo "Score: ${CHECKED}/${TOTAL} checklist items"
echo "Pipeline may advance to stage ${NEXT_STAGE}."
echo "==========================================="
exit 0
