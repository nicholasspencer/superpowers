#!/usr/bin/env bash
# test-helpers.sh — Shared utilities for superpowers integration tests
#
# Uses `openclaw agent` to drive real LLM sessions and verify behavior.
# Each test creates an isolated session, sends a task, and asserts on
# the JSON response + filesystem artifacts.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# --- Session helpers ---

# Run an OpenClaw agent session and capture JSON output.
# Usage: result=$(run_agent "prompt text" [timeout_seconds] [session_id])
run_agent() {
    local prompt="$1"
    local timeout="${2:-300}"
    local session_id="${3:-test-$(date +%s)-$$-$RANDOM}"

    openclaw agent \
        --session-id "$session_id" \
        --message "$prompt" \
        --json \
        --timeout "$timeout" \
        2>/dev/null
}

# Extract the text response from agent JSON output.
# Usage: text=$(get_response_text "$json_result")
get_response_text() {
    local json="$1"
    echo "$json" | jq -r '.result.payloads[0].text // empty'
}

# Extract token usage from agent JSON output.
# Usage: tokens=$(get_token_usage "$json_result")
get_token_usage() {
    local json="$1"
    echo "$json" | jq -r '.result.meta.agentMeta.usage // empty'
}

# Extract the skills available in the session.
# Usage: skills=$(get_available_skills "$json_result")
get_available_skills() {
    local json="$1"
    echo "$json" | jq -r '.result.meta.systemPromptReport.skills.entries[].name' 2>/dev/null
}

# Estimate cost from token usage (rough: $3/$15 per M input/output).
# Usage: cost=$(estimate_cost "$json_result")
estimate_cost() {
    local json="$1"
    local input output cache_write
    input=$(echo "$json" | jq -r '.result.meta.agentMeta.usage.input // 0')
    output=$(echo "$json" | jq -r '.result.meta.agentMeta.usage.output // 0')
    cache_write=$(echo "$json" | jq -r '.result.meta.agentMeta.usage.cacheWrite // 0')

    # Rough estimate: input $3/M, output $15/M, cache write $3.75/M
    echo "$input $output $cache_write" | awk '{
        cost = ($1 * 3 + $2 * 15 + $3 * 3.75) / 1000000
        printf "$%.4f", cost
    }'
}

# --- Fixture helpers ---

# Create a temporary project directory with a git repo.
# Usage: project_dir=$(create_temp_project)
create_temp_project() {
    local dir
    dir=$(mktemp -d -t superpowers-test-XXXXXX)
    cd "$dir"
    git init -q
    git config user.email "test@superpowers.dev"
    git config user.name "Superpowers Test"
    echo "$dir"
}

# Copy a fixture into a temp project.
# Usage: copy_fixture "node-hello" "$project_dir"
copy_fixture() {
    local fixture_name="$1"
    local dest="$2"
    if [ -d "$FIXTURES_DIR/$fixture_name" ]; then
        cp -r "$FIXTURES_DIR/$fixture_name/"* "$dest/" 2>/dev/null || true
        cp -r "$FIXTURES_DIR/$fixture_name/".[^.]* "$dest/" 2>/dev/null || true
    fi
}

# Clean up a temp project.
# Usage: cleanup_project "$project_dir"
cleanup_project() {
    local dir="$1"
    if [ -d "$dir" ] && [[ "$dir" == /tmp/* ]]; then
        rm -rf "$dir"
    fi
}

# --- Assertion helpers ---

# Check if text contains a pattern (case-insensitive).
# Usage: assert_contains "$text" "pattern" "test name"
assert_contains() {
    local text="$1"
    local pattern="$2"
    local test_name="${3:-test}"

    if echo "$text" | grep -qi "$pattern"; then
        echo -e "  ${GREEN}[PASS]${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}[FAIL]${NC} $test_name"
        echo -e "  ${RED}Expected to find:${NC} $pattern"
        if [ "${VERBOSE:-false}" = true ]; then
            echo "  In output:"
            echo "$text" | head -20 | sed 's/^/    /'
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Check if text does NOT contain a pattern (case-insensitive).
# Usage: assert_not_contains "$text" "pattern" "test name"
assert_not_contains() {
    local text="$1"
    local pattern="$2"
    local test_name="${3:-test}"

    if echo "$text" | grep -qi "$pattern"; then
        echo -e "  ${RED}[FAIL]${NC} $test_name"
        echo -e "  ${RED}Did not expect to find:${NC} $pattern"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    else
        echo -e "  ${GREEN}[PASS]${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    fi
}

# Check if a file exists.
# Usage: assert_file_exists "/path/to/file" "test name"
assert_file_exists() {
    local filepath="$1"
    local test_name="${2:-file exists}"

    if [ -f "$filepath" ]; then
        echo -e "  ${GREEN}[PASS]${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}[FAIL]${NC} $test_name"
        echo -e "  ${RED}File not found:${NC} $filepath"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Check if a directory exists.
# Usage: assert_dir_exists "/path/to/dir" "test name"
assert_dir_exists() {
    local dirpath="$1"
    local test_name="${2:-directory exists}"

    if [ -d "$dirpath" ]; then
        echo -e "  ${GREEN}[PASS]${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}[FAIL]${NC} $test_name"
        echo -e "  ${RED}Directory not found:${NC} $dirpath"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Check if a skill name appears in available skills.
# Usage: assert_skill_available "$json_result" "brainstorming" "test name"
assert_skill_available() {
    local json="$1"
    local skill_name="$2"
    local test_name="${3:-skill available: $skill_name}"

    if get_available_skills "$json" | grep -q "^${skill_name}$"; then
        echo -e "  ${GREEN}[PASS]${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}[FAIL]${NC} $test_name"
        echo -e "  ${RED}Skill not in available_skills:${NC} $skill_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# --- Reporting ---

# Print test summary with cost.
# Usage: print_summary "$total_cost"
print_summary() {
    local total_cost="${1:-unknown}"
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN} Test Results${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "  Passed:  ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Failed:  ${RED}$TESTS_FAILED${NC}"
    echo -e "  Skipped: ${YELLOW}$TESTS_SKIPPED${NC}"
    echo -e "  Cost:    $total_cost"
    echo ""

    if [ "$TESTS_FAILED" -gt 0 ]; then
        echo -e "  ${RED}STATUS: FAILED${NC}"
        return 1
    else
        echo -e "  ${GREEN}STATUS: PASSED${NC}"
        return 0
    fi
}

# Export for subshells
export -f run_agent get_response_text get_token_usage get_available_skills estimate_cost
export -f create_temp_project copy_fixture cleanup_project
export -f assert_contains assert_not_contains assert_file_exists assert_dir_exists assert_skill_available
export -f print_summary
export SCRIPT_DIR FIXTURES_DIR
export TESTS_PASSED TESTS_FAILED TESTS_SKIPPED
