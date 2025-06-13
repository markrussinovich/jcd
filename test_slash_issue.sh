#!/bin/bash

echo "=== Testing Trailing Slash Issue ==="
echo "Issue: After getting '/tmp/foo/foo1/foo2' and pressing tab again,"
echo "       it should explore subdirectories, not add another slash"
echo

# Create test structure
TEST_DIR="/tmp/mcd_slash_test"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/foo/foo1/foo2/subdir1"
mkdir -p "$TEST_DIR/foo/foo1/foo2/subdir2"

echo "Created test structure:"
find "$TEST_DIR" -type d | sort

cd "$TEST_DIR"
echo "Working from: $(pwd)"

# Source the mcd function
export MCD_BINARY="/datadrive/mcd/target/release/mcd"
export MCD_DEBUG=1
source /datadrive/mcd/mcd_function.sh

echo
echo "=== Test Scenario ==="
echo "1. User types 'mcd 2' + tab -> should get 'foo/foo1/foo2/'"
echo "2. User presses tab again -> should show subdir1, subdir2 (not add another slash)"

echo
echo "Step 1: Simulating 'mcd 2' + tab"
export COMP_WORDS=("mcd" "2")
export COMP_CWORD=1
export COMPREPLY=()
_mcd_tab_complete

echo "First completion result: '${COMPREPLY[0]}'"

echo
echo "Step 2: Simulating tab again with the completed path"
export COMP_WORDS=("mcd" "${COMPREPLY[0]}")
export COMP_CWORD=1
export COMPREPLY=()
_mcd_tab_complete

echo "Second completion result: '${COMPREPLY[0]}'"

if [[ "${COMPREPLY[0]}" == *"//" ]]; then
    echo "✗ BUG: Double slash detected in result"
elif [[ "${COMPREPLY[0]}" == *"subdir"* ]]; then
    echo "✓ GOOD: Found subdirectory"
else
    echo "? UNCLEAR: Result doesn't match expected patterns"
fi

echo
echo "Expected behavior:"
echo "- First tab: complete to something like '$TEST_DIR/foo/foo1/foo2/'"
echo "- Second tab: show subdirectories like '$TEST_DIR/foo/foo1/foo2/subdir1'"
echo "- NOT: add another slash like '$TEST_DIR/foo/foo1/foo2//'"

# Cleanup
rm -rf "$TEST_DIR"