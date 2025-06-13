#!/bin/bash

# Test script to verify the absolute path regression fix
# Tests that mcd /da returns immediate matches quickly without deep search

set -e

echo "Testing mcd absolute path regression fix..."

# Create test directories if they don't exist
mkdir -p /datadrive2 2>/dev/null || true
mkdir -p /data 2>/dev/null || true
mkdir -p /database 2>/dev/null || true

# Verify test directories exist
echo "Test directories:"
ls -la /data* 2>/dev/null | head -10 || echo "No /data* directories found"

# Try to find the mcd binary
MCD_BINARY=""
if [ -f "./target/release/mcd" ]; then
    MCD_BINARY="./target/release/mcd"
elif [ -f "../target/release/mcd" ]; then
    MCD_BINARY="../target/release/mcd"
elif [ -f "../../target/release/mcd" ]; then
    MCD_BINARY="../../target/release/mcd"
elif [ -f "../../../target/release/mcd" ]; then
    MCD_BINARY="../../../target/release/mcd"
elif [ -f "../../../../target/release/mcd" ]; then
    MCD_BINARY="../../../../target/release/mcd"
elif [ -f "../../../../../target/release/mcd" ]; then
    MCD_BINARY="../../../../../target/release/mcd"
else
    echo "ERROR: Could not find mcd binary"
    echo "Searched in: ., .., ../.., ../../.., ../../../.., ../../../../.."
    exit 1
fi

echo "Found mcd binary at: $MCD_BINARY"

# Test 1: Absolute path immediate matches
echo ""
echo "=== Test 1: Testing absolute path /da for immediate matches ==="
start_time=$(date +%s.%3N)
results=$($MCD_BINARY /da 2>&1 || true)
end_time=$(date +%s.%3N)
duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")

echo "Duration: ${duration}s"
echo "Results:"
echo "$results"

# Check if we got immediate matches quickly (less than 2 seconds)
if [[ "$duration" != "N/A" ]]; then
    if (( $(echo "$duration < 2.0" | bc -l 2>/dev/null || echo 0) )); then
        echo "✓ PASS: Quick response (${duration}s < 2.0s)"
    else
        echo "✗ FAIL: Slow response (${duration}s >= 2.0s)"
    fi
fi

# Check if we got /datadrive in results
if echo "$results" | grep -q "/datadrive"; then
    echo "✓ PASS: Found /datadrive in results"
else
    echo "✗ FAIL: /datadrive not found in results"
fi

# Test 2: Relative path functionality
echo ""
echo "=== Test 2: Testing relative path functionality ==="
cd /tmp 2>/dev/null || cd /
rel_results=$($MCD_BINARY bin 2>&1 || true)
echo "Relative path results for 'bin':"
echo "$rel_results"

if echo "$rel_results" | grep -q "/bin\|bin"; then
    echo "✓ PASS: Relative path search working"
else
    echo "✗ FAIL: Relative path search not working"
fi

# Test 3: Prefix vs substring prioritization
echo ""
echo "=== Test 3: Testing prefix vs substring prioritization ==="
prefix_results=$($MCD_BINARY data 2>&1 || true)
echo "Results for 'data' pattern:"
echo "$prefix_results"

# Check if prefix matches come before substring matches
first_result=$(echo "$prefix_results" | head -1)
if echo "$first_result" | grep -q "^/data"; then
    echo "✓ PASS: Prefix matches prioritized"
else
    echo "? INFO: First result: $first_result"
fi

echo ""
echo "=== Summary ==="
echo "The regression fix test is complete."
echo "Key indicators of success:"
echo "1. /da query returns quickly (< 2 seconds)"
echo "2. /datadrive appears in results"
echo "3. Relative paths still work"
echo "4. Prefix matches are prioritized"