#!/bin/bash

echo "=== Testing Final Trailing Slash Fix ==="
echo "Fix: When absolute path ends with '/', search for subdirectories"
echo

# Create test structure
TEST_DIR="/tmp/foo"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/foo1/foo2/subdir1"
mkdir -p "$TEST_DIR/foo1/foo2/subdir2"
mkdir -p "$TEST_DIR/foo1/foo2/deep/nested"

echo "Created test structure:"
find "$TEST_DIR" -type d | sort

cd "$TEST_DIR"
echo "Working from: $(pwd)"

echo
echo "=== Test 1: Binary behavior with trailing slash ==="
echo "Testing that the Rust binary now handles paths ending with '/'"

# Test without trailing slash (should return the directory)
result_no_slash=$(/datadrive/mcd/target/release/mcd "/tmp/foo/foo1/foo2" 0 2>/dev/null)
echo "Without slash: '/tmp/foo/foo1/foo2' → '$result_no_slash'"

# Test with trailing slash (should return subdirectories)
echo "With slash: '/tmp/foo/foo1/foo2/' → "
for i in {0..3}; do
    result=$(/datadrive/mcd/target/release/mcd "/tmp/foo/foo1/foo2/" $i 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "  Match $i: $result"
    else
        echo "  No more matches after index $((i-1))"
        break
    fi
done

echo
echo "=== Test 2: Tab completion behavior ==="
echo "Testing the full tab completion scenario"

# Source mcd function
export MCD_BINARY="/datadrive/mcd/target/release/mcd"
export MCD_DEBUG=0  # Disable debug for cleaner output
source /datadrive/mcd/mcd_function.sh

# First tab - get a directory without trailing slash
export COMP_WORDS=("mcd" "2")
export COMP_CWORD=1
export COMPREPLY=()
_mcd_tab_complete

first_result="${COMPREPLY[0]}"
echo "First tab: 'mcd 2' → '$first_result'"

# Add trailing slash manually to simulate what bash completion does
if [[ "$first_result" != *"/" ]]; then
    manual_slash="$first_result/"
    echo "Manually adding slash: '$manual_slash'"
    
    # Test what happens when we tab complete a path with trailing slash
    export COMP_WORDS=("mcd" "$manual_slash")
    export COMP_CWORD=1
    export COMPREPLY=()
    _mcd_tab_complete
    
    second_result="${COMPREPLY[0]}"
    echo "Second tab: '$manual_slash' → '$second_result'"
    
    if [[ "$second_result" == *"//" ]]; then
        echo "✗ STILL BUGGY: Double slash detected"
    elif [[ "$second_result" == *"subdir"* ]] || [[ "$second_result" == *"deep"* ]]; then
        echo "✓ FIXED: Found subdirectory"
    elif [[ "$second_result" == "$first_result" ]]; then
        echo "? NO CHANGE: Same path returned (might be correct if no subdirs)"
    else
        echo "? UNCLEAR: Unexpected result"
    fi
fi

echo
echo "=== Test 3: Edge cases ==="

# Test with leaf directory (no subdirectories)
mkdir -p /tmp/leaf_test
cd /tmp/leaf_test

echo "Testing leaf directory behavior:"
echo "Leaf directory with slash: '/tmp/leaf_test/' → "
result=$(/datadrive/mcd/target/release/mcd "/tmp/leaf_test/" 0 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "  Result: $result"
else
    echo "  No matches (expected for empty directory)"
fi

# Cleanup
rm -rf "$TEST_DIR" /tmp/leaf_test

echo
echo "=== Summary ==="
echo "1. Binary should find subdirectories when path ends with '/'"
echo "2. Tab completion should explore subdirectories, not add double slash"
echo "3. Leaf directories should be handled gracefully"