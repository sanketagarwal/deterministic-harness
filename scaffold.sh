#!/bin/sh
# scaffold.sh — Create a self-improving agent harness for any domain
# Works on macOS and Linux (POSIX sh compatible)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
SCAN_FILE=""

# --- Parse arguments ---
while [ "$#" -gt 0 ]; do
    case "$1" in
        --from-scan)
            SCAN_FILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "=== Deterministic Harness Scaffold ==="
echo ""

# --- Helper: get value from scan config ---
scan_val() {
    if [ -n "$SCAN_FILE" ] && [ -f "$SCAN_FILE" ]; then
        grep "^${1}=" "$SCAN_FILE" 2>/dev/null | head -1 | sed 's/^[^=]*=//' | sed 's/^"//;s/"$//'
    fi
}

# --- Gather input (with scan defaults) ---

DEFAULT_NAME="$(scan_val PIPELINE_NAME)"
if [ -n "$DEFAULT_NAME" ]; then
    printf "Pipeline name [${DEFAULT_NAME}]: "
    read PIPELINE_NAME
    PIPELINE_NAME="${PIPELINE_NAME:-$DEFAULT_NAME}"
else
    printf "Pipeline name (e.g., my-research-pipeline): "
    read PIPELINE_NAME
fi

if [ -z "$PIPELINE_NAME" ]; then
    echo "Error: Pipeline name is required."
    exit 1
fi

DEFAULT_DOMAIN="$(scan_val DOMAIN)"
if [ -n "$DEFAULT_DOMAIN" ]; then
    printf "Domain [${DEFAULT_DOMAIN}]: "
    read DOMAIN
    DOMAIN="${DOMAIN:-$DEFAULT_DOMAIN}"
else
    printf "Domain (e.g., research, software-qa, security-audit): "
    read DOMAIN
fi

if [ -z "$DOMAIN" ]; then
    echo "Error: Domain is required."
    exit 1
fi

DEFAULT_STAGES="$(scan_val NUM_STAGES)"
DEFAULT_STAGES="${DEFAULT_STAGES:-5}"
printf "Number of stages [${DEFAULT_STAGES}]: "
read NUM_STAGES
NUM_STAGES="${NUM_STAGES:-$DEFAULT_STAGES}"

# Validate number
case "$NUM_STAGES" in
    ''|*[!0-9]*)
        echo "Error: Number of stages must be a positive integer."
        exit 1
        ;;
esac

if [ "$NUM_STAGES" -lt 2 ]; then
    echo "Error: Need at least 2 stages."
    exit 1
fi

echo ""
echo "Enter a name for each stage:"
STAGE_NAMES=""
STAGE_GATES=""
STAGE_CMDS=""
STAGE_CHECKLISTS=""
i=1
while [ "$i" -le "$NUM_STAGES" ]; do
    DEFAULT_SNAME="$(scan_val "STAGE_${i}_NAME")"
    DEFAULT_GATE="$(scan_val "STAGE_${i}_GATE")"
    DEFAULT_CMD="$(scan_val "STAGE_${i}_CMD")"
    DEFAULT_CL1="$(scan_val "STAGE_${i}_CHECKLIST_1")"
    DEFAULT_CL2="$(scan_val "STAGE_${i}_CHECKLIST_2")"
    DEFAULT_CL3="$(scan_val "STAGE_${i}_CHECKLIST_3")"

    if [ -n "$DEFAULT_SNAME" ]; then
        printf "  Stage ${i} [${DEFAULT_SNAME}]: "
        read STAGE_NAME
        STAGE_NAME="${STAGE_NAME:-$DEFAULT_SNAME}"
    else
        printf "  Stage ${i}: "
        read STAGE_NAME
    fi

    if [ -z "$STAGE_NAME" ]; then
        echo "Error: Stage name is required."
        exit 1
    fi

    # Accumulate pipe-delimited lists
    if [ -z "$STAGE_NAMES" ]; then
        STAGE_NAMES="$STAGE_NAME"
        STAGE_GATES="${DEFAULT_GATE}"
        STAGE_CMDS="${DEFAULT_CMD}"
        STAGE_CHECKLISTS="${DEFAULT_CL1};;${DEFAULT_CL2};;${DEFAULT_CL3}"
    else
        STAGE_NAMES="$STAGE_NAMES|$STAGE_NAME"
        STAGE_GATES="$STAGE_GATES|${DEFAULT_GATE}"
        STAGE_CMDS="$STAGE_CMDS|${DEFAULT_CMD}"
        STAGE_CHECKLISTS="$STAGE_CHECKLISTS|${DEFAULT_CL1};;${DEFAULT_CL2};;${DEFAULT_CL3}"
    fi
    i=$((i + 1))
done

TODAY="$(date +%Y-%m-%d)"

echo ""
echo "Creating pipeline: $PIPELINE_NAME"
echo "Domain: $DOMAIN"
echo "Stages: $NUM_STAGES"
echo ""

# --- Create directory structure ---

PROJECT_DIR="$SCRIPT_DIR/$PIPELINE_NAME"

if [ -d "$PROJECT_DIR" ]; then
    echo "Error: Directory '$PIPELINE_NAME' already exists."
    exit 1
fi

mkdir -p "$PROJECT_DIR/skills"
mkdir -p "$PROJECT_DIR/research"
mkdir -p "$PROJECT_DIR/.improvements"

# --- Helper: get value from pipe-delimited list by index ---
get_stage_name() {
    idx="$1"
    echo "$STAGE_NAMES" | tr '|' '\n' | sed -n "${idx}p"
}

get_stage_gate() {
    idx="$1"
    val="$(echo "$STAGE_GATES" | tr '|' '\n' | sed -n "${idx}p")"
    if [ -n "$val" ]; then
        echo "$val"
    elif [ "$idx" -eq 1 ] || [ "$idx" -eq "$NUM_STAGES" ]; then
        echo "human"
    else
        echo "auto"
    fi
}

get_stage_cmd() {
    idx="$1"
    echo "$STAGE_CMDS" | tr '|' '\n' | sed -n "${idx}p"
}

get_stage_checklist() {
    idx="$1"
    item="$2"
    line="$(echo "$STAGE_CHECKLISTS" | tr '|' '\n' | sed -n "${idx}p")"
    echo "$line" | sed 's/;;/\n/g' | sed -n "${item}p"
}

# --- Helper: slugify a name ---
slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//'
}

# --- Generate pipeline.md ---

{
    echo "# ${PIPELINE_NAME} Pipeline"
    echo ""
    echo "**Domain:** ${DOMAIN}"
    echo "**Created:** ${TODAY}"
    echo "**Stages:** ${NUM_STAGES}"
    echo ""
    echo "---"
    echo ""

    i=1
    while [ "$i" -le "$NUM_STAGES" ]; do
        SNAME="$(get_stage_name "$i")"
        SLUG="$(slugify "$SNAME")"

        GATE="$(get_stage_gate "$i")"

        # Determine input/output paths
        if [ "$i" -eq 1 ]; then
            INPUT="(pipeline input)"
        else
            PREV_NAME="$(get_stage_name $((i - 1)))"
            PREV_SLUG="$(slugify "$PREV_NAME")"
            INPUT="research/${PIPELINE_NAME}/stage-$((i - 1))-${PREV_SLUG}-output.md"
        fi
        OUTPUT="research/${PIPELINE_NAME}/stage-${i}-${SLUG}-output.md"

        echo "### Stage ${i}: ${SNAME}"
        echo ""
        echo "**Purpose:** <!-- Define the purpose of this stage -->"
        echo "**Gate type:** ${GATE}"
        echo "**Input artifact:** \`${INPUT}\`"
        echo "**Output artifact:** \`${OUTPUT}\`"
        echo ""
        CL1="$(get_stage_checklist "$i" 1)"
        CL2="$(get_stage_checklist "$i" 2)"
        CL3="$(get_stage_checklist "$i" 3)"
        echo "#### Quality Gate Checklist"
        echo "- [ ] ${CL1:-<!-- Item 1 -->}"
        echo "- [ ] ${CL2:-<!-- Item 2 -->}"
        echo "- [ ] ${CL3:-<!-- Item 3 -->}"
        echo ""
        echo "#### Known Failure Modes"
        echo "<!-- Populated over time from retrospectives and self-improvement analysis -->"
        echo ""
        echo "---"
        echo ""

        i=$((i + 1))
    done

    echo "## Gate Rules"
    echo ""
    echo "**Human Gate:** Requires explicit human approval before the pipeline advances. The agent produces its output and checklist, then waits. A human reviews and creates an approval file at \`research/${PIPELINE_NAME}/.gate-{stage}-approved\` to unlock the next stage. The agent cannot create this file."
    echo ""
    echo "**Auto Gate:** The gate enforcer checks mechanically — output artifact exists, all checklist items checked. If both conditions are met, the pipeline advances automatically."
    echo ""
    echo "---"
    echo ""
    echo "## Verdicts"
    echo ""
    echo "- **PURSUE** — Signal is strong, proceed to execution/deployment."
    echo "- **INVESTIGATE** — Signal exists but needs more work before committing resources."
    echo "- **MONITOR** — Not actionable now, but worth tracking."
    echo "- **ARCHIVE** — No signal found, or signal is not worth pursuing. Document why."
    echo ""
    echo "Any stage can kill the pipeline. A documented kill with clear reasoning is a successful outcome."
} > "$PROJECT_DIR/pipeline.md"

# --- Generate memory.md ---

sed -e "s/{{PIPELINE_NAME}}/${PIPELINE_NAME}/g" \
    -e "s/{{DATE}}/${TODAY}/g" \
    "$TEMPLATES_DIR/MEMORY.md" > "$PROJECT_DIR/memory.md"

# --- Generate gate-enforcer.sh ---

cp "$TEMPLATES_DIR/gate-enforcer.sh" "$PROJECT_DIR/gate-enforcer.sh"
chmod +x "$PROJECT_DIR/gate-enforcer.sh"

# --- Generate skill files ---

i=1
while [ "$i" -le "$NUM_STAGES" ]; do
    SNAME="$(get_stage_name "$i")"
    SLUG="$(slugify "$SNAME")"

    if [ "$i" -eq 1 ]; then
        INPUT="(pipeline input)"
    else
        PREV_NAME="$(get_stage_name $((i - 1)))"
        PREV_SLUG="$(slugify "$PREV_NAME")"
        INPUT="research/${PIPELINE_NAME}/stage-$((i - 1))-${PREV_SLUG}-output.md"
    fi
    OUTPUT="research/${PIPELINE_NAME}/stage-${i}-${SLUG}-output.md"

    SCMD="$(get_stage_cmd "$i")"
    CL1="$(get_stage_checklist "$i" 1)"
    CL2="$(get_stage_checklist "$i" 2)"
    CL3="$(get_stage_checklist "$i" 3)"

    # Escape sed-special characters in command string
    SCMD_ESCAPED="$(echo "$SCMD" | sed 's/[&/\\]/\\&/g')"
    CL1_ESCAPED="$(echo "$CL1" | sed 's/[&/\\]/\\&/g')"
    CL2_ESCAPED="$(echo "$CL2" | sed 's/[&/\\]/\\&/g')"
    CL3_ESCAPED="$(echo "$CL3" | sed 's/[&/\\]/\\&/g')"

    SNAME_ESCAPED="$(echo "$SNAME" | sed 's/[&/\\]/\\&/g')"

    sed -e "s/{{STAGE_NUM}}/${i}/g" \
        -e "s/{{STAGE_NAME}}/${SNAME_ESCAPED}/g" \
        -e "s|{{INPUT_PATH}}|${INPUT}|g" \
        -e "s|{{OUTPUT_PATH}}|${OUTPUT}|g" \
        "$TEMPLATES_DIR/skill-template.md" > "$PROJECT_DIR/skills/stage-${i}-${SLUG}.md"

    # Replace command placeholder (use | delimiter to avoid issues with /)
    sed -i.bak "s|{{COMMAND}}|${SCMD_ESCAPED}|g" "$PROJECT_DIR/skills/stage-${i}-${SLUG}.md"

    # Replace checklist placeholders if scan provided values
    if [ -n "$CL1" ]; then
        sed -i.bak "s|{{Checklist item 1}}|${CL1_ESCAPED}|" "$PROJECT_DIR/skills/stage-${i}-${SLUG}.md"
    fi
    if [ -n "$CL2" ]; then
        sed -i.bak "s|{{Checklist item 2}}|${CL2_ESCAPED}|" "$PROJECT_DIR/skills/stage-${i}-${SLUG}.md"
    fi
    if [ -n "$CL3" ]; then
        sed -i.bak "s|{{Checklist item 3}}|${CL3_ESCAPED}|" "$PROJECT_DIR/skills/stage-${i}-${SLUG}.md"
    fi
    rm -f "$PROJECT_DIR/skills/stage-${i}-${SLUG}.md.bak"

    i=$((i + 1))
done

# --- Generate self-improve.md and retrospective.md ---

sed -e "s/{{PIPELINE_NAME}}/${PIPELINE_NAME}/g" \
    -e "s/{{DATE}}/${TODAY}/g" \
    "$TEMPLATES_DIR/self-improve.md" > "$PROJECT_DIR/.improvements/self-improve.md"

sed -e "s/{{PIPELINE_NAME}}/${PIPELINE_NAME}/g" \
    -e "s/{{DATE}}/${TODAY}/g" \
    "$TEMPLATES_DIR/retrospective.md" > "$PROJECT_DIR/.improvements/retrospective.md"

# --- Initialize git repo ---

cd "$PROJECT_DIR"
git init -q
git add -A
git commit -q -m "Initialize ${PIPELINE_NAME} harness

Domain: ${DOMAIN}
Stages: ${NUM_STAGES}
Generated by deterministic-harness scaffold.sh"

echo "=== Done ==="
echo ""
echo "Created: ${PIPELINE_NAME}/"
echo ""
ls -la "$PROJECT_DIR"
echo ""
echo "--- Next steps ---"
echo ""
echo "1. Review pipeline.md — stages, gate types, and checklists"
echo "2. Review skill files in skills/ — instructions and commands"
echo "3. Run the pipeline:"
echo "   ${SCRIPT_DIR}/run-pipeline.sh ${PROJECT_DIR} <project-name>"
echo "4. Generate CLAUDE.md for agent integration:"
echo "   ${SCRIPT_DIR}/generate-claude-md.sh ${PROJECT_DIR}"
echo "5. After each run, complete .improvements/retrospective.md"
echo ""
echo "The harness improves itself. Every failure → root cause → mechanical fix → never repeat."
