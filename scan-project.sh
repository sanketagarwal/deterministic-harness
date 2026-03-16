#!/bin/sh
# scan-project.sh — Auto-read a project and suggest a deterministic harness pipeline
# Works on macOS and Linux (POSIX sh compatible)
#
# Usage: ./scan-project.sh /path/to/project
#
# Scans for package managers, CI configs, test frameworks, linting, build commands,
# docs, and git history. Outputs a suggested pipeline that scaffold.sh can consume.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUTO_ACCEPT=false
CONFIG_ONLY=false

# ─── Helpers ──────────────────────────────────────────────────────────────────

die() { printf "Error: %s\n" "$1" >&2; exit 1; }

# Print a section header
section() { printf "\n\033[1;36m=== %s ===\033[0m\n" "$1"; }

# Print a detection result
detected() { printf "  \033[1;32m[+]\033[0m %s\n" "$1"; }
not_detected() { printf "  \033[1;33m[-]\033[0m %s\n" "$1"; }

# Prompt user with choices. Sets REPLY.
prompt_yne() {
    if [ "$AUTO_ACCEPT" = "true" ]; then
        REPLY="y"
        return
    fi
    printf "\n\033[1;33m%s\033[0m [y/n/edit] (default: y): " "$1"
    read REPLY </dev/tty
    REPLY="${REPLY:-y}"
}

# Prompt for freeform text. Sets REPLY.
prompt_text() {
    if [ "$AUTO_ACCEPT" = "true" ]; then
        REPLY=""
        return
    fi
    printf "  %s: " "$1"
    read REPLY </dev/tty
}

# ─── Validate arguments ──────────────────────────────────────────────────────

# Parse flags
PROJECT_DIR=""
while [ $# -gt 0 ]; do
    case "$1" in
        --auto-accept) AUTO_ACCEPT=true; shift ;;
        --config-only) CONFIG_ONLY=true; AUTO_ACCEPT=true; shift ;;
        -*) die "Unknown flag: $1" ;;
        *) PROJECT_DIR="$1"; shift ;;
    esac
done

if [ -z "$PROJECT_DIR" ]; then
    printf "Usage: %s [--auto-accept] [--config-only] /path/to/project\n" "$0"
    exit 1
fi
[ -d "$PROJECT_DIR" ] || die "Directory not found: $PROJECT_DIR"

# Resolve to absolute path
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
PROJECT_BASENAME="$(basename "$PROJECT_DIR")"

printf "\033[1m=== Deterministic Harness — Project Scanner ===\033[0m\n"
printf "Scanning: %s\n" "$PROJECT_DIR"

# ─── Detection: Package Manager ──────────────────────────────────────────────

section "Package Manager"

PKG_MANAGER=""
PKG_SCRIPTS=""

if [ -f "$PROJECT_DIR/package.json" ]; then
    # Detect which node package manager
    if [ -f "$PROJECT_DIR/pnpm-lock.yaml" ]; then
        PKG_MANAGER="pnpm"
    elif [ -f "$PROJECT_DIR/yarn.lock" ]; then
        PKG_MANAGER="yarn"
    elif [ -f "$PROJECT_DIR/package-lock.json" ]; then
        PKG_MANAGER="npm"
    else
        PKG_MANAGER="npm"
    fi
    detected "Node.js project — package manager: $PKG_MANAGER"

    # Extract scripts from package.json (portable: no jq dependency)
    if command -v python3 >/dev/null 2>&1; then
        PKG_SCRIPTS="$(python3 -c "
import json, sys
try:
    d = json.load(open('$PROJECT_DIR/package.json'))
    scripts = d.get('scripts', {})
    for k in scripts:
        print(k)
except Exception:
    pass
" 2>/dev/null)" || PKG_SCRIPTS=""
    fi

    if [ -n "$PKG_SCRIPTS" ]; then
        detected "Scripts found: $(echo "$PKG_SCRIPTS" | tr '\n' ', ' | sed 's/,$//')"
    fi
elif [ -f "$PROJECT_DIR/Cargo.toml" ]; then
    PKG_MANAGER="cargo"
    detected "Rust project — cargo"
elif [ -f "$PROJECT_DIR/pyproject.toml" ]; then
    if [ -f "$PROJECT_DIR/poetry.lock" ]; then
        PKG_MANAGER="poetry"
    else
        PKG_MANAGER="pip"
    fi
    detected "Python project — $PKG_MANAGER"
elif [ -f "$PROJECT_DIR/Gemfile" ]; then
    PKG_MANAGER="bundler"
    detected "Ruby project — bundler"
elif [ -f "$PROJECT_DIR/go.mod" ]; then
    PKG_MANAGER="go"
    detected "Go project — go modules"
elif [ -f "$PROJECT_DIR/Makefile" ] || [ -f "$PROJECT_DIR/makefile" ]; then
    PKG_MANAGER="make"
    detected "Makefile found — make"
else
    PKG_MANAGER="unknown"
    not_detected "No recognized package manager found — using defaults"
fi

# ─── Detection: CI Config ────────────────────────────────────────────────────

section "CI Configuration"

CI_JOBS=""

if [ -d "$PROJECT_DIR/.github/workflows" ]; then
    detected "GitHub Actions workflows found"
    # Parse job names from workflow files
    for wf in "$PROJECT_DIR/.github/workflows"/*.yml "$PROJECT_DIR/.github/workflows"/*.yaml; do
        [ -f "$wf" ] || continue
        wf_name="$(basename "$wf")"
        # Extract job names (lines matching "  jobname:" under "jobs:")
        if command -v python3 >/dev/null 2>&1; then
            jobs="$(python3 -c "
import sys
in_jobs = False
for line in open('$wf'):
    stripped = line.rstrip()
    if stripped == 'jobs:':
        in_jobs = True
        continue
    if in_jobs:
        if line[0:1] not in (' ', '\t') and stripped:
            in_jobs = False
            continue
        # Two-space or one-level indent under jobs
        if len(line) - len(line.lstrip()) == 2 and stripped.endswith(':'):
            print(stripped.rstrip(':').strip())
" 2>/dev/null)" || jobs=""
        else
            # Fallback: rough grep
            jobs="$(sed -n '/^jobs:/,/^[^ ]/{ /^  [a-zA-Z].*:$/{ s/://; s/^ *//; p; } }' "$wf" 2>/dev/null)" || jobs=""
        fi
        if [ -n "$jobs" ]; then
            detected "  $wf_name jobs: $(echo "$jobs" | tr '\n' ', ' | sed 's/,$//')"
            if [ -z "$CI_JOBS" ]; then
                CI_JOBS="$jobs"
            else
                CI_JOBS="$(printf "%s\n%s" "$CI_JOBS" "$jobs")"
            fi
        fi
    done
elif [ -f "$PROJECT_DIR/.gitlab-ci.yml" ]; then
    detected "GitLab CI found"
elif [ -f "$PROJECT_DIR/.circleci/config.yml" ]; then
    detected "CircleCI found"
elif [ -f "$PROJECT_DIR/Jenkinsfile" ]; then
    detected "Jenkinsfile found"
else
    not_detected "No CI configuration found"
fi

# ─── Detection: Test Framework ───────────────────────────────────────────────

section "Test Framework"

TEST_FRAMEWORK=""
TEST_CMD=""

has_script() {
    echo "$PKG_SCRIPTS" | grep -q "^${1}$" 2>/dev/null
}

if [ -f "$PROJECT_DIR/vitest.config.ts" ] || [ -f "$PROJECT_DIR/vitest.config.js" ] || [ -f "$PROJECT_DIR/vitest.config.mts" ]; then
    TEST_FRAMEWORK="vitest"
    TEST_CMD="${PKG_MANAGER} test"
    detected "Vitest"
elif has_script "test"; then
    # Check if jest or vitest in devDependencies
    if [ -f "$PROJECT_DIR/jest.config.js" ] || [ -f "$PROJECT_DIR/jest.config.ts" ]; then
        TEST_FRAMEWORK="jest"
    else
        TEST_FRAMEWORK="test-script"
    fi
    TEST_CMD="${PKG_MANAGER} test"
    detected "$TEST_FRAMEWORK (via $PKG_MANAGER test)"
elif [ "$PKG_MANAGER" = "cargo" ]; then
    TEST_FRAMEWORK="cargo-test"
    TEST_CMD="cargo test"
    detected "cargo test"
elif [ -f "$PROJECT_DIR/pytest.ini" ] || [ -f "$PROJECT_DIR/setup.cfg" ] || [ -f "$PROJECT_DIR/pyproject.toml" ]; then
    if [ "$PKG_MANAGER" = "poetry" ] || [ "$PKG_MANAGER" = "pip" ]; then
        # Check for pytest in pyproject.toml
        if [ -f "$PROJECT_DIR/pyproject.toml" ] && grep -q "pytest" "$PROJECT_DIR/pyproject.toml" 2>/dev/null; then
            TEST_FRAMEWORK="pytest"
            TEST_CMD="pytest"
            detected "pytest"
        fi
    fi
elif [ "$PKG_MANAGER" = "go" ]; then
    TEST_FRAMEWORK="go-test"
    TEST_CMD="go test ./..."
    detected "go test"
fi

if [ -z "$TEST_FRAMEWORK" ]; then
    not_detected "No test framework auto-detected"
    TEST_CMD=""
fi

# ─── Detection: Linting ──────────────────────────────────────────────────────

section "Linting & Formatting"

LINT_CMD=""
LINT_TOOLS=""

# Node.js linting
if [ -f "$PROJECT_DIR/.eslintrc.js" ] || [ -f "$PROJECT_DIR/.eslintrc.json" ] || [ -f "$PROJECT_DIR/.eslintrc.yml" ] || [ -f "$PROJECT_DIR/eslint.config.js" ] || [ -f "$PROJECT_DIR/eslint.config.mjs" ]; then
    LINT_TOOLS="${LINT_TOOLS}eslint "
    detected "ESLint"
fi

if [ -f "$PROJECT_DIR/.prettierrc" ] || [ -f "$PROJECT_DIR/.prettierrc.js" ] || [ -f "$PROJECT_DIR/.prettierrc.json" ] || [ -f "$PROJECT_DIR/prettier.config.js" ]; then
    LINT_TOOLS="${LINT_TOOLS}prettier "
    detected "Prettier"
fi

if has_script "lint"; then
    LINT_CMD="${PKG_MANAGER} lint"
    detected "Lint script: $LINT_CMD"
elif [ "$PKG_MANAGER" = "cargo" ]; then
    LINT_CMD="cargo clippy -- -D warnings"
    LINT_TOOLS="${LINT_TOOLS}clippy "
    detected "cargo clippy"
elif [ -f "$PROJECT_DIR/ruff.toml" ] || [ -f "$PROJECT_DIR/.ruff.toml" ] || ([ -f "$PROJECT_DIR/pyproject.toml" ] && grep -q "ruff" "$PROJECT_DIR/pyproject.toml" 2>/dev/null); then
    LINT_CMD="ruff check ."
    LINT_TOOLS="${LINT_TOOLS}ruff "
    detected "ruff"
fi

if [ -z "$LINT_CMD" ] && [ -z "$LINT_TOOLS" ]; then
    not_detected "No linting tools detected"
fi

# ─── Detection: Type Checking ────────────────────────────────────────────────

section "Type Checking"

TYPECHECK_CMD=""

if has_script "type-check" || has_script "typecheck"; then
    if has_script "type-check"; then
        TYPECHECK_CMD="${PKG_MANAGER} type-check"
    else
        TYPECHECK_CMD="${PKG_MANAGER} typecheck"
    fi
    detected "Type-check script: $TYPECHECK_CMD"
elif [ -f "$PROJECT_DIR/tsconfig.json" ]; then
    TYPECHECK_CMD="${PKG_MANAGER} exec tsc --noEmit"
    detected "TypeScript (tsconfig.json found) — $TYPECHECK_CMD"
elif [ -f "$PROJECT_DIR/mypy.ini" ] || ([ -f "$PROJECT_DIR/pyproject.toml" ] && grep -q "mypy" "$PROJECT_DIR/pyproject.toml" 2>/dev/null); then
    TYPECHECK_CMD="mypy ."
    detected "mypy"
fi

if [ -z "$TYPECHECK_CMD" ]; then
    not_detected "No type checking detected"
fi

# ─── Detection: Build Command ────────────────────────────────────────────────

section "Build"

BUILD_CMD=""

if has_script "build"; then
    BUILD_CMD="${PKG_MANAGER} build"
    detected "Build script: $BUILD_CMD"
elif [ "$PKG_MANAGER" = "cargo" ]; then
    BUILD_CMD="cargo build"
    detected "cargo build"
elif [ "$PKG_MANAGER" = "go" ]; then
    BUILD_CMD="go build ./..."
    detected "go build"
elif [ "$PKG_MANAGER" = "make" ]; then
    BUILD_CMD="make"
    detected "make"
fi

if [ -z "$BUILD_CMD" ]; then
    not_detected "No build command detected"
fi

# ─── Detection: Migration / Database ─────────────────────────────────────────

section "Database / Migrations"

MIGRATION_CMD=""

if has_script "migration-dry-run" || has_script "db:migrate:dry-run"; then
    if has_script "migration-dry-run"; then
        MIGRATION_CMD="${PKG_MANAGER} migration-dry-run"
    else
        MIGRATION_CMD="${PKG_MANAGER} db:migrate:dry-run"
    fi
    detected "Migration dry-run: $MIGRATION_CMD"
elif has_script "db:migrate"; then
    detected "Database migration script found (no dry-run detected)"
fi

# Check for common ORM/migration dirs
if [ -d "$PROJECT_DIR/prisma" ]; then
    detected "Prisma detected"
    if [ -z "$MIGRATION_CMD" ]; then
        MIGRATION_CMD="${PKG_MANAGER} exec prisma migrate status"
    fi
elif [ -d "$PROJECT_DIR/migrations" ] || [ -d "$PROJECT_DIR/db/migrate" ]; then
    detected "Migrations directory found"
fi

if [ -z "$MIGRATION_CMD" ]; then
    not_detected "No migration dry-run detected"
fi

# ─── Detection: Documentation ────────────────────────────────────────────────

section "Documentation"

CLAUDE_MD=""

if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
    CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"
    detected "CLAUDE.md found"

    # Extract quality workflow if present
    if command -v python3 >/dev/null 2>&1; then
        QUALITY_WORKFLOW="$(python3 -c "
import re
text = open('$CLAUDE_MD').read()
# Look for chained commands (lint && type-check && test && build patterns)
matches = re.findall(r'[\w-]+\s+(?:lint|type-check|typecheck|test|build)(?:\s*&&\s*[\w-]+\s+(?:lint|type-check|typecheck|test|build))+', text)
for m in matches:
    print(m)
    break
" 2>/dev/null)" || QUALITY_WORKFLOW=""
        if [ -n "$QUALITY_WORKFLOW" ]; then
            detected "Quality workflow: $QUALITY_WORKFLOW"
        fi
    fi
elif [ -f "$PROJECT_DIR/AGENTS.md" ]; then
    detected "AGENTS.md found"
elif [ -f "$PROJECT_DIR/CONTRIBUTING.md" ]; then
    detected "CONTRIBUTING.md found"
else
    not_detected "No CLAUDE.md or similar docs found"
fi

# ─── Detection: Git History & Failure Patterns ───────────────────────────────

section "Git History & Failure Patterns"

FAILURE_COMMITS=""
GIT_AVAILABLE=""

if [ -d "$PROJECT_DIR/.git" ]; then
    GIT_AVAILABLE="yes"
    detected "Git repository found"

    # Last 20 commits
    RECENT_COMMITS="$(cd "$PROJECT_DIR" && git log --oneline -20 2>/dev/null)" || RECENT_COMMITS=""
    if [ -n "$RECENT_COMMITS" ]; then
        COMMIT_COUNT="$(echo "$RECENT_COMMITS" | wc -l | tr -d ' ')"
        detected "Last $COMMIT_COUNT commits analyzed"
    fi

    # Look for fix/bug/revert patterns in recent history (up to 200 commits)
    FAILURE_COMMITS="$(cd "$PROJECT_DIR" && git log --oneline -200 --grep='fix' --grep='bug' --grep='revert' --grep='hotfix' --grep='broken' --grep='crash' --grep='regression' --all-match=false 2>/dev/null | head -30)" || FAILURE_COMMITS=""

    if [ -n "$FAILURE_COMMITS" ]; then
        FAILURE_COUNT="$(echo "$FAILURE_COMMITS" | wc -l | tr -d ' ')"
        detected "$FAILURE_COUNT fix/bug/revert commits found — will seed failure modes"
    else
        not_detected "No fix/bug/revert commits found in recent history"
    fi
else
    not_detected "Not a git repository"
fi

# ─── Build suggested pipeline ────────────────────────────────────────────────

section "Building Suggested Pipeline"

# Pipeline name defaults to project directory basename
SUGGESTED_NAME="$(echo "$PROJECT_BASENAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')-qa"
SUGGESTED_DOMAIN="software-qa"

# Build stages dynamically based on what was detected
# We always have: Specification, Verification & Release
# Middle stages depend on what tools were found

STAGE_COUNT=0

# Arrays stored as newline-delimited strings
STAGE_NAMES=""
STAGE_GATES=""
STAGE_CHECKLISTS=""  # Checklists separated by ||, items within separated by ;;
STAGE_CMDS=""

add_stage() {
    _name="$1"
    _gate="$2"
    _checklist="$3"
    _cmd="$4"
    [ -z "$_cmd" ] && _cmd="__NONE__"
    STAGE_COUNT=$((STAGE_COUNT + 1))
    STAGE_NAMES="$(printf "%s\n%s" "$STAGE_NAMES" "$_name")"
    STAGE_GATES="$(printf "%s\n%s" "$STAGE_GATES" "$_gate")"
    STAGE_CHECKLISTS="$(printf "%s\n%s" "$STAGE_CHECKLISTS" "$_checklist")"
    STAGE_CMDS="$(printf "%s\n%s" "$STAGE_CMDS" "$_cmd")"
}

get_field() {
    echo "$1" | sed -n "$((${2} + 1))p"
}

# Stage 1: Specification (always present)
add_stage "Specification" "human" \
    "Requirements documented with acceptance criteria;;Edge cases identified;;Scope bounded — no unbounded changes" \
    ""

# Stage 2: Lint & Types (if lint or typecheck detected)
if [ -n "$LINT_CMD" ] || [ -n "$TYPECHECK_CMD" ]; then
    _lint_checklist=""
    _lint_cmd=""

    if [ -n "$LINT_CMD" ]; then
        _lint_checklist="Linting passes: $LINT_CMD"
        _lint_cmd="$LINT_CMD"
    fi
    if [ -n "$TYPECHECK_CMD" ]; then
        if [ -n "$_lint_checklist" ]; then
            _lint_checklist="${_lint_checklist};;Type checking passes: $TYPECHECK_CMD"
            _lint_cmd="${_lint_cmd} && ${TYPECHECK_CMD}"
        else
            _lint_checklist="Type checking passes: $TYPECHECK_CMD"
            _lint_cmd="$TYPECHECK_CMD"
        fi
    fi
    _lint_checklist="${_lint_checklist};;No new warnings introduced"

    add_stage "Lint & Types" "auto" "$_lint_checklist" "$_lint_cmd"
fi

# Stage 3: Testing (if test framework detected)
if [ -n "$TEST_CMD" ]; then
    _test_checklist="All tests pass: ${TEST_CMD};;No skipped tests without justification;;Edge cases from specification have test coverage"
    add_stage "Testing" "auto" "$_test_checklist" "$TEST_CMD"
fi

# Stage 4: Build & Integration (if build command detected)
if [ -n "$BUILD_CMD" ]; then
    _build_checklist="Build succeeds: ${BUILD_CMD}"
    _build_cmd="$BUILD_CMD"
    if [ -n "$MIGRATION_CMD" ]; then
        _build_checklist="${_build_checklist};;Migration dry-run passes: ${MIGRATION_CMD}"
        _build_cmd="${_build_cmd} && ${MIGRATION_CMD}"
    fi
    _build_checklist="${_build_checklist};;No new build warnings"
    add_stage "Build & Integration" "auto" "$_build_checklist" "$_build_cmd"
fi

# If we only have Specification so far (nothing detected), add generic stages
if [ "$STAGE_COUNT" -eq 1 ]; then
    add_stage "Implementation" "auto" \
        "Code compiles without errors;;No linting warnings;;Changes are minimal and focused" \
        ""
    add_stage "Testing" "auto" \
        "All tests pass;;Edge cases covered;;No regressions" \
        ""
    add_stage "Build" "auto" \
        "Build succeeds;;No new warnings" \
        ""
fi

# Final stage: Verification & Release (always present)
add_stage "Verification & Release" "human" \
    "All automated gates passed;;Changes reviewed for correctness;;No unintended side effects;;Documentation updated if needed" \
    ""

# ─── Display summary and ask for confirmation ────────────────────────────────

section "Suggested Pipeline"

printf "\n  Pipeline name: \033[1m%s\033[0m\n" "$SUGGESTED_NAME"
printf "  Domain: \033[1m%s\033[0m\n" "$SUGGESTED_DOMAIN"
printf "  Stages: \033[1m%d\033[0m\n" "$STAGE_COUNT"

printf "\n--- Confirm Pipeline Configuration ---\n"

if [ "$AUTO_ACCEPT" = "true" ]; then
    PIPELINE_NAME="$SUGGESTED_NAME"
    DOMAIN="$SUGGESTED_DOMAIN"
else
    # Ask about pipeline name
    printf "\nPipeline name [%s]: " "$SUGGESTED_NAME"
    read REPLY </dev/tty
    PIPELINE_NAME="${REPLY:-$SUGGESTED_NAME}"

    printf "Domain [%s]: " "$SUGGESTED_DOMAIN"
    read REPLY </dev/tty
    DOMAIN="${REPLY:-$SUGGESTED_DOMAIN}"
fi

# Iterate through stages and ask for confirmation
# We'll build the final accepted stages in new variables
FINAL_COUNT=0
FINAL_NAMES=""
FINAL_GATES=""
FINAL_CHECKLISTS=""
FINAL_CMDS=""

add_final_stage() {
    FINAL_COUNT=$((FINAL_COUNT + 1))
    # Use ||| as delimiter for cmds to avoid empty-line issues
    _val="$4"
    [ -z "$_val" ] && _val="__NONE__"
    FINAL_NAMES="$(printf "%s\n%s" "$FINAL_NAMES" "$1")"
    FINAL_GATES="$(printf "%s\n%s" "$FINAL_GATES" "$2")"
    FINAL_CHECKLISTS="$(printf "%s\n%s" "$FINAL_CHECKLISTS" "$3")"
    FINAL_CMDS="$(printf "%s\n%s" "$FINAL_CMDS" "$_val")"
}

i=1
while [ "$i" -le "$STAGE_COUNT" ]; do
    _name="$(get_field "$STAGE_NAMES" "$i")"
    _gate="$(get_field "$STAGE_GATES" "$i")"
    _checklist="$(get_field "$STAGE_CHECKLISTS" "$i")"
    _cmd="$(get_field "$STAGE_CMDS" "$i")"
    [ "$_cmd" = "__NONE__" ] && _cmd=""

    printf "\n\033[1;36m--- Stage %d: %s ---\033[0m\n" "$i" "$_name"
    printf "  Gate: %s\n" "$_gate"
    printf "  Checklist:\n"
    echo "$_checklist" | tr ';;' '\n' | while IFS= read -r item; do
        [ -z "$item" ] && continue
        printf "    - %s\n" "$item"
    done
    if [ -n "$_cmd" ]; then
        printf "  Command: %s\n" "$_cmd"
    fi

    prompt_yne "Accept this stage?"

    case "$REPLY" in
        y|Y|yes|YES)
            add_final_stage "$_name" "$_gate" "$_checklist" "$_cmd"
            ;;
        n|N|no|NO)
            printf "  Skipped.\n"
            ;;
        edit|e|E)
            prompt_text "Stage name [$_name]"
            _name="${REPLY:-$_name}"

            prompt_text "Gate type (human/auto) [$_gate]"
            _gate="${REPLY:-$_gate}"

            printf "  Enter checklist items (one per line, empty line to finish):\n"
            _new_checklist=""
            while true; do
                printf "    - "
                read _item </dev/tty
                [ -z "$_item" ] && break
                if [ -z "$_new_checklist" ]; then
                    _new_checklist="$_item"
                else
                    _new_checklist="${_new_checklist};;${_item}"
                fi
            done
            if [ -n "$_new_checklist" ]; then
                _checklist="$_new_checklist"
            fi

            prompt_text "Command [$_cmd]"
            _cmd="${REPLY:-$_cmd}"

            add_final_stage "$_name" "$_gate" "$_checklist" "$_cmd"
            printf "  Updated.\n"
            ;;
        *)
            # Default to accept
            add_final_stage "$_name" "$_gate" "$_checklist" "$_cmd"
            ;;
    esac

    i=$((i + 1))
done

# ─── Validate we have at least 2 stages ──────────────────────────────────────

if [ "$FINAL_COUNT" -lt 2 ]; then
    die "Need at least 2 stages in the pipeline."
fi

# ─── Output the pipeline config ──────────────────────────────────────────────

section "Generating Pipeline Configuration"

CONFIG_FILE="$(mktemp)"

{
    printf 'PIPELINE_NAME="%s"\n' "$PIPELINE_NAME"
    printf 'DOMAIN="%s"\n' "$DOMAIN"
    printf 'NUM_STAGES=%d\n' "$FINAL_COUNT"

    j=1
    while [ "$j" -le "$FINAL_COUNT" ]; do
        _name="$(get_field "$FINAL_NAMES" "$j")"
        _gate="$(get_field "$FINAL_GATES" "$j")"
        _checklist="$(get_field "$FINAL_CHECKLISTS" "$j")"
        _cmd="$(get_field "$FINAL_CMDS" "$j")"
        [ "$_cmd" = "__NONE__" ] && _cmd=""

        printf 'STAGE_%d_NAME="%s"\n' "$j" "$_name"
        printf 'STAGE_%d_GATE="%s"\n' "$j" "$_gate"

        # Split checklist by ;; and output numbered items
        _ci=1
        _old_ifs="$IFS"
        IFS=";"
        for _token in $_checklist; do
            # Skip empty tokens (from ;; splitting into ; ; sequences)
            case "$_token" in
                ""|" ") continue ;;
            esac
            printf 'STAGE_%d_CHECKLIST_%d="%s"\n' "$j" "$_ci" "$_token"
            _ci=$((_ci + 1))
        done
        IFS="$_old_ifs"

        printf 'STAGE_%d_CMD="%s"\n' "$j" "$_cmd"

        j=$((j + 1))
    done
} > "$CONFIG_FILE"

printf "\nGenerated configuration:\n\n"
cat "$CONFIG_FILE"
printf "\n"

# ─── Call scaffold.sh ─────────────────────────────────────────────────────────

section "Scaffolding Pipeline"

if [ "$CONFIG_ONLY" = "true" ]; then
    SAVED_CONFIG="/tmp/harness-scan.conf"
    cp "$CONFIG_FILE" "$SAVED_CONFIG"
    printf "Configuration saved to: %s\n" "$SAVED_CONFIG"
    printf "\nTo generate the pipeline:\n"
    printf "  %s/scaffold.sh --from-scan %s\n" "$SCRIPT_DIR" "$SAVED_CONFIG"
elif [ ! -f "$SCRIPT_DIR/scaffold.sh" ]; then
    printf "Warning: scaffold.sh not found at %s\n" "$SCRIPT_DIR/scaffold.sh"
    printf "Configuration saved to: %s\n" "$CONFIG_FILE"
    printf "You can feed it to scaffold.sh manually.\n"
else
    printf "Calling scaffold.sh to generate the pipeline...\n\n"

    # Use --from-scan mode with the config file, plus pipe stage names for interactive defaults
    {
        printf "\n"  # accept default pipeline name
        printf "\n"  # accept default domain
        printf "\n"  # accept default stage count

        j=1
        while [ "$j" -le "$FINAL_COUNT" ]; do
            printf "\n"  # accept default stage name
            j=$((j + 1))
        done
    } | sh "$SCRIPT_DIR/scaffold.sh" --from-scan "$CONFIG_FILE"

    PIPELINE_DIR="$SCRIPT_DIR/$PIPELINE_NAME"

    # ─── Post-scaffold: Enrich pipeline.md with detected checklist items ──────

    if [ -d "$PIPELINE_DIR" ] && [ -f "$PIPELINE_DIR/pipeline.md" ]; then
        section "Enriching Pipeline"

        # Replace placeholder checklist items with detected ones
        if command -v python3 >/dev/null 2>&1; then
            python3 -c "
import sys

config_file = '$CONFIG_FILE'
pipeline_file = '$PIPELINE_DIR/pipeline.md'
final_count = $FINAL_COUNT

# Parse config
config = {}
with open(config_file) as f:
    for line in f:
        line = line.strip()
        if '=' in line:
            key, val = line.split('=', 1)
            config[key] = val.strip('\"')

# Read pipeline.md
with open(pipeline_file) as f:
    content = f.read()

# For each stage, replace placeholder checklist with detected items
for j in range(1, final_count + 1):
    stage_name = config.get(f'STAGE_{j}_NAME', '')
    gate = config.get(f'STAGE_{j}_GATE', '')
    cmd = config.get(f'STAGE_{j}_CMD', '')

    # Build checklist items
    items = []
    ci = 1
    while f'STAGE_{j}_CHECKLIST_{ci}' in config:
        items.append(config[f'STAGE_{j}_CHECKLIST_{ci}'])
        ci += 1

    if items:
        # Find the placeholder checklist block for this stage
        old_checklist = '- [ ] <!-- Item 1 -->\n- [ ] <!-- Item 2 -->\n- [ ] <!-- Item 3 -->'
        new_checklist = '\n'.join(f'- [ ] {item}' for item in items)

        # Replace only the first occurrence (stage by stage)
        content = content.replace(old_checklist, new_checklist, 1)

    # Update gate type
    if gate:
        old_gate_line = f'### Stage {j}: {stage_name}\n\n**Purpose:** <!-- Define the purpose of this stage -->\n**Gate type:** '
        # The gate is already set by scaffold.sh defaults, but we want ours
        pass

    # Add command if we have one
    if cmd:
        marker = f'#### Known Failure Modes'
        insert = f'#### Automated Command\n\`\`\`sh\n{cmd}\n\`\`\`\n\n#### Known Failure Modes'
        # Only add once per occurrence
        content = content.replace(marker, insert, 1)

with open(pipeline_file, 'w') as f:
    f.write(content)

print('  Pipeline enriched with detected checklist items and commands.')
" 2>/dev/null || printf "  Warning: Could not enrich pipeline.md (python3 error)\n"
        else
            printf "  Skipping enrichment (python3 not available)\n"
        fi

        # ─── Post-scaffold: Seed memory.md with failure patterns from git ─────

        if [ -n "$FAILURE_COMMITS" ] && [ -f "$PIPELINE_DIR/memory.md" ]; then
            section "Seeding Failure Modes from Git History"

            TODAY="$(date +%Y-%m-%d)"

            # Parse failure commits and add them as open failure modes
            if command -v python3 >/dev/null 2>&1; then
                python3 -c "
import re

commits_text = '''$FAILURE_COMMITS'''
memory_file = '$PIPELINE_DIR/memory.md'
today = '$TODAY'

with open(memory_file) as f:
    content = f.read()

# Parse commits for failure patterns
entries = []
for line in commits_text.strip().split('\n'):
    if not line.strip():
        continue
    # Extract commit message (skip hash)
    parts = line.split(' ', 1)
    if len(parts) < 2:
        continue
    msg = parts[1].strip()

    # Categorize
    if re.search(r'\brevert\b', msg, re.I):
        mode = 'Reverted change: ' + msg
    elif re.search(r'\bhotfix\b', msg, re.I):
        mode = 'Hotfix required: ' + msg
    elif re.search(r'\bbug\b', msg, re.I):
        mode = 'Bug: ' + msg
    elif re.search(r'\bfix\b', msg, re.I):
        mode = 'Fix: ' + msg
    elif re.search(r'\bcrash\b', msg, re.I):
        mode = 'Crash: ' + msg
    elif re.search(r'\bregression\b', msg, re.I):
        mode = 'Regression: ' + msg
    elif re.search(r'\bbroken\b', msg, re.I):
        mode = 'Broken: ' + msg
    else:
        mode = msg
    entries.append(mode)

# Deduplicate similar entries (keep first 15)
seen = set()
unique = []
for e in entries:
    key = e.lower()[:40]
    if key not in seen:
        seen.add(key)
        unique.append(e)
    if len(unique) >= 15:
        break

# Replace the empty open failure modes table
old_table = '''| Date Identified | Stage | Failure Mode | Why No Fix Yet | Owner |
|----------------|-------|--------------|----------------|-------|
| | | | | |'''

new_rows = []
for e in unique:
    # Escape pipes in commit messages
    safe = e.replace('|', '/')
    new_rows.append(f'| {today} | TBD | {safe} | Detected from git history — needs triage | — |')

new_table = '''| Date Identified | Stage | Failure Mode | Why No Fix Yet | Owner |
|----------------|-------|--------------|----------------|-------|
''' + '\n'.join(new_rows)

content = content.replace(old_table, new_table)

with open(memory_file, 'w') as f:
    f.write(content)

print(f'  Seeded {len(unique)} failure mode(s) from git history into memory.md')
" 2>/dev/null || printf "  Warning: Could not seed memory.md (python3 error)\n"
            else
                printf "  Skipping failure seeding (python3 not available)\n"
            fi
        fi

        # ─── Post-scaffold: Commit the enrichments ───────────────────────────

        if [ -d "$PIPELINE_DIR/.git" ]; then
            cd "$PIPELINE_DIR"
            git add -A 2>/dev/null
            git diff --cached --quiet 2>/dev/null || \
                git commit -q -m "Enrich pipeline with detected project configuration

Detected: pkg=$PKG_MANAGER test=$TEST_FRAMEWORK lint=${LINT_TOOLS:-none}
Source: $PROJECT_DIR
Generated by scan-project.sh" 2>/dev/null
            cd "$SCRIPT_DIR"
        fi
    fi

    # ─── Final summary ───────────────────────────────────────────────────────

    section "Done"

    printf "\nPipeline created: %s/\n" "$PIPELINE_DIR"
    printf "Configuration:    %s\n\n" "$CONFIG_FILE"
    printf "Files:\n"
    if [ -d "$PIPELINE_DIR" ]; then
        ls -la "$PIPELINE_DIR" 2>/dev/null
    fi
    printf "\n--- Next steps ---\n\n"
    printf "1. Review pipeline.md — checklist items were pre-populated from project scan\n"
    printf "2. Review memory.md — failure modes were seeded from git history\n"
    printf "3. Edit skills/ to add stage-specific agent instructions\n"
    printf "4. Run your first pipeline pass\n"
    printf "5. After each run, complete .improvements/retrospective.md\n\n"
fi

# Clean up temp file if scaffold.sh was called successfully
if [ -d "$PIPELINE_DIR" ] 2>/dev/null; then
    rm -f "$CONFIG_FILE"
fi
