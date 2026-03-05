#!/usr/bin/env bash
# test-brainstorm-gate.sh — Verify brainstorming enforces design-before-code.
#
# The brainstorming skill should prevent the agent from jumping straight to
# implementation when given a "build X" prompt without an existing plan.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo -e "${CYAN}=== Test: Brainstorm Gate ===${NC}"
echo ""

# --- Test 1: Agent brainstorms before coding ---
echo "Test 1: Agent brainstorms when asked to build something new"

result=$(run_agent \
    "Build me a URL shortener service in Node.js. Start working on it now." \
    180)

text=$(get_response_text "$result")
cost=$(estimate_cost "$result")
echo "  (cost: $cost)"

# The brainstorming skill should kick in and force design discussion
# before any implementation begins
assert_contains "$text" "brainstorm\|design\|plan\|think through\|consider\|requirement\|approach\|architect" \
    "Agent enters design/brainstorming phase" || true

assert_contains "$text" "question\|clarif\|option\|tradeoff\|alternativ\|decision" \
    "Agent asks clarifying questions or presents options" || true

# Agent should NOT have produced implementation code
assert_not_contains "$text" "npm init\|mkdir src\|express()\|app\.listen\|createServer" \
    "Agent didn't jump straight to implementation" || true

echo ""

# --- Test 2: Agent acknowledges existing plan ---
echo "Test 2: Agent respects an existing plan (doesn't re-brainstorm)"

# Create a temp project with a plan already in place
project_dir=$(create_temp_project)
copy_fixture "node-hello" "$project_dir"
mkdir -p "$project_dir/docs/plans"
cp "$FIXTURES_DIR/plans/two-task-plan.md" "$project_dir/docs/plans/"
cd "$project_dir" && git add -A && git commit -q -m "initial"

result=$(run_agent \
    "Execute the implementation plan in docs/plans/two-task-plan.md. The project is at $project_dir." \
    180)

text=$(get_response_text "$result")
cost=$(estimate_cost "$result")
echo "  (cost: $cost)"

# With an existing plan, agent should move to execution, not brainstorming
assert_contains "$text" "task\|implement\|creat\|execut\|plan" \
    "Agent references plan execution" || true

assert_not_contains "$text" "brainstorm\|should we first think\|before we start" \
    "Agent doesn't try to re-brainstorm an existing plan" || true

cleanup_project "$project_dir"

echo ""

print_summary
