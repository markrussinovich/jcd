#!/bin/bash

# Quick validation script for MCD functionality
echo "=== MCD Quick Validation ==="

# Check if binary exists and is executable
if [[ -x "/datadrive/mcd/target/release/mcd" ]]; then
    echo "✓ Binary exists and is executable"
else
    echo "✗ Binary not found or not executable"
    exit 1
fi

# Test basic binary functionality
echo "Testing binary functionality..."

# Create test structure
mkdir -p /tmp/mcd_test/{parent/{child1,child2},sibling}
cd /tmp/mcd_test/parent/child1

# Test parent navigation
result=$(/datadrive/mcd/target/release/mcd ".." 2>/dev/null)
if [[ "$result" == "/tmp/mcd_test/parent" ]]; then
    echo "✓ Parent navigation works"
else
    echo "✗ Parent navigation failed. Got: '$result'"
fi

# Test multi-level navigation
result=$(/datadrive/mcd/target/release/mcd "../.." 2>/dev/null)
if [[ "$result" == "/tmp/mcd_test" ]]; then
    echo "✓ Multi-level navigation works"
else
    echo "✗ Multi-level navigation failed. Got: '$result'"
fi

# Test relative pattern search
result=$(/datadrive/mcd/target/release/mcd "../child2" 2>/dev/null)
if [[ "$result" == "/tmp/mcd_test/parent/child2" ]]; then
    echo "✓ Relative pattern search works"
else
    echo "✗ Relative pattern search failed. Got: '$result'"
fi

# Test shell function
echo "Testing shell function..."
source /datadrive/mcd/mcd_function.sh

# Test function existence
if declare -f mcd > /dev/null; then
    echo "✓ Shell function loaded"
else
    echo "✗ Shell function not loaded"
fi

# Test shell function navigation
cd /tmp/mcd_test/parent/child1
mcd ".." 2>/dev/null
if [[ "$(pwd)" == "/tmp/mcd_test/parent" ]]; then
    echo "✓ Shell function navigation works"
else
    echo "✗ Shell function navigation failed. Current dir: $(pwd)"
fi

# Cleanup
rm -rf /tmp/mcd_test

echo "=== Validation Complete ==="
