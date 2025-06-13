#!/bin/bash

echo "=== Testing Trailing Slash Fallback Fix ==="
echo "Bug: 'mcd /path/that/doesnt/exist/' should find matches, not return 'No directories found'"
echo

# Create test structure to match user's example
TEST_BASE="/datadrive/tmp"
rm -rf "$TEST_BASE"
mkdir -p "$TEST_BASE/foo1/foo2"
mkdir -p "$TEST_BASE/foo1/foo2/foo3a"
mkdir -p "$TEST_BASE/foo1/foo2/foo3b"
mkdir -p "$TEST_BASE/foo1/foo2/foo3b/foo4"

echo "Created test structure:"
find "$TEST_BASE" -type d | sort

cd "$TEST_BASE/foo1/foo2"
echo "Working from: $(pwd)"

echo
echo "=== Test 1: Reproduce the reported bug ==="
echo "Command: mcd /datadrive/tmp/foo1/foo2/foo3b/foo4/"
echo "Expected: Should find /datadrive/tmp/foo1/foo2/foo3b/foo4 (without trailing slash)"
echo "Before fix: 'No directories found matching...'"

result=$(/datadrive/mcd/target/release/mcd "/datadrive/tmp/foo1/foo2/foo3b/foo4/" 2>&1)
exit_code=$?

echo "Result: $result"
echo "Exit code: $exit_code"

if [[ $exit_code -eq 0 ]]; then
    echo "✓ FIXED: Found directory: $result"
else
    echo "✗ STILL BROKEN: No directory found"
fi

echo
echo "=== Test 2: Various trailing slash scenarios ==="

echo
echo "2a. Existing directory with trailing slash (should explore subdirectories):"
result=$(/datadrive/mcd/target/release/mcd "/datadrive/tmp/foo1/foo2/" 0 2>/dev/null)
if [[ $? -eq 0 ]]; then
    echo "  ✓ Found: $result"
else
    echo "  ✗ Failed to find subdirectories"
fi

echo
echo "2b. Non-existing directory with trailing slash (should find match without slash):"
result=$(/datadrive/mcd/target/release/mcd "/datadrive/tmp/foo1/foo2/foo3b/foo4/" 0 2>/dev/null)
if [[ $? -eq 0 ]]; then
    echo "  ✓ Found: $result"
else
    echo "  ✗ Failed to find directory"
fi

echo
echo "2c. Pattern with trailing slash (should find matches):"
result=$(/datadrive/mcd/target/release/mcd "/datadrive/tmp/foo1/foo2/foo3/" 0 2>/dev/null)
if [[ $? -eq 0 ]]; then
    echo "  ✓ Found: $result"
else
    echo "  ✗ Failed to find pattern matches"
fi

echo
echo "=== Test 3: Ensure existing functionality still works ==="

echo
echo "3a. Existing directory without slash:"
result=$(/datadrive/mcd/target/release/mcd "/datadrive/tmp/foo1/foo2/foo3b" 0 2>/dev/null)
if [[ $? -eq 0 ]]; then
    echo "  ✓ Found: $result"
else
    echo "  ✗ Failed"
fi

echo
echo "3b. Pattern search without slash:"
result=$(/datadrive/mcd/target/release/mcd "/datadrive/tmp/foo1/foo2/foo3" 0 2>/dev/null)
if [[ $? -eq 0 ]]; then
    echo "  ✓ Found: $result"
else
    echo "  ✗ Failed"
fi

echo
echo "3c. Relative pattern (should be unaffected):"
cd "$TEST_BASE/foo1"
result=$(/datadrive/mcd/target/release/mcd "foo2" 0 2>/dev/null)
if [[ $? -eq 0 ]]; then
    echo "  ✓ Found: $result"
else
    echo "  ✗ Failed"
fi

# Cleanup
rm -rf "$TEST_BASE"

echo
echo "=== Summary ==="
echo "Fix: When path with trailing slash doesn't exist, remove slash and do pattern search"
echo "This resolves: mcd /path/that/doesnt/exist/ → should find /path/that/doesnt/exist"
echo "Preserves: All existing functionality for paths without trailing slashes"