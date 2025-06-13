#!/bin/bash

echo "=== Debugging Binary Call Issue ==="

# Create test structure
TEST_DIR="debug_test"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/foo1/foo2/subdir1"
mkdir -p "$TEST_DIR/foo1/foo2/subdir2"

echo "Created test structure:"
find "$TEST_DIR" -type d | sort

# Test binary from current directory
echo
echo "Testing binary from current directory (/datadrive/mcd):"
echo "1. Call: mcd 'debug_test/foo1/foo2/' 0"
/datadrive/mcd/target/release/mcd 'debug_test/foo1/foo2/' 0
echo "2. Call: mcd 'debug_test/foo1/foo2/' 1"
/datadrive/mcd/target/release/mcd 'debug_test/foo1/foo2/' 1

# Test binary from inside test directory
cd "$TEST_DIR"
echo
echo "Working from inside test directory: $(pwd)"
echo "3. Call: mcd 'foo1/foo2/' 0"
/datadrive/mcd/target/release/mcd 'foo1/foo2/' 0
echo "4. Call: mcd 'foo1/foo2/' 1"
/datadrive/mcd/target/release/mcd 'foo1/foo2/' 1

# Test with absolute path from inside test directory
absolute_path="$(pwd)/foo1/foo2/"
echo
echo "5. Call with absolute path: mcd '$absolute_path' 0"
/datadrive/mcd/target/release/mcd "$absolute_path" 0
echo "6. Call with absolute path: mcd '$absolute_path' 1"
/datadrive/mcd/target/release/mcd "$absolute_path" 1

# Cleanup
cd ..
rm -rf "$TEST_DIR"