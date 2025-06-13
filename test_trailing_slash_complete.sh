#!/bin/bash

echo "=== Testing the Complete Trailing Slash Scenario ==="
echo "Following the exact user workflow: mcd 2 + tab + tab + tab"
echo

# Create test structure
TEST_DIR="test_slash_bug"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/foo1/foo2/subdir1"
mkdir -p "$TEST_DIR/foo1/foo2/subdir2"

echo "Created test structure:"
find "$TEST_DIR" -type d | sort

cd "$TEST_DIR"
echo "Working from: $(pwd)"

# Source the mcd function with debug enabled
export MCD_BINARY="/datadrive/mcd/target/release/mcd"
export MCD_DEBUG=1
source /datadrive/mcd/mcd_function.sh

echo
echo "=== Step 1: mcd 2 + tab ==="
export COMP_WORDS=("mcd" "2")
export COMP_CWORD=1
export COMPREPLY=()
_mcd_tab_complete

first_result="${COMPREPLY[0]}"
echo "First result: '$first_result'"

echo
echo "=== Step 2: Tab again (cycling through matches) ==="
export COMP_WORDS=("mcd" "$first_result")
export COMP_CWORD=1
export COMPREPLY=()
_mcd_tab_complete

second_result="${COMPREPLY[0]}"
echo "Second result: '$second_result'"

echo
echo "=== Step 3: Tab again (now user has '/tmp/foo/foo1/foo2/') ==="
# This simulates the user having the completed path with trailing slash
# and pressing tab to explore subdirectories
third_input="$second_result"
export COMP_WORDS=("mcd" "$third_input")
export COMP_CWORD=1
export COMPREPLY=()
_mcd_tab_complete

third_result="${COMPREPLY[0]}"
echo "Third result: '$third_result'"

# Check for the bug
echo
echo "=== Analysis ==="
echo "Step 1: 'mcd 2' → '$first_result'"
echo "Step 2: '$first_result' → '$second_result'"
echo "Step 3: '$second_result' → '$third_result'"

if [[ "$third_result" == *"//" ]]; then
    echo "✗ BUG CONFIRMED: Double slash detected in step 3"
elif [[ "$third_result" == *"subdir"* ]]; then
    echo "✓ WORKING: Found subdirectory in step 3"
elif [[ "$third_result" == "$second_result" ]]; then
    echo "? LEAF: No change, treating as leaf directory"
elif [[ "$third_result" == "${second_result%/}" ]]; then
    echo "✓ FIXED: Tab on trailing slash removed slash (leaf directory behavior)"
else
    echo "? UNCLEAR: Unexpected result in step 3"
fi

# Cleanup
cd ..
rm -rf "$TEST_DIR"