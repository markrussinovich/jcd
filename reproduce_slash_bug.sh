#!/bin/bash

echo "=== Reproducing the Trailing Slash Bug ==="
echo "Testing the exact scenario described by the user"
echo

# Create test structure similar to user's example
TEST_DIR="/tmp/foo"
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
echo "This should complete to something like '/tmp/foo/foo1/foo2/'"

export COMP_WORDS=("mcd" "2")
export COMP_CWORD=1
export COMPREPLY=()
_mcd_tab_complete

first_result="${COMPREPLY[0]}"
echo
echo "First completion result: '$first_result'"

if [[ "$first_result" == *"foo2"* ]]; then
    echo "✓ First tab worked: got path containing foo2"
    if [[ "$first_result" == *"foo2/" ]]; then
        echo "  - Has trailing slash (single match case)"
    else
        echo "  - No trailing slash (multiple match case)"
    fi
else
    echo "✗ First tab failed to find foo2"
    exit 1
fi

echo
echo "=== Step 2: Tab again with the completed path ==="
echo "This should explore subdirectories under foo2, showing subdir1, subdir2"
echo "NOT add another slash to make it '$first_result/'"

export COMP_WORDS=("mcd" "$first_result")
export COMP_CWORD=1
export COMPREPLY=()
_mcd_tab_complete

second_result="${COMPREPLY[0]}"
echo
echo "Second completion result: '$second_result'"

# Check what happened
if [[ "$second_result" == *"//" ]]; then
    echo "✗ BUG CONFIRMED: Double slash detected"
    echo "  First:  '$first_result'"
    echo "  Second: '$second_result'"
elif [[ "$second_result" == *"subdir"* ]]; then
    echo "✓ FIXED: Found subdirectory"
elif [[ "$second_result" == "$first_result" ]]; then
    echo "✗ BUG: No change, same path returned"
else
    echo "? UNCLEAR: Unexpected result"
fi

echo
echo "Expected behavior:"
echo "  First tab:  'mcd 2' → '/tmp/foo/foo1/foo2/'"
echo "  Second tab: '/tmp/foo/foo1/foo2/' → '/tmp/foo/foo1/foo2/subdir1'"
echo
echo "Actual behavior:"
echo "  First tab:  'mcd 2' → '$first_result'"
echo "  Second tab: '$first_result' → '$second_result'"

# Cleanup
rm -rf "$TEST_DIR"