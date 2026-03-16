#!/bin/sh
# scaffold.sh — Create a self-improving agent harness for any domain
# Works on macOS and Linux (POSIX sh compatible)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

echo "=== Deterministic Harness Scaffold ==="
echo ""

# --- Gather input ---

printf "Pipeline name (e.g., my-research-pipeline): "
read PIPELINE_NAME

if [ -z "$PIPELINE_NAME" ]; then
    echo "Error: Pipeline name is required."
    exit 1
fi

printf "Domain (e.g., research, software-qa, security-audit): "
read DOMAIN

if [ -z "$DOMAIN" ]; then
    echo "Error: Domain is required."
    exit 1
fi

printf "Number of stages [5]: "
read NUM_STAGES
NUM_STAGES="${NUM_STAGES:-5}"

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
i=1
while [ "$i" -le "$NUM_STAGES" ]; do
    printf "  Stage ${i}: "
    read STAGE_NAME
    if [ -z "$STAGE_NAME" ]; then
        echo "Error: Stage name is required."
        exit 1
    fi
    if [ -z "$STAGE_NAMES" ]; then
        STAGE_NAMES="$STAGE_NAME"
    else
        STAGE_NAMES="$STAGE_NAMES|$STAGE_NAME"
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

# --- Helper: get stage name by index ---
get_stage_name() {
    idx="$1"
    echo "$STAGE_NAMES" | tr '|' '\n' | sed -n "${idx}p"
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

        # Default gate type: first and last are human, middle are auto
        if [ "$i" -eq 1 ] || [ "$i" -eq "$NUM_STAGES" ]; then
            GATE="human"
        else
            GATE="auto"
        fi

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
        echo "#### Quality Gate Checklist"
        echo "- [ ] <!-- Item 1 -->"
        echo "- [ ] <!-- Item 2 -->"
        echo "- [ ] <!-- Item 3 -->"
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

    sed -e "s/{{STAGE_NUM}}/${i}/g" \
        -e "s/{{STAGE_NAME}}/${SNAME}/g" \
        -e "s|{{INPUT_PATH}}|${INPUT}|g" \
        -e "s|{{OUTPUT_PATH}}|${OUTPUT}|g" \
        "$TEMPLATES_DIR/skill-template.md" > "$PROJECT_DIR/skills/stage-${i}-${SLUG}.md"

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
echo "1. Edit pipeline.md to define the purpose of each stage"
echo "2. Edit each skill file in skills/ to add stage-specific instructions and checklist items"
echo "3. Run your first pipeline pass"
echo "4. After each run, complete .improvements/retrospective.md"
echo "5. Use gate-enforcer.sh to enforce gates:"
echo "   ./gate-enforcer.sh <stage-number> <project-name>"
echo ""
echo "The harness improves itself. Every failure → root cause → mechanical fix → never repeat."
