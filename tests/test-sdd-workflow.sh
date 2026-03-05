#!/usr/bin/env bash
# test-sdd-workflow.sh — Subagent-driven development end-to-end test.
#
# This is the expensive integration test. Creates a toy Node.js project with
# a 2-task plan, asks the agent to execute it using subagent-driven development,
# and verifies:
#   - Subagents were mentioned/dispatched
#   - Implementation files were created
#   - Tests pass
#   - Git commits were made
#
# Expected runtime: 5-15 minutes. Expected cost: $2-8.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo -e "${CYAN}=== Test: Subagent-Driven Development Workflow ===${NC}"
echo ""
echo -e "${YELLOW}⚠ This is an integration test. Expect 5-15 minutes and ~\$2-8 in tokens.${NC}"
echo ""

# --- Setup ---
echo "Setting up test project..."
project_dir=$(create_temp_project)
copy_fixture "node-hello" "$project_dir"
mkdir -p "$project_dir/docs/plans" "$project_dir/src" "$project_dir/test"
cp "$FIXTURES_DIR/plans/two-task-plan.md" "$project_dir/docs/plans/"
cd "$project_dir" && git add -A && git commit -q -m "initial: test fixture"
echo "  Project: $project_dir"
echo ""

# --- Execute ---
echo "Running subagent-driven development workflow..."
echo "  (this will take several minutes)"
echo ""

result=$(run_agent \
    "Execute the implementation plan at docs/plans/two-task-plan.md using subagent-driven development. The project is at $project_dir. Create the source files, write the tests, and verify everything passes. Commit your work." \
    600 \
    "test-sdd-$(date +%s)")

text=$(get_response_text "$result")
cost=$(estimate_cost "$result")
echo "  Response received (cost: $cost)"
echo ""

# --- Verify behavior ---
echo "Verifying workflow behavior..."

# The agent should reference subagents or task dispatch
assert_contains "$text" "subagent\|spawn\|sessions_spawn\|dispatch\|task 1\|task 2" \
    "Agent references subagent dispatch or task execution" || true

# Should mention review of some kind
assert_contains "$text" "review\|verify\|check\|compliance\|quality" \
    "Agent mentions review step" || true

echo ""

# --- Verify artifacts ---
echo "Verifying project artifacts..."

# Implementation files should exist
assert_file_exists "$project_dir/src/math.js" "src/math.js created" || true

# Test files should exist
assert_file_exists "$project_dir/test/math.test.js" "test/math.test.js created" || true

# Check implementation content
if [ -f "$project_dir/src/math.js" ]; then
    local_content=$(cat "$project_dir/src/math.js")
    assert_contains "$local_content" "add" "add function exists" || true
    assert_contains "$local_content" "multiply" "multiply function exists" || true
fi

# Tests should pass
echo ""
echo "Running project tests..."
if cd "$project_dir" && npm test 2>&1; then
    echo -e "  ${GREEN}[PASS]${NC} npm test passes"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "  ${RED}[FAIL]${NC} npm test failed"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Git commits should exist beyond the initial one
echo ""
echo "Checking git history..."
commit_count=$(cd "$project_dir" && git log --oneline | wc -l | tr -d ' ')
if [ "$commit_count" -gt 1 ]; then
    echo -e "  ${GREEN}[PASS]${NC} Git commits created ($commit_count total)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "  ${RED}[FAIL]${NC} No new git commits (only $commit_count)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""

# --- Cleanup ---
cleanup_project "$project_dir"

print_summary "$cost"
