#!/usr/bin/env bash
# test-skill-triggering.sh — Verify the right superpowers skill fires for the right task.
#
# Sends task prompts to OpenClaw and checks that the agent's response
# demonstrates it followed the correct methodology (not just named it).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo -e "${CYAN}=== Test: Skill Triggering ===${NC}"
echo ""

TOTAL_COST="$0.0000"

# --- Test 1: Debugging prompt triggers systematic approach ---
echo "Test 1: Debugging prompt → systematic-debugging methodology"

result=$(run_agent \
    "You have a Node.js test that passes when run alone but fails in the full suite. The test file is test/user.test.js and it tests user creation. Describe ONLY your investigation approach — do NOT write any code. What are the phases of your investigation?" \
    120)

text=$(get_response_text "$result")
cost=$(estimate_cost "$result")
echo "  (cost: $cost)"

# Should follow systematic debugging phases, not jump to fixes
assert_contains "$text" "reproduc\|isolat\|replicate" "Mentions reproduction/isolation phase" || true
assert_contains "$text" "root cause\|hypothesis\|investigate" "Investigative mindset, not just 'try this'" || true
assert_not_contains "$text" "just change\|simply replace\|quick fix" "Doesn't jump to fixes" || true

echo ""

# --- Test 2: Build prompt triggers brainstorming ---
echo "Test 2: Build prompt → brainstorming methodology"

result=$(run_agent \
    "I want to build a CLI tool that converts CSV files to JSON. Before we start coding, what should we think through? Just describe the design considerations — no code yet." \
    120)

text=$(get_response_text "$result")
cost=$(estimate_cost "$result")
echo "  (cost: $cost)"

# Should brainstorm/design before jumping to implementation
assert_contains "$text" "edge case\|error handling\|input\|output\|design\|consider\|requirement" "Considers design aspects" || true
assert_contains "$text" "format\|schema\|struct\|option\|flag\|argument" "Thinks about interface/structure" || true
assert_not_contains "$text" "^import\|^const\|^function\|require(" "Doesn't jump straight to code" || true

echo ""

# --- Test 3: Skills are available in session ---
echo "Test 3: Superpowers skills loaded in agent sessions"

# Use the result from test 1 (already have it)
assert_skill_available "$result" "brainstorming" || true
assert_skill_available "$result" "systematic-debugging" || true
assert_skill_available "$result" "writing-plans" || true
assert_skill_available "$result" "test-driven-development" || true
assert_skill_available "$result" "subagent-driven-development" || true
assert_skill_available "$result" "using-superpowers" || true

echo ""

print_summary "$TOTAL_COST"
