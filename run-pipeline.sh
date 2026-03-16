#!/bin/sh
# run-pipeline.sh — Orchestrate pipeline execution with command execution and interactive human gates
# Usage: ./run-pipeline.sh <pipeline-dir> [project-name]
#
# pipeline-dir: path to a harness project (has pipeline.md, skills/, gate-enforcer.sh)
# project-name: name for this run (defaults to "default")

set -e

# ─── Globals ───────────────────────────────────────────────────────────────────
PIPELINE_DIR=""
PROJECT="default"
WORKDIR=""
START_TIME=""
STAGE_RESULTS=""
TOTAL_STAGES=0
COMPLETED_STAGES=0
FAILURE_ENTRIES=""
ABORTED=0

# ─── Helpers ───────────────────────────────────────────────────────────────────

usage() {
    echo "Usage: $0 [--workdir /path/to/project] <pipeline-dir> [project-name]"
    echo ""
    echo "  pipeline-dir   Path to a harness project (contains pipeline.md, skills/, gate-enforcer.sh)"
    echo "  project-name   Name for this run (used for gate approval files, defaults to \"default\")"
    echo "  --workdir DIR  Directory to run commands in (defaults to pipeline-dir)"
    exit 1
}

now_seconds() {
    date +%s
}

elapsed_display() {
    _elapsed="$1"
    _min=$((_elapsed / 60))
    _sec=$((_elapsed % 60))
    if [ "$_min" -gt 0 ]; then
        printf "%dm %ds" "$_min" "$_sec"
    else
        printf "%ds" "$_sec"
    fi
}

record_stage() {
    # $1 = stage number, $2 = name, $3 = result (PASSED|BLOCKED|SKIPPED|ABORTED)
    if [ -z "$STAGE_RESULTS" ]; then
        STAGE_RESULTS="$1|$2|$3"
    else
        STAGE_RESULTS="$STAGE_RESULTS
$1|$2|$3"
    fi
}

add_failure_entry() {
    # $1 = stage, $2 = description, $3 = suggested root cause
    _date="$(date +%Y-%m-%d)"
    _entry="| $_date | Stage $1 | $2 | $3 |  |  |"
    if [ -z "$FAILURE_ENTRIES" ]; then
        FAILURE_ENTRIES="$_entry"
    else
        FAILURE_ENTRIES="$FAILURE_ENTRIES
$_entry"
    fi
}

# ─── Log parser ────────────────────────────────────────────────────────────────

parse_output() {
    # Parse command output for test results, lint errors, type errors, build status, coverage
    # $1 = log file path, $2 = stage number
    _logfile="$1"
    _stage="$2"
    _summary=""
    _has_failures=0
    _failure_desc=""

    if [ ! -f "$_logfile" ]; then
        return
    fi

    # Test results: look for patterns like "X passed", "Y failed", "Z skipped"
    _tests_passed=""
    _tests_failed=""
    _tests_skipped=""

    # Pattern: "N passed" or "N tests passed"
    _tp="$(grep -oiE '[0-9]+ (tests? )?pass(ed|ing)?' "$_logfile" 2>/dev/null | head -1 | grep -oE '[0-9]+' | head -1)" || true
    if [ -n "$_tp" ]; then
        _tests_passed="$_tp"
    fi

    # Pattern: "N failed" or "N tests failed"
    _tf="$(grep -oiE '[0-9]+ (tests? )?fail(ed|ure|ures|ing)?' "$_logfile" 2>/dev/null | head -1 | grep -oE '[0-9]+' | head -1)" || true
    if [ -n "$_tf" ]; then
        _tests_failed="$_tf"
    fi

    # Pattern: "N skipped"
    _ts="$(grep -oiE '[0-9]+ (tests? )?skip(ped)?' "$_logfile" 2>/dev/null | head -1 | grep -oE '[0-9]+' | head -1)" || true
    if [ -n "$_ts" ]; then
        _tests_skipped="$_ts"
    fi

    # Lint errors
    _lint_errors=""
    _le="$(grep -oiE '[0-9]+ (lint )?(error|problem|issue|warning)s?' "$_logfile" 2>/dev/null | head -1 | grep -oE '[0-9]+' | head -1)" || true
    if [ -n "$_le" ]; then
        _lint_errors="$_le"
    fi

    # Type errors
    _type_errors=""
    _te="$(grep -oiE '[0-9]+ type[ -]?errors?' "$_logfile" 2>/dev/null | head -1 | grep -oE '[0-9]+' | head -1)" || true
    if [ -n "$_te" ]; then
        _type_errors="$_te"
    fi
    # Also check for "Found N errors" from tsc
    if [ -z "$_type_errors" ]; then
        _te="$(grep -oiE 'found [0-9]+ errors?' "$_logfile" 2>/dev/null | head -1 | grep -oE '[0-9]+' | head -1)" || true
        if [ -n "$_te" ]; then
            _type_errors="$_te"
        fi
    fi

    # Build success/failure
    _build_status=""
    if grep -qiE 'build (succeeded|successful|complete|passed)' "$_logfile" 2>/dev/null; then
        _build_status="success"
    elif grep -qiE 'build (failed|failure|error)' "$_logfile" 2>/dev/null; then
        _build_status="failed"
        _has_failures=1
    fi

    # Coverage percentage
    _coverage=""
    _cov="$(grep -oiE '([0-9]+(\.[0-9]+)?)\s*%\s*(coverage|cov|of statements|of branches|of lines)' "$_logfile" 2>/dev/null | head -1 | grep -oE '[0-9]+(\.[0-9]+)?' | head -1)" || true
    if [ -n "$_cov" ]; then
        _coverage="$_cov"
    fi
    # Also check "coverage: N%"
    if [ -z "$_coverage" ]; then
        _cov="$(grep -oiE 'coverage[: ]+([0-9]+(\.[0-9]+)?)%' "$_logfile" 2>/dev/null | head -1 | grep -oE '[0-9]+(\.[0-9]+)?' | head -1)" || true
        if [ -n "$_cov" ]; then
            _coverage="$_cov"
        fi
    fi

    # Build summary string
    _parts=""
    if [ -n "$_tests_passed" ]; then
        _parts="${_tests_passed} tests passed"
    fi
    if [ -n "$_tests_failed" ]; then
        if [ -n "$_parts" ]; then
            _parts="$_parts, ${_tests_failed} failed"
        else
            _parts="${_tests_failed} tests failed"
        fi
        if [ "$_tests_failed" != "0" ]; then
            _has_failures=1
        fi
    fi
    if [ -n "$_tests_skipped" ]; then
        if [ -n "$_parts" ]; then
            _parts="$_parts, ${_tests_skipped} skipped"
        else
            _parts="${_tests_skipped} skipped"
        fi
    fi
    if [ -n "$_lint_errors" ] && [ "$_lint_errors" != "0" ]; then
        if [ -n "$_parts" ]; then
            _parts="$_parts, ${_lint_errors} lint errors"
        else
            _parts="${_lint_errors} lint errors"
        fi
        _has_failures=1
    fi
    if [ -n "$_type_errors" ] && [ "$_type_errors" != "0" ]; then
        if [ -n "$_parts" ]; then
            _parts="$_parts, ${_type_errors} type errors"
        else
            _parts="${_type_errors} type errors"
        fi
        _has_failures=1
    fi
    if [ -n "$_build_status" ]; then
        if [ -n "$_parts" ]; then
            _parts="$_parts, build $_build_status"
        else
            _parts="build $_build_status"
        fi
    fi
    if [ -n "$_coverage" ]; then
        if [ -n "$_parts" ]; then
            _parts="$_parts, ${_coverage}% coverage"
        else
            _parts="${_coverage}% coverage"
        fi
    fi

    if [ -n "$_parts" ]; then
        echo "  Results: $_parts"
    fi

    # Build failure description for memory.md suggestion
    if [ "$_has_failures" -eq 1 ]; then
        _failure_desc=""
        if [ -n "$_tests_failed" ] && [ "$_tests_failed" != "0" ]; then
            _failure_desc="${_tests_failed} test failure(s)"
        fi
        if [ -n "$_lint_errors" ] && [ "$_lint_errors" != "0" ]; then
            if [ -n "$_failure_desc" ]; then
                _failure_desc="$_failure_desc, ${_lint_errors} lint error(s)"
            else
                _failure_desc="${_lint_errors} lint error(s)"
            fi
        fi
        if [ -n "$_type_errors" ] && [ "$_type_errors" != "0" ]; then
            if [ -n "$_failure_desc" ]; then
                _failure_desc="$_failure_desc, ${_type_errors} type error(s)"
            else
                _failure_desc="${_type_errors} type error(s)"
            fi
        fi
        if [ "$_build_status" = "failed" ]; then
            if [ -n "$_failure_desc" ]; then
                _failure_desc="$_failure_desc, build failure"
            else
                _failure_desc="Build failure"
            fi
        fi
        if [ -n "$_failure_desc" ]; then
            add_failure_entry "$_stage" "$_failure_desc" "Review stage $_stage output log for details"
            echo ""
            echo "  [!] Failure detected. Suggested memory.md entry:"
            echo "      Stage $_stage: $_failure_desc"
        fi
    fi
}

# ─── Print run summary ────────────────────────────────────────────────────────

print_summary() {
    _end_time="$(now_seconds)"
    _elapsed=$((_end_time - START_TIME))

    echo ""
    echo "============================================"
    echo "           PIPELINE RUN SUMMARY"
    echo "============================================"
    echo ""

    if [ -n "$STAGE_RESULTS" ]; then
        echo "$STAGE_RESULTS" | while IFS='|' read -r _snum _sname _sresult; do
            case "$_sresult" in
                PASSED)  _marker="[OK]" ;;
                BLOCKED) _marker="[XX]" ;;
                SKIPPED) _marker="[--]" ;;
                ABORTED) _marker="[!!]" ;;
                *)       _marker="[??]" ;;
            esac
            echo "  $_marker Stage $_snum: $_sname — $_sresult"
        done
    fi

    echo ""
    echo "  Total time: $(elapsed_display "$_elapsed")"
    echo ""

    if [ -n "$FAILURE_ENTRIES" ]; then
        echo "--- Suggested failure entries for memory.md ---"
        echo ""
        echo "| Date | Stage | Failure | Root Cause | Fix Applied | File Changed |"
        echo "|------|-------|---------|------------|-------------|--------------|"
        echo "$FAILURE_ENTRIES"
        echo ""

        # Prompt to log failures
        _memory_file="$PIPELINE_DIR/memory.md"
        if [ -f "$_memory_file" ]; then
            printf "Log these failures to memory.md? [y/n] "
            read -r _answer </dev/tty 2>/dev/null || _answer="n"
            case "$_answer" in
                y|Y|yes|YES)
                    echo "" >> "$_memory_file"
                    echo "$FAILURE_ENTRIES" >> "$_memory_file"
                    echo "Failure entries appended to memory.md"
                    ;;
                *)
                    echo "Skipped logging to memory.md"
                    ;;
            esac
        else
            echo "(No memory.md found at $PIPELINE_DIR/memory.md — skipping log prompt)"
        fi
    else
        echo "  No failures detected."
    fi

    echo ""
    echo "============================================"
}

# ─── Signal handler ────────────────────────────────────────────────────────────

cleanup() {
    echo ""
    echo ""
    echo "--- Pipeline interrupted (Ctrl+C) ---"
    ABORTED=1
    # Mark remaining stages as SKIPPED
    _current_done=0
    if [ -n "$STAGE_RESULTS" ]; then
        _current_done="$(echo "$STAGE_RESULTS" | wc -l | tr -d ' ')"
    fi
    _next=$((_current_done + 1))
    while [ "$_next" -le "$TOTAL_STAGES" ]; do
        _skip_name="$(get_stage_name "$_next")"
        record_stage "$_next" "$_skip_name" "SKIPPED"
        _next=$((_next + 1))
    done
    print_summary
    exit 130
}

trap cleanup INT TERM

# ─── Pipeline parser ──────────────────────────────────────────────────────────

get_stage_count() {
    grep -c '^### Stage [0-9]' "$PIPELINE_DIR/pipeline.md" 2>/dev/null || echo "0"
}

get_stage_name() {
    _sn="$1"
    _line="$(grep "^### Stage ${_sn}:" "$PIPELINE_DIR/pipeline.md" 2>/dev/null | head -1)"
    if [ -n "$_line" ]; then
        echo "$_line" | sed 's/^### Stage [0-9]*: //'
    else
        echo "Unknown"
    fi
}

get_stage_gate_type() {
    _sg="$1"
    _section="$(sed -n "/^### Stage ${_sg}:/,/^### Stage/p" "$PIPELINE_DIR/pipeline.md" 2>/dev/null | head -20)"
    if echo "$_section" | grep -qi 'gate type.*human'; then
        echo "human"
    else
        echo "auto"
    fi
}

get_stage_skill_file() {
    _ss="$1"
    # Look for skill file reference in pipeline.md
    _section="$(sed -n "/^### Stage ${_ss}:/,/^### Stage/p" "$PIPELINE_DIR/pipeline.md" 2>/dev/null | head -20)"
    _skill_ref="$(echo "$_section" | grep -i 'skill file' | head -1 | sed 's/.*`\([^`]*\)`.*/\1/')"
    if [ -n "$_skill_ref" ] && [ -f "$PIPELINE_DIR/$_skill_ref" ]; then
        echo "$PIPELINE_DIR/$_skill_ref"
        return
    fi
    # Fallback: look for stage-N-*.md in skills/
    for _f in "$PIPELINE_DIR/skills/stage-${_ss}-"*.md; do
        if [ -f "$_f" ]; then
            echo "$_f"
            return
        fi
    done
    echo ""
}

extract_command() {
    # Extract command from skill file
    # Look for **Command:** `...` pattern
    _skill="$1"
    _cmd=""

    # Try **Command:** `...`
    _cmd="$(grep -i '\*\*Command:\*\*' "$_skill" 2>/dev/null | head -1 | sed 's/.*`\([^`]*\)`.*/\1/')" || true
    if [ -n "$_cmd" ] && [ "$_cmd" != "$(grep -i '\*\*Command:\*\*' "$_skill" 2>/dev/null | head -1)" ]; then
        echo "$_cmd"
        return
    fi

    # Try ## Commands section — grab the first code block or backtick command
    _in_commands=0
    while IFS= read -r _line; do
        case "$_line" in
            "## Commands"*|"## Command"*)
                _in_commands=1
                continue
                ;;
            "## "*)
                if [ "$_in_commands" -eq 1 ]; then
                    break
                fi
                ;;
        esac
        if [ "$_in_commands" -eq 1 ]; then
            # Look for `command` on a line
            _extracted="$(echo "$_line" | sed -n 's/.*`\([^`]*\)`.*/\1/p')" || true
            if [ -n "$_extracted" ]; then
                echo "$_extracted"
                return
            fi
            # Look for lines starting with $ (shell prompt)
            _extracted="$(echo "$_line" | sed -n 's/^\$ *//p')" || true
            if [ -n "$_extracted" ]; then
                echo "$_extracted"
                return
            fi
        fi
    done < "$_skill"

    echo ""
}

# ─── Human gate prompt ────────────────────────────────────────────────────────

prompt_human_gate() {
    _phg_stage="$1"
    _phg_reason="$2"
    _phg_logfile="$3"

    while true; do
        printf "  Review stage %s output. Approve? [y/n/view] " "$_phg_stage"
        read -r _answer </dev/tty 2>/dev/null || _answer="n"
        case "$_answer" in
            y|Y|yes|YES)
                # Create approval file
                _approval_dir="$PIPELINE_DIR/research/${PROJECT}"
                mkdir -p "$_approval_dir"
                echo "Approved by pipeline runner on $(date +%Y-%m-%d\ %H:%M:%S)" > "$_approval_dir/.gate-${_phg_stage}-approved"
                echo "  Approval file created."
                return 0
                ;;
            n|N|no|NO)
                echo "  Pipeline aborted by user."
                return 1
                ;;
            view|VIEW|v|V)
                echo ""
                if [ -n "$_phg_logfile" ] && [ -f "$_phg_logfile" ]; then
                    echo "--- Begin stage $_phg_stage output ---"
                    cat "$_phg_logfile"
                    echo "--- End stage $_phg_stage output ---"
                else
                    echo "  (No output log available for this stage)"
                fi
                echo ""
                ;;
            *)
                echo "  Please enter y, n, or view."
                ;;
        esac
    done
}

# ─── Main ─────────────────────────────────────────────────────────────────────

# Parse arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        --workdir)
            WORKDIR="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            if [ -z "$PIPELINE_DIR" ]; then
                PIPELINE_DIR="$1"
            else
                PROJECT="$1"
            fi
            shift
            ;;
    esac
done

if [ -z "$PIPELINE_DIR" ]; then
    usage
fi

PIPELINE_DIR="$(cd "$PIPELINE_DIR" && pwd)"
if [ -n "$WORKDIR" ]; then
    WORKDIR="$(cd "$WORKDIR" && pwd)"
else
    WORKDIR="$PIPELINE_DIR"
fi

if [ ! -f "$PIPELINE_DIR/pipeline.md" ]; then
    echo "ERROR: pipeline.md not found in $PIPELINE_DIR"
    echo "Expected: $PIPELINE_DIR/pipeline.md"
    exit 1
fi

if [ ! -f "$PIPELINE_DIR/gate-enforcer.sh" ]; then
    echo "WARNING: gate-enforcer.sh not found in $PIPELINE_DIR"
    echo "Gate checks will be skipped."
fi

TOTAL_STAGES="$(get_stage_count)"
if [ "$TOTAL_STAGES" -eq 0 ]; then
    echo "ERROR: No stages found in pipeline.md"
    exit 1
fi

# Create research output directory
RESEARCH_DIR="$PIPELINE_DIR/research/${PROJECT}"
mkdir -p "$RESEARCH_DIR"

START_TIME="$(now_seconds)"

echo ""
echo "============================================"
echo "  Pipeline Runner"
echo "  Project: $PROJECT"
echo "  Dir:     $PIPELINE_DIR"
echo "  Stages:  $TOTAL_STAGES"
echo "============================================"
echo ""

# ─── Stage loop ────────────────────────────────────────────────────────────────

CURRENT_STAGE=1
while [ "$CURRENT_STAGE" -le "$TOTAL_STAGES" ]; do
    STAGE_NAME="$(get_stage_name "$CURRENT_STAGE")"
    GATE_TYPE="$(get_stage_gate_type "$CURRENT_STAGE")"
    SKILL_FILE="$(get_stage_skill_file "$CURRENT_STAGE")"
    LOG_FILE="$RESEARCH_DIR/stage-${CURRENT_STAGE}-output.log"

    echo "=== Stage $CURRENT_STAGE: $STAGE_NAME ($GATE_TYPE) ==="
    echo ""

    # Load and display skill file info
    if [ -n "$SKILL_FILE" ] && [ -f "$SKILL_FILE" ]; then
        echo "  Skill file: $SKILL_FILE"
        CMD="$(extract_command "$SKILL_FILE")"
    else
        echo "  Skill file: (none found)"
        CMD=""
    fi

    # Execute command if one exists
    if [ -n "$CMD" ]; then
        echo "  Command: $CMD"
        echo ""
        echo "  Executing..."
        echo ""

        # Run the command from the working directory, capture output
        _cmd_exit=0
        (cd "$WORKDIR" && eval "$CMD") > "$LOG_FILE" 2>&1 || _cmd_exit=$?

        if [ "$_cmd_exit" -eq 0 ]; then
            echo "  Command completed successfully (exit code 0)"
        else
            echo "  Command exited with code $_cmd_exit"
        fi

        # Parse output for results
        parse_output "$LOG_FILE" "$CURRENT_STAGE"

        # Write artifact summary
        _artifact_file="$RESEARCH_DIR/stage-${CURRENT_STAGE}-artifact.md"
        {
            echo "# Stage $CURRENT_STAGE: $STAGE_NAME — Run Artifact"
            echo ""
            echo "**Date:** $(date +%Y-%m-%d\ %H:%M:%S)"
            echo "**Project:** $PROJECT"
            echo "**Command:** \`$CMD\`"
            echo "**Exit code:** $_cmd_exit"
            echo ""
            if [ "$_cmd_exit" -eq 0 ]; then
                echo "**Result:** PASS"
            else
                echo "**Result:** FAIL"
            fi
            echo ""
            echo "## Output"
            echo ""
            echo '```'
            cat "$LOG_FILE"
            echo '```'
        } > "$_artifact_file"
    else
        echo "  No command defined for this stage — skipping execution."
        echo ""
    fi

    echo ""

    # Run gate-enforcer
    _gate_result="PASSED"
    _gate_output=""
    if [ -f "$PIPELINE_DIR/gate-enforcer.sh" ]; then
        echo "  Running gate-enforcer for stage $CURRENT_STAGE..."
        echo ""
        _gate_exit=0
        _gate_output="$(sh "$PIPELINE_DIR/gate-enforcer.sh" "$CURRENT_STAGE" "$PROJECT" 2>&1)" || _gate_exit=$?

        echo "$_gate_output" | sed 's/^/  /'
        echo ""

        if [ "$_gate_exit" -ne 0 ]; then
            _gate_result="BLOCKED"
        fi
    else
        echo "  (gate-enforcer.sh not found, skipping gate check)"
        echo ""
    fi

    # Handle gate result
    if [ "$_gate_result" = "PASSED" ]; then
        echo "  >>> Stage $CURRENT_STAGE: PASSED"
        record_stage "$CURRENT_STAGE" "$STAGE_NAME" "PASSED"
        COMPLETED_STAGES=$((COMPLETED_STAGES + 1))
    else
        # BLOCKED
        _block_reason="$(echo "$_gate_output" | grep 'BLOCKED:' | head -1)"
        if [ -z "$_block_reason" ]; then
            _block_reason="Gate check failed"
        fi

        echo "  >>> Stage $CURRENT_STAGE: BLOCKED"
        echo "  Reason: $_block_reason"
        echo ""

        if [ "$GATE_TYPE" = "auto" ]; then
            # Auto gate blocked — hard stop
            record_stage "$CURRENT_STAGE" "$STAGE_NAME" "BLOCKED"
            # Mark remaining stages as SKIPPED
            _skip_stage=$((CURRENT_STAGE + 1))
            while [ "$_skip_stage" -le "$TOTAL_STAGES" ]; do
                _skip_name="$(get_stage_name "$_skip_stage")"
                record_stage "$_skip_stage" "$_skip_name" "SKIPPED"
                _skip_stage=$((_skip_stage + 1))
            done
            print_summary
            exit 1
        else
            # Human gate — interactive prompt
            if prompt_human_gate "$CURRENT_STAGE" "$_block_reason" "$LOG_FILE"; then
                echo "  >>> Stage $CURRENT_STAGE: PASSED (human approved)"
                record_stage "$CURRENT_STAGE" "$STAGE_NAME" "PASSED"
                COMPLETED_STAGES=$((COMPLETED_STAGES + 1))
            else
                record_stage "$CURRENT_STAGE" "$STAGE_NAME" "ABORTED"
                # Mark remaining stages as SKIPPED
                _skip_stage=$((CURRENT_STAGE + 1))
                while [ "$_skip_stage" -le "$TOTAL_STAGES" ]; do
                    _skip_name="$(get_stage_name "$_skip_stage")"
                    record_stage "$_skip_stage" "$_skip_name" "SKIPPED"
                    _skip_stage=$((_skip_stage + 1))
                done
                print_summary
                exit 1
            fi
        fi
    fi

    echo ""
    CURRENT_STAGE=$((CURRENT_STAGE + 1))
done

# ─── All stages complete ──────────────────────────────────────────────────────

print_summary
exit 0
