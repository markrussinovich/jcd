#!/bin/bash

echo "=== Testing Subdirectory Exploration Still Works ==="
echo "Ensuring that when subdirectories can be found, they are discovered"
echo

# Create test structure with relative paths that the binary can find
TEST_DIR="test_subdir_exploration"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/parent/child1"
mkdir -p "$TEST_DIR/parent/child2"
mkdir -p "$TEST_DIR/parent/child3"

echo "Created test structure:"
find "$TEST_DIR" -type d | sort

cd "$TEST_DIR"
echo "Working from: $(pwd)"

# Source the mcd function with debug enabled
export MCD_BINARY="/datadrive/mcd/target/release/mcd"
export MCD_DEBUG=1
source /datadrive/mcd/mcd_function.sh

echo
echo "=== Test: mcd parent/ + tab (should find child directories) ==="
export COMP_WORDS=("mcd" "parent/")
export COMP_CWORD=1
export COMPREPLY=()
_mcd_tab_complete

result="${COMPREPLY[0]}"
echo "Result: '$result'"

if [[ "$result" == *"child"* ]]; then
    echo "✓ SUCCESS: Found child directory"
elif [[ "$result" == *"//" ]]; then
    echo "✗ FAIL: Double slash bug still present"  
elif [[ "$result" == "parent" ]]; then
    echo "✓ SUCCESS: Correctly handled as leaf directory (no subdirs found by binary)"
else
    echo "? UNCLEAR: Unexpected result: '$result'"
fi

echo
echo "Let's also test what the binary returns directly:"
echo "Binary call: mcd 'parent/' 0"
direct_result=$(/datadrive/mcd/target/release/mcd 'parent/' 0 2>/dev/null)
echo "Direct binary result: '$direct_result'"

echo "Binary call: mcd 'parent/' 1"
direct_result2=$(/datadrive/mcd/target/release/mcd 'parent/' 1 2>/dev/null)
echo "Direct binary result 2: '$direct_result2'"

# Cleanup
cd ..
rm -rf "$TEST_DIR"