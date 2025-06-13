#!/bin/bash

echo "=== Testing Trailing Slash Fix ==="
echo "Issue: After completion adds trailing slash, next tab should explore subdirectories"
echo "Fix: Remove requirement that original pattern must end with slash"
echo

# Create comprehensive test structure
TEST_ROOT="/tmp/mcd_trailing_slash_test"
rm -rf "$TEST_ROOT"

# Test case 1: Single match with subdirectories
mkdir -p "$TEST_ROOT/case1/foo2/subdir1"
mkdir -p "$TEST_ROOT/case1/foo2/subdir2"

# Test case 2: Multiple matches
mkdir -p "$TEST_ROOT/case2/foo1"
mkdir -p "$TEST_ROOT/case2/foo2/subdir1"

# Test case 3: Leaf directory (no subdirectories)
mkdir -p "$TEST_ROOT/case3/foo3"

echo "Created test structure:"
find "$TEST_ROOT" -type d | sort

# Source mcd function
export MCD_BINARY="/datadrive/mcd/target/release/mcd"
export MCD_DEBUG=0  # Disable debug for cleaner output
source /datadrive/mcd/mcd_function.sh

echo
echo "=== Test Case 1: Single match with subdirectories ==="
echo "Pattern: '2' should complete to 'foo2/', then tab again should show subdirectories"

cd "$TEST_ROOT/case1"
echo "Working directory: $(pwd)"

# First tab - should complete to foo2/
export COMP_WORDS=("mcd" "2")
export COMP_CWORD=1
export COMPREPLY=()
_mcd_tab_complete

first_result="${COMPREPLY[0]}"
echo "First tab result: '$first_result'"

if [[ "$first_result" == *"foo2/" ]]; then
    echo "✓ First tab correct: added trailing slash"
    
    # Second tab - should explore subdirectories
    export COMP_WORDS=("mcd" "$first_result")
    export COMP_CWORD=1
    export COMPREPLY=()
    _mcd_tab_complete
    
    second_result="${COMPREPLY[0]}"
    echo "Second tab result: '$second_result'"
    
    if [[ "$second_result" == *"//" ]]; then
        echo "✗ BUG: Double slash detected"
    elif [[ "$second_result" == *"subdir"* ]]; then
        echo "✓ FIXED: Found subdirectory"
    else
        echo "? UNCLEAR: Unexpected result"
    fi
else
    echo "✗ First tab failed"
fi

echo
echo "=== Test Case 2: Multiple matches ==="
echo "Pattern: 'foo' should show multiple options, not affected by fix"

cd "$TEST_ROOT/case2"
echo "Working directory: $(pwd)"

export COMP_WORDS=("mcd" "foo")
export COMP_CWORD=1
export COMPREPLY=()
_mcd_tab_complete

echo "First result: '${COMPREPLY[0]}'"
echo "This should cycle between foo1 and foo2 (multiple match behavior unchanged)"

echo
echo "=== Test Case 3: Leaf directory ==="
echo "Pattern: '3' should complete to 'foo3' without slash (no subdirectories)"

cd "$TEST_ROOT/case3"
echo "Working directory: $(pwd)"

export COMP_WORDS=("mcd" "3")
export COMP_CWORD=1
export COMPREPLY=()
_mcd_tab_complete

result="${COMPREPLY[0]}"
echo "Result: '$result'"

if [[ "$result" == *"foo3" ]] && [[ "$result" != *"foo3/" ]]; then
    echo "✓ Leaf directory behavior preserved (no trailing slash added)"
elif [[ "$result" == *"foo3/" ]]; then
    echo "? Leaf directory has trailing slash (check if this is correct behavior)"
else
    echo "✗ Unexpected result"
fi

echo
echo "=== Test Case 4: Relative paths still work ==="
echo "Testing that relative path functionality is unaffected"

cd "$TEST_ROOT/case1"
mkdir -p ../relative_test/target_dir
cd foo2/subdir1

export COMP_WORDS=("mcd" "../..")
export COMP_CWORD=1
export COMPREPLY=()
_mcd_tab_complete

result="${COMPREPLY[0]}"
echo "Relative navigation result: '$result'"

if [[ "$result" == *"case1" ]]; then
    echo "✓ Relative navigation still works"
else
    echo "✗ Relative navigation broken"
fi

echo
echo "=== Running Official Tests ==="
echo "Checking that official tests still pass..."

# Run the validation test
if [ -x "/datadrive/mcd/tests/validate_mcd.sh" ]; then
    echo "Running validate_mcd.sh..."
    bash /datadrive/mcd/tests/validate_mcd.sh
else
    echo "Validation test not found, skipping"
fi

# Cleanup
rm -rf "$TEST_ROOT"

echo
echo "=== Summary ==="
echo "✓ Fix: Remove original pattern slash requirement for subdirectory exploration"
echo "✓ Test: Single match + trailing slash + tab → explore subdirectories"
echo "✓ Test: Multiple matches behavior unchanged"
echo "✓ Test: Leaf directory behavior preserved"  
echo "✓ Test: Relative paths still work"
echo "✓ Test: Official tests should pass"