#!/bin/bash

echo "Testing relative path functionality..."

# Create a test directory structure
mkdir -p /tmp/mcd_test/{parent/{child1,child2,childX},sibling/{sub1,sub2},foo/{bar,baz}}

echo "Created test structure:"
echo "/tmp/mcd_test/"
echo "├── parent/"
echo "│   ├── child1/"
echo "│   ├── child2/"
echo "│   └── childX/"
echo "├── sibling/"
echo "│   ├── sub1/"
echo "│   └── sub2/"
echo "└── foo/"
echo "    ├── bar/"
echo "    └── baz/"

# Test the binary directly
echo -e "\n=== Testing binary with relative paths ==="

cd /tmp/mcd_test/parent/child1
echo "Current directory: $(pwd)"

echo -e "\nTest 1: mcd '..' (should go to parent)"
result=$(/datadrive/mcd/target/release/mcd ".." 2>&1)
echo "Result: $result"

echo -e "\nTest 2: mcd '../..' (should go to mcd_test)"
result=$(/datadrive/mcd/target/release/mcd "../.." 2>&1)
echo "Result: $result"

echo -e "\nTest 3: mcd '../child2' (should find sibling directory)"
result=$(/datadrive/mcd/target/release/mcd "../child2" 2>&1)
echo "Result: $result"

echo -e "\nTest 4: mcd '../../foo' (should find foo directory)"
result=$(/datadrive/mcd/target/release/mcd "../../foo" 2>&1)
echo "Result: $result"

# Test with patterns
echo -e "\nTest 5: mcd '../ch' (should find child directories)"
for i in {0..5}; do
    result=$(/datadrive/mcd/target/release/mcd "../ch" $i 2>/dev/null)
    if [[ -n "$result" ]]; then
        echo "Match $i: $result"
    else
        break
    fi
done

echo -e "\n=== Testing shell function ==="

# Source the shell function
source /datadrive/mcd/mcd_function.sh

cd /tmp/mcd_test/parent/child1
echo "Current directory: $(pwd)"

echo -e "\nTesting mcd function:"
echo "mcd '..' -> "
mcd ".."
echo "Now in: $(pwd)"

echo "mcd 'child1' -> "
mcd "child1"
echo "Now in: $(pwd)"

echo "mcd '../..' -> "
mcd "../.."
echo "Now in: $(pwd)"

echo "mcd 'parent/child2' -> "
mcd "parent/child2"
echo "Now in: $(pwd)"

# Clean up
echo -e "\n=== Cleaning up ==="
rm -rf /tmp/mcd_test
echo "Test completed!"
