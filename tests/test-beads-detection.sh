#!/usr/bin/env bash
# test-beads-detection.sh — Verify skills detect beads vs inline tracking.
#
# When .beads/ exists in a project, superpowers skills should use `bd` commands
# for task tracking. Without it, they should track inline in plan markdown.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo -e "${CYAN}=== Test: Beads Detection ===${NC}"
echo ""

# --- Test 1: Agent mentions beads when .beads/ exists ---
echo "Test 1: With .beads/ → agent references beads tracking"

project_dir=$(create_temp_project)
copy_fixture "node-hello" "$project_dir"
mkdir -p "$project_dir/.beads"
mkdir -p "$project_dir/docs/plans"
cp "$FIXTURES_DIR/plans/two-task-plan.md" "$project_dir/docs/plans/"
cd "$project_dir" && git add -A && git commit -q -m "initial with beads"

result=$(run_agent \
    "I want to execute the plan in docs/plans/two-task-plan.md. The project is at $project_dir. How would you track progress on the tasks? Describe your tracking approach — don't execute yet." \
    120)

text=$(get_response_text "$result")
cost=$(estimate_cost "$result")
echo "  (cost: $cost)"

assert_contains "$text" "bead\|bd " \
    "Agent mentions beads/bd for tracking" || true

cleanup_project "$project_dir"

echo ""

# --- Test 2: Agent uses inline tracking without .beads/ ---
echo "Test 2: Without .beads/ → agent references inline tracking"

project_dir=$(create_temp_project)
copy_fixture "node-hello" "$project_dir"
mkdir -p "$project_dir/docs/plans"
cp "$FIXTURES_DIR/plans/two-task-plan.md" "$project_dir/docs/plans/"
cd "$project_dir" && git add -A && git commit -q -m "initial without beads"

result=$(run_agent \
    "I want to execute the plan in docs/plans/two-task-plan.md. The project is at $project_dir. How would you track progress on the tasks? Describe your tracking approach — don't execute yet." \
    120)

text=$(get_response_text "$result")
cost=$(estimate_cost "$result")
echo "  (cost: $cost)"

# Without beads, should mention inline/markdown tracking
assert_contains "$text" "inline\|markdown\|check.*off\|plan.*file\|track.*in.*plan\|update.*plan" \
    "Agent mentions inline/markdown tracking" || true

assert_not_contains "$text" "bd create\|bd start\|bd close" \
    "Agent doesn't reference bd commands without .beads/" || true

cleanup_project "$project_dir"

echo ""

print_summary
