#!/usr/bin/env bash
# run-tests.sh — Test runner for superpowers OpenClaw integration tests.
#
# Usage:
#   ./run-tests.sh                          # Run fast tests only
#   ./run-tests.sh --all                    # Run all tests including SDD integration
#   ./run-tests.sh --test test-brainstorm-gate.sh  # Run specific test
#   ./run-tests.sh --dry-run                # Show what would run
#   ./run-tests.sh --verbose                # Show full agent output on failures
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================"
echo " Superpowers Integration Test Suite"
echo "========================================"
echo ""
echo "Repository: $(cd .. && pwd)"
echo "Test time:  $(date)"
echo "OpenClaw:   $(openclaw --version 2>/dev/null | head -1 || echo 'not found')"
echo ""

# Check dependencies
if ! command -v openclaw &>/dev/null; then
    echo "ERROR: openclaw CLI not found"
    exit 1
fi
if ! command -v jq &>/dev/null; then
    echo "ERROR: jq not found (needed for JSON parsing)"
    echo "Install: brew install jq"
    exit 1
fi

# Parse args
VERBOSE=false
DRY_RUN=false
SPECIFIC_TEST=""
RUN_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --test|-t)
            SPECIFIC_TEST="$2"
            shift 2
            ;;
        --all|-a)
            RUN_ALL=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --all, -a          Run all tests including expensive integration"
            echo "  --test, -t NAME    Run only the specified test"
            echo "  --dry-run, -n      Show what would run (no tokens burned)"
            echo "  --verbose, -v      Show full agent output on failures"
            echo "  --help, -h         Show this help"
            echo ""
            echo "Fast tests (~2-5 min, ~\$0.50):"
            echo "  test-skill-triggering.sh   Verify right skill fires for right task"
            echo "  test-brainstorm-gate.sh    Verify brainstorming enforces design-first"
            echo "  test-beads-detection.sh    Verify beads vs inline tracking detection"
            echo ""
            echo "Integration tests (~5-15 min, ~\$2-8):"
            echo "  test-sdd-workflow.sh       Full subagent-driven development end-to-end"
            exit 0
            ;;
        *)
            echo "Unknown option: $1 (use --help)"
            exit 1
            ;;
    esac
done

export VERBOSE

# Test lists
fast_tests=(
    "test-skill-triggering.sh"
    "test-brainstorm-gate.sh"
    "test-beads-detection.sh"
)

integration_tests=(
    "test-sdd-workflow.sh"
)

# Build test list
if [ -n "$SPECIFIC_TEST" ]; then
    tests=("$SPECIFIC_TEST")
elif [ "$RUN_ALL" = true ]; then
    tests=("${fast_tests[@]}" "${integration_tests[@]}")
else
    tests=("${fast_tests[@]}")
fi

# Dry run
if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN — would execute:"
    echo ""
    for test in "${tests[@]}"; do
        if [ -f "$SCRIPT_DIR/$test" ]; then
            echo "  ✓ $test"
        else
            echo "  ✗ $test (not found)"
        fi
    done
    echo ""
    if [ "$RUN_ALL" = false ] && [ ${#integration_tests[@]} -gt 0 ]; then
        echo "Skipped (use --all):"
        for test in "${integration_tests[@]}"; do
            echo "  ⏭ $test"
        done
    fi
    exit 0
fi

# Run tests
total_passed=0
total_failed=0
total_skipped=0
start_time=$(date +%s)

for test in "${tests[@]}"; do
    echo "----------------------------------------"
    echo "Running: $test"
    echo "----------------------------------------"
    echo ""

    test_path="$SCRIPT_DIR/$test"

    if [ ! -f "$test_path" ]; then
        echo "  [SKIP] Test file not found: $test"
        total_skipped=$((total_skipped + 1))
        echo ""
        continue
    fi

    chmod +x "$test_path" 2>/dev/null || true

    test_start=$(date +%s)

    if bash "$test_path"; then
        test_end=$(date +%s)
        test_duration=$((test_end - test_start))
        echo "  Completed in ${test_duration}s"
    else
        test_end=$(date +%s)
        test_duration=$((test_end - test_start))
        echo "  Completed in ${test_duration}s (with failures)"
        total_failed=$((total_failed + 1))
    fi

    echo ""
done

end_time=$(date +%s)
total_duration=$((end_time - start_time))

echo "========================================"
echo " Summary"
echo "========================================"
echo ""
echo "  Duration: ${total_duration}s"
echo ""

if [ "$RUN_ALL" = false ] && [ ${#integration_tests[@]} -gt 0 ]; then
    echo "Note: Integration tests skipped (use --all for full suite)."
    echo ""
fi

if [ "$total_failed" -gt 0 ]; then
    echo "STATUS: SOME TESTS HAD FAILURES"
    exit 1
else
    echo "STATUS: ALL TESTS COMPLETED"
    exit 0
fi
